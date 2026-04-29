import CloudKit
import CoreLocation
import Foundation
import OSLog

actor CloudKitCommunityService: CommunityService {
    private let container: CKContainer
    private let publicDB: CKDatabase
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let logger = Logger(subsystem: "brainmeld.Road-Beans", category: "CloudKitCommunityService")
    private var memberSnapshotCache: [String: CommunityMemberSnapshot] = [:]

    init(container: CKContainer = .default()) {
        self.container = container
        self.publicDB = container.publicCloudDatabase
    }

    func currentMember() async throws -> CommunityMemberSnapshot? {
        let userID = try await currentUserRecordID()
        return try await fetchMember(userRecordID: userID.recordName)
    }

    func join(displayName: String, profile: TasteProfile, existingVisits: [CommunityVisitDraft]) async throws {
        logger.info("Community join started")
        let userID = try await currentUserRecordID()
        logger.info("Community join fetched user record ID: \(userID.recordName, privacy: .private)")
        if try await fetchMember(userRecordID: userID.recordName) != nil {
            logger.info("Community join found existing member")
            throw CommunityServiceError.alreadyMember
        }

        let now = Date.now
        let record = CKRecord(recordType: CommunityRecordType.member, recordID: memberRecordID(for: userID.recordName))
        record["userRecordID"] = userID.recordName as NSString
        record["displayName"] = displayName.trimmingCharacters(in: .whitespacesAndNewlines) as NSString
        record["tasteProfile"] = try encoder.encode(profile) as NSData
        record["joinedAt"] = now as NSDate
        record["lastUpdatedAt"] = now as NSDate
        _ = try await save(record)
        logger.info("Community member record saved")

        for visit in existingVisits {
            _ = try await publish(visit)
        }
        logger.info("Community join completed")
    }

    func leave(deleteRatings: Bool) async throws {
        let userID = try await currentUserRecordID()
        try await deleteCurrentUserSocialRecords(userRecordID: userID.recordName)
        if deleteRatings {
            try await deleteAuthoredVisits(authorUserRecordID: userID.recordName)
        }
        do {
            _ = try await delete(recordID: memberRecordID(for: userID.recordName))
        } catch let error as CKError where error.code == .unknownItem {}
        memberSnapshotCache[userID.recordName] = nil
    }

    func updateProfile(displayName: String, profile: TasteProfile) async throws {
        let userID = try await currentUserRecordID()
        let record = try await fetch(recordID: memberRecordID(for: userID.recordName))
        record["displayName"] = displayName.trimmingCharacters(in: .whitespacesAndNewlines) as NSString
        record["tasteProfile"] = try encoder.encode(profile) as NSData
        record["lastUpdatedAt"] = Date.now as NSDate
        _ = try await save(record)
        memberSnapshotCache[userID.recordName] = nil
    }

    func publish(_ visit: CommunityVisitDraft) async throws -> String {
        let userID = try await currentUserRecordID()
        guard let member = try await fetchMember(userRecordID: userID.recordName) else {
            throw CommunityServiceError.notAMember
        }

        let recordID = CKRecord.ID(recordName: visit.localVisitID.uuidString)
        let record = (try? await fetch(recordID: recordID)) ?? CKRecord(recordType: CommunityRecordType.visit, recordID: recordID)
        apply(visit, to: record, author: member)
        _ = try await save(record)
        logger.info("Published community visit \(recordID.recordName, privacy: .public)")
        return recordID.recordName
    }

    func updatePublishedVisit(_ visit: CommunityVisitDraft) async throws {
        _ = try await publish(visit)
    }

    func deletePublishedVisit(localVisitID: UUID) async throws {
        let recordID = CKRecord.ID(recordName: localVisitID.uuidString)
        do {
            _ = try await delete(recordID: recordID)
        } catch let error as CKError where error.code == .unknownItem {}
    }

    func deleteVisit(recordName: String) async throws {
        let userID = try await currentUserRecordID()
        let recordID = CKRecord.ID(recordName: recordName)
        let record: CKRecord
        do {
            record = try await fetch(recordID: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            throw CommunityServiceError.notFound
        }
        guard record["authorUserRecordID"] as? String == userID.recordName else {
            throw CommunityServiceError.notAuthor
        }

        try await deleteRecordsMatching(
            recordType: CommunityRecordType.like,
            predicate: NSPredicate(format: "communityVisitRecordName == %@", recordName)
        )
        try await deleteRecordsMatching(
            recordType: CommunityRecordType.comment,
            predicate: NSPredicate(format: "communityVisitRecordName == %@", recordName)
        )
        _ = try await delete(recordID: recordID)
    }

    func fetchFeedPage(
        cursor: String?,
        limit: Int,
        authorIDsToInclude: Set<String>?,
        authorIDsToExclude: Set<String>
    ) async throws -> CommunityFeedPage {
        if let cursor, let queryCursor = decodeCursor(cursor) {
            let page = try await query(cursor: queryCursor, limit: limit)
            return CommunityFeedPage(
                rows: try await rows(from: page.records),
                nextCursor: page.cursor.flatMap(encodeCursor(_:))
            )
        }

        guard let predicate = feedPredicate(
            authorIDsToInclude: authorIDsToInclude,
            authorIDsToExclude: authorIDsToExclude
        ) else {
            return CommunityFeedPage(rows: [], nextCursor: nil)
        }

        let feedQuery = CKQuery(recordType: CommunityRecordType.visit, predicate: predicate)
        feedQuery.sortDescriptors = [NSSortDescriptor(key: "publishedAt", ascending: false)]

        do {
            let page = try await query(feedQuery, limit: limit)
            return CommunityFeedPage(
                rows: try await rows(from: page.records),
                nextCursor: page.cursor.flatMap(encodeCursor(_:))
            )
        } catch {
            logger.error("Community feed indexed query failed; retrying with local filtering: \(String(describing: error), privacy: .public)")
            return try await fetchFeedPageWithLocalFiltering(
                limit: limit,
                authorIDsToInclude: authorIDsToInclude,
                authorIDsToExclude: authorIDsToExclude
            )
        }
    }

    func fetchVisits(matchingMapKitIdentifier identifier: String) async throws -> [CommunityVisitRow] {
        let predicate = NSPredicate(format: "placeMapKitIdentifier == %@", identifier)
        let query = CKQuery(recordType: CommunityRecordType.visit, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "visitDate", ascending: false)]
        return try await rows(from: queryAll(query))
    }

    func fetchVisits(near coordinate: CLLocationCoordinate2D, radiusMeters: Double, nameContains: String) async throws -> [CommunityVisitRow] {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let predicate = NSPredicate(
            format: "distanceToLocation:fromLocation:(placeLocation, %@) < %f AND placeName CONTAINS[cd] %@",
            location,
            radiusMeters,
            nameContains
        )
        let query = CKQuery(recordType: CommunityRecordType.visit, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "visitDate", ascending: false)]
        return try await rows(from: queryAll(query))
    }

    func fetchMember(userRecordID: String) async throws -> CommunityMemberSnapshot? {
        if let cached = memberSnapshotCache[userRecordID] {
            return cached
        }
        do {
            let record = try await fetch(recordID: memberRecordID(for: userRecordID))
            let snapshot = try member(from: record)
            if let snapshot {
                memberSnapshotCache[userRecordID] = snapshot
            }
            return snapshot
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    func fetchVisitDetail(recordName: String) async throws -> CommunityVisitDetail? {
        do {
            let record = try await fetch(recordID: CKRecord.ID(recordName: recordName))
            guard var row = try await row(from: record, likeCount: 0, commentCount: 0) else { return nil }
            let commentRows = try await comments(forVisitRecordName: recordName)
            row.commentCount = commentRows.count
            row.likeCount = try await likeCount(for: recordName)
            return CommunityVisitDetail(
                row: row,
                comments: commentRows,
                likedByCurrentUser: try await isLikedByCurrentUser(recordName)
            )
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    func fetchLikedVisitsByCurrentUser() async throws -> [CommunityVisitRow] {
        let userID = try await currentUserRecordID()
        let predicate = NSPredicate(format: "userRecordID == %@", userID.recordName)
        let query = CKQuery(recordType: CommunityRecordType.like, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        var rows: [CommunityVisitRow] = []
        let likes = try await queryAll(query)
        for like in likes {
            guard
                let recordName = like["communityVisitRecordName"] as? String,
                let detail = try await fetchVisitDetail(recordName: recordName)
            else { continue }
            rows.append(detail.row)
        }
        return rows
    }

    func like(visitRecordName: String) async throws {
        let userID = try await currentUserRecordID()
        let displayName = try await currentMemberDisplayName()
        let recordID = CKRecord.ID(recordName: "like-\(visitRecordName)-\(userID.recordName)")
        let record = CKRecord(recordType: CommunityRecordType.like, recordID: recordID)
        record["communityVisitRecordName"] = visitRecordName as NSString
        record["userRecordID"] = userID.recordName as NSString
        record["userDisplayName"] = displayName as NSString
        record["timestamp"] = Date.now as NSDate
        do {
            _ = try await save(record)
        } catch let error as CKError where error.code == .serverRecordChanged || error.code == .batchRequestFailed || error.code == .constraintViolation {}
    }

    func unlike(visitRecordName: String) async throws {
        let userID = try await currentUserRecordID()
        let recordID = CKRecord.ID(recordName: "like-\(visitRecordName)-\(userID.recordName)")
        do {
            _ = try await delete(recordID: recordID)
        } catch let error as CKError where error.code == .unknownItem {}
    }

    func comments(forVisitRecordName recordName: String) async throws -> [CommunityCommentRow] {
        let predicate = NSPredicate(format: "communityVisitRecordName == %@", recordName)
        let query = CKQuery(recordType: CommunityRecordType.comment, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        return try await queryAll(query).compactMap(comment(from:))
    }

    func addComment(toVisitRecordName recordName: String, text: String) async throws -> CommunityCommentRow {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CommunityServiceError.invalidInput }

        let userID = try await currentUserRecordID()
        let displayName = try await currentMemberDisplayName()
        let record = CKRecord(recordType: CommunityRecordType.comment)
        let timestamp = Date.now
        record["communityVisitRecordName"] = recordName as NSString
        record["userRecordID"] = userID.recordName as NSString
        record["userDisplayName"] = displayName as NSString
        record["text"] = trimmed as NSString
        record["timestamp"] = timestamp as NSDate
        let saved = try await save(record)
        return CommunityCommentRow(
            id: saved.recordID.recordName,
            authorUserRecordID: userID.recordName,
            authorDisplayName: displayName,
            text: trimmed,
            timestamp: saved["timestamp"] as? Date ?? timestamp
        )
    }

    func deleteComment(recordName: String) async throws {
        do {
            _ = try await delete(recordID: CKRecord.ID(recordName: recordName))
        } catch let error as CKError where error.code == .unknownItem {}
    }

    private func currentUserRecordID() async throws -> CKRecord.ID {
        try await withCheckedThrowingContinuation { continuation in
            container.fetchUserRecordID { recordID, error in
                if let recordID {
                    continuation.resume(returning: recordID)
                } else {
                    continuation.resume(throwing: error ?? CommunityServiceError.notAMember)
                }
            }
        }
    }

    private nonisolated func memberRecordID(for userRecordID: String) -> CKRecord.ID {
        CKRecord.ID(recordName: "member-\(userRecordID)")
    }

    private func fetch(recordID: CKRecord.ID) async throws -> CKRecord {
        try await withCheckedThrowingContinuation { continuation in
            publicDB.fetch(withRecordID: recordID) { record, error in
                if let record {
                    continuation.resume(returning: record)
                } else {
                    continuation.resume(throwing: error ?? CommunityServiceError.notFound)
                }
            }
        }
    }

    private func save(_ record: CKRecord) async throws -> CKRecord {
        try await withCheckedThrowingContinuation { continuation in
            publicDB.save(record) { record, error in
                if let record {
                    continuation.resume(returning: record)
                } else {
                    continuation.resume(throwing: Self.communityError(from: error))
                }
            }
        }
    }

    private func delete(recordID: CKRecord.ID) async throws -> CKRecord.ID {
        try await withCheckedThrowingContinuation { continuation in
            publicDB.delete(withRecordID: recordID) { recordID, error in
                if let recordID {
                    continuation.resume(returning: recordID)
                } else {
                    continuation.resume(throwing: error ?? CommunityServiceError.notFound)
                }
            }
        }
    }

    private func query(_ query: CKQuery, limit: Int) async throws -> (records: [CKRecord], cursor: CKQueryOperation.Cursor?) {
        try await withCheckedThrowingContinuation { continuation in
            let operation = CKQueryOperation(query: query)
            operation.resultsLimit = limit
            collect(operation, continuation: continuation)
        }
    }

    private func query(cursor: CKQueryOperation.Cursor, limit: Int) async throws -> (records: [CKRecord], cursor: CKQueryOperation.Cursor?) {
        try await withCheckedThrowingContinuation { continuation in
            let operation = CKQueryOperation(cursor: cursor)
            operation.resultsLimit = limit
            collect(operation, continuation: continuation)
        }
    }

    private func queryAll(_ query: CKQuery) async throws -> [CKRecord] {
        var output: [CKRecord] = []
        var page = try await self.query(query, limit: 100)
        output.append(contentsOf: page.records)
        while let cursor = page.cursor {
            page = try await self.query(cursor: cursor, limit: 100)
            output.append(contentsOf: page.records)
        }
        return output
    }

    private nonisolated func collect(
        _ operation: CKQueryOperation,
        continuation: CheckedContinuation<(records: [CKRecord], cursor: CKQueryOperation.Cursor?), Error>
    ) {
        var records: [CKRecord] = []
        operation.recordMatchedBlock = { _, result in
            if case .success(let record) = result {
                records.append(record)
            }
        }
        operation.queryResultBlock = { result in
            switch result {
            case .success(let cursor):
                continuation.resume(returning: (records, cursor))
            case .failure(let error):
                continuation.resume(throwing: Self.communityError(from: error))
            }
        }
        publicDB.add(operation)
    }

    private nonisolated static func communityError(from error: Error?) -> Error {
        guard let error else {
            return CommunityServiceError.underlying("CloudKit request failed")
        }
        if isMissingProductionSchemaError(error) {
            return CommunityServiceError.schemaNotConfigured
        }
        return error
    }

    private nonisolated static func isMissingProductionSchemaError(_ error: Error) -> Bool {
        let message = String(describing: error)
        return message.localizedCaseInsensitiveContains("Cannot create new type")
            || message.localizedCaseInsensitiveContains("production schema")
    }

    private func rows(from records: [CKRecord]) async throws -> [CommunityVisitRow] {
        let recordNames = Set(records.map(\.recordID.recordName))
        let likeCounts = await bestEffortLikeCounts(for: recordNames)
        let commentCounts = await bestEffortCommentCounts(for: recordNames)
        var rows: [CommunityVisitRow] = []
        for record in records {
            if let row = try await row(
                from: record,
                likeCount: likeCounts[record.recordID.recordName, default: 0],
                commentCount: commentCounts[record.recordID.recordName, default: 0]
            ) {
                rows.append(row)
            }
        }
        return rows
    }

    private func fetchFeedPageWithLocalFiltering(
        limit: Int,
        authorIDsToInclude: Set<String>?,
        authorIDsToExclude: Set<String>
    ) async throws -> CommunityFeedPage {
        let broadQuery = CKQuery(recordType: CommunityRecordType.visit, predicate: allVisitsPredicate())
        let records = try await queryAll(broadQuery)
        let filtered = records.filter { record in
            guard let authorUserRecordID = record["authorUserRecordID"] as? String else { return false }
            if let authorIDsToInclude, !authorIDsToInclude.contains(authorUserRecordID) {
                return false
            }
            return !authorIDsToExclude.contains(authorUserRecordID)
        }
        .sorted { lhs, rhs in
            let left = lhs["publishedAt"] as? Date ?? .distantPast
            let right = rhs["publishedAt"] as? Date ?? .distantPast
            return left > right
        }
        .prefix(limit)

        return CommunityFeedPage(rows: try await rows(from: Array(filtered)), nextCursor: nil)
    }

    private func row(from record: CKRecord, likeCount: Int, commentCount: Int) async throws -> CommunityVisitRow? {
        guard
            let authorUserRecordID = record["authorUserRecordID"] as? String,
            let authorDisplayName = record["authorDisplayName"] as? String,
            let placeName = record["placeName"] as? String,
            let placeKindRawValue = record["placeKind"] as? String,
            let visitDate = record["visitDate"] as? Date,
            let beanRating = Self.doubleValue(record["beanRating"]),
            let drinkSummary = record["drinkSummary"] as? String,
            let tagSummary = record["tagSummary"] as? String,
            let publishedAt = record["publishedAt"] as? Date
        else { return nil }

        let author = try? await fetchMember(userRecordID: authorUserRecordID)
        return CommunityVisitRow(
            id: record.recordID.recordName,
            authorUserRecordID: authorUserRecordID,
            authorDisplayName: authorDisplayName,
            authorTasteProfile: author?.tasteProfile,
            placeName: placeName,
            placeKindRawValue: placeKindRawValue,
            placeMapKitIdentifier: record["placeMapKitIdentifier"] as? String,
            placeLatitude: Self.doubleValue(record["placeLatitude"]),
            placeLongitude: Self.doubleValue(record["placeLongitude"]),
            visitDate: visitDate,
            beanRating: beanRating,
            drinkSummary: drinkSummary,
            tagSummary: tagSummary,
            publishedAt: publishedAt,
            likeCount: likeCount,
            commentCount: commentCount
        )
    }

    private func member(from record: CKRecord) throws -> CommunityMemberSnapshot? {
        guard
            let userRecordID = record["userRecordID"] as? String,
            let displayName = record["displayName"] as? String,
            let data = record["tasteProfile"] as? Data,
            let joinedAt = record["joinedAt"] as? Date
        else { return nil }

        return CommunityMemberSnapshot(
            userRecordID: userRecordID,
            displayName: displayName,
            tasteProfile: try decoder.decode(TasteProfile.self, from: data),
            joinedAt: joinedAt
        )
    }

    private func comment(from record: CKRecord) -> CommunityCommentRow? {
        guard
            let authorUserRecordID = record["userRecordID"] as? String,
            let authorDisplayName = record["userDisplayName"] as? String,
            let text = record["text"] as? String,
            let timestamp = record["timestamp"] as? Date
        else { return nil }

        return CommunityCommentRow(
            id: record.recordID.recordName,
            authorUserRecordID: authorUserRecordID,
            authorDisplayName: authorDisplayName,
            text: text,
            timestamp: timestamp
        )
    }

    private func apply(_ visit: CommunityVisitDraft, to record: CKRecord, author: CommunityMemberSnapshot) {
        let now = Date.now
        record["localVisitID"] = visit.localVisitID.uuidString as NSString
        record["authorUserRecordID"] = author.userRecordID as NSString
        record["authorDisplayName"] = author.displayName as NSString
        record["placeName"] = visit.placeName as NSString
        record["placeKind"] = visit.placeKindRawValue as NSString
        record["placeMapKitIdentifier"] = visit.placeMapKitIdentifier as NSString?
        record["placeLatitude"] = visit.placeLatitude as NSNumber?
        record["placeLongitude"] = visit.placeLongitude as NSNumber?
        if let latitude = visit.placeLatitude, let longitude = visit.placeLongitude {
            record["placeLocation"] = CLLocation(latitude: latitude, longitude: longitude)
        }
        record["visitDate"] = visit.visitDate as NSDate
        record["beanRating"] = visit.beanRating as NSNumber
        record["drinkSummary"] = visit.drinkSummary as NSString
        record["tagSummary"] = visit.tagSummary as NSString
        record["publishedAt"] = (record["publishedAt"] as? Date ?? now) as NSDate
        record["lastUpdatedAt"] = now as NSDate
    }

    private func currentMemberDisplayName() async throws -> String {
        guard let member = try await currentMember() else { throw CommunityServiceError.notAMember }
        return member.displayName
    }

    private func likeCount(for recordName: String) async throws -> Int {
        let predicate = NSPredicate(format: "communityVisitRecordName == %@", recordName)
        let query = CKQuery(recordType: CommunityRecordType.like, predicate: predicate)
        return try await queryAll(query).count
    }

    private func commentCount(for recordName: String) async throws -> Int {
        let predicate = NSPredicate(format: "communityVisitRecordName == %@", recordName)
        let query = CKQuery(recordType: CommunityRecordType.comment, predicate: predicate)
        return try await queryAll(query).count
    }

    private func socialCounts(recordType: String, recordNames: Set<String>) async throws -> [String: Int] {
        guard !recordNames.isEmpty else { return [:] }
        let predicate = NSPredicate(format: "communityVisitRecordName IN %@", Array(recordNames))
        let query = CKQuery(recordType: recordType, predicate: predicate)
        let records = try await queryAll(query)
        return records.reduce(into: [:]) { counts, record in
            guard let recordName = record["communityVisitRecordName"] as? String else { return }
            counts[recordName, default: 0] += 1
        }
    }

    private func bestEffortLikeCounts(for recordNames: Set<String>) async -> [String: Int] {
        do {
            return try await socialCounts(recordType: CommunityRecordType.like, recordNames: recordNames)
        } catch {
            logger.error("Community like count batch failed: \(String(describing: error), privacy: .public)")
            var counts: [String: Int] = [:]
            for recordName in recordNames {
                counts[recordName] = await bestEffortLikeCount(for: recordName)
            }
            return counts
        }
    }

    private func bestEffortCommentCounts(for recordNames: Set<String>) async -> [String: Int] {
        do {
            return try await socialCounts(recordType: CommunityRecordType.comment, recordNames: recordNames)
        } catch {
            logger.error("Community comment count batch failed: \(String(describing: error), privacy: .public)")
            var counts: [String: Int] = [:]
            for recordName in recordNames {
                counts[recordName] = await bestEffortCommentCount(for: recordName)
            }
            return counts
        }
    }

    private func bestEffortLikeCount(for recordName: String) async -> Int {
        do {
            return try await likeCount(for: recordName)
        } catch {
            logger.error("Community like count failed for \(recordName, privacy: .public): \(String(describing: error), privacy: .public)")
            return 0
        }
    }

    private func bestEffortCommentCount(for recordName: String) async -> Int {
        do {
            return try await commentCount(for: recordName)
        } catch {
            logger.error("Community comment count failed for \(recordName, privacy: .public): \(String(describing: error), privacy: .public)")
            return 0
        }
    }

    nonisolated static func doubleValue(_ value: Any?) -> Double? {
        if let number = value as? NSNumber {
            return number.doubleValue
        }
        return value as? Double
    }

    func isLikedByCurrentUser(_ recordName: String) async throws -> Bool {
        let userID = try await currentUserRecordID()
        let recordID = CKRecord.ID(recordName: "like-\(recordName)-\(userID.recordName)")
        do {
            _ = try await fetch(recordID: recordID)
            return true
        } catch let error as CKError where error.code == .unknownItem {
            return false
        }
    }

    func likedVisitIDsByCurrentUser(in recordNames: Set<String>) async throws -> Set<String> {
        guard !recordNames.isEmpty else { return [] }
        let userID = try await currentUserRecordID()
        let predicate = NSPredicate(
            format: "userRecordID == %@ AND communityVisitRecordName IN %@",
            userID.recordName,
            Array(recordNames)
        )
        let query = CKQuery(recordType: CommunityRecordType.like, predicate: predicate)
        do {
            let records = try await queryAll(query)
            return Set(records.compactMap { $0["communityVisitRecordName"] as? String })
        } catch {
            logger.error("Community liked batch query failed: \(String(describing: error), privacy: .public)")
            return try await sequentialLikedVisitIDsByCurrentUser(in: recordNames)
        }
    }

    private func sequentialLikedVisitIDsByCurrentUser(in recordNames: Set<String>) async throws -> Set<String> {
        var liked: Set<String> = []
        for recordName in recordNames {
            if try await isLikedByCurrentUser(recordName) {
                liked.insert(recordName)
            }
        }
        return liked
    }

    private func deleteAuthoredVisits(authorUserRecordID: String) async throws {
        let authoredVisits = try await queryAll(CKQuery(
            recordType: CommunityRecordType.visit,
            predicate: NSPredicate(format: "authorUserRecordID == %@", authorUserRecordID)
        ))
        for visit in authoredVisits {
            try await deleteVisit(recordName: visit.recordID.recordName)
        }
    }

    private func deleteCurrentUserSocialRecords(userRecordID: String) async throws {
        try await deleteRecordsMatching(
            recordType: CommunityRecordType.like,
            predicate: NSPredicate(format: "userRecordID == %@", userRecordID)
        )
        try await deleteRecordsMatching(
            recordType: CommunityRecordType.comment,
            predicate: NSPredicate(format: "userRecordID == %@", userRecordID)
        )
    }

    private func deleteRecordsMatching(recordType: String, predicate: NSPredicate) async throws {
        let query = CKQuery(recordType: recordType, predicate: predicate)
        let records = try await queryAll(query)
        for record in records {
            do {
                _ = try await delete(recordID: record.recordID)
            } catch let error as CKError where error.code == .unknownItem {}
        }
    }

    private func feedPredicate(
        authorIDsToInclude: Set<String>?,
        authorIDsToExclude: Set<String>
    ) -> NSPredicate? {
        if let include = authorIDsToInclude, include.isEmpty {
            return nil
        }

        var predicates: [NSPredicate] = []
        if let include = authorIDsToInclude {
            predicates.append(NSPredicate(format: "authorUserRecordID IN %@", Array(include)))
        }
        if !authorIDsToExclude.isEmpty {
            predicates.append(NSPredicate(format: "NOT (authorUserRecordID IN %@)", Array(authorIDsToExclude)))
        }
        return predicates.isEmpty ? allVisitsPredicate() : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    private nonisolated func allVisitsPredicate() -> NSPredicate {
        NSPredicate(format: "beanRating >= 0")
    }

    private nonisolated func encodeCursor(_ cursor: CKQueryOperation.Cursor) -> String? {
        try? NSKeyedArchiver.archivedData(withRootObject: cursor, requiringSecureCoding: true).base64EncodedString()
    }

    private nonisolated func decodeCursor(_ string: String) -> CKQueryOperation.Cursor? {
        guard let data = Data(base64Encoded: string) else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKQueryOperation.Cursor.self, from: data)
    }
}
