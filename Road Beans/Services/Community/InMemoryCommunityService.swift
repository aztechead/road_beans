import CoreLocation
import Foundation

actor InMemoryCommunityService: CommunityService {
    private let currentUserRecordID: String
    private var members: [String: CommunityMemberSnapshot]
    private var visits: [String: CommunityVisitRow]
    private var localVisitIndex: [UUID: String]
    private var likes: Set<String>
    private var commentRows: [String: [CommunityCommentRow]]

    init(
        currentUserRecordID: String = "preview-user",
        members: [CommunityMemberSnapshot] = [],
        visits: [CommunityVisitRow] = []
    ) {
        self.currentUserRecordID = currentUserRecordID
        self.members = Dictionary(uniqueKeysWithValues: members.map { ($0.userRecordID, $0) })
        self.visits = Dictionary(uniqueKeysWithValues: visits.map { ($0.id, $0) })
        self.localVisitIndex = [:]
        self.likes = []
        self.commentRows = [:]
    }

    func currentMember() async throws -> CommunityMemberSnapshot? {
        members[currentUserRecordID]
    }

    func join(displayName: String, profile: TasteProfile, existingVisits: [CommunityVisitDraft]) async throws {
        if members[currentUserRecordID] != nil { throw CommunityServiceError.alreadyMember }
        let member = CommunityMemberSnapshot(
            userRecordID: currentUserRecordID,
            displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            tasteProfile: profile,
            joinedAt: Date.now
        )
        members[currentUserRecordID] = member
        for visit in existingVisits {
            _ = try await publish(visit)
        }
    }

    func leave(deleteRatings: Bool) async throws {
        members[currentUserRecordID] = nil
        if deleteRatings {
            let authoredIDs = visits.values
                .filter { $0.authorUserRecordID == currentUserRecordID }
                .map(\.id)
            for id in authoredIDs {
                visits[id] = nil
                commentRows[id] = nil
                localVisitIndex = localVisitIndex.filter { $0.value != id }
                likes = likes.filter { !$0.hasPrefix("\(id)-") }
            }
        }
        likes = likes.filter { !$0.hasSuffix("-\(currentUserRecordID)") }
        for recordName in commentRows.keys {
            commentRows[recordName]?.removeAll { $0.authorUserRecordID == currentUserRecordID }
            visits[recordName]?.commentCount = commentRows[recordName, default: []].count
        }
    }

    func updateProfile(displayName: String, profile: TasteProfile) async throws {
        guard let existing = members[currentUserRecordID] else { throw CommunityServiceError.notAMember }
        members[currentUserRecordID] = CommunityMemberSnapshot(
            userRecordID: existing.userRecordID,
            displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            tasteProfile: profile,
            joinedAt: existing.joinedAt
        )
    }

    func publish(_ visit: CommunityVisitDraft) async throws -> String {
        guard let member = members[currentUserRecordID] else { throw CommunityServiceError.notAMember }
        let recordName = localVisitIndex[visit.localVisitID] ?? visit.localVisitID.uuidString
        localVisitIndex[visit.localVisitID] = recordName
        visits[recordName] = row(from: visit, recordName: recordName, member: member)
        return recordName
    }

    func updatePublishedVisit(_ visit: CommunityVisitDraft) async throws {
        _ = try await publish(visit)
    }

    func deletePublishedVisit(localVisitID: UUID) async throws {
        guard let recordName = localVisitIndex[localVisitID] ?? Optional(localVisitID.uuidString) else { return }
        visits[recordName] = nil
        commentRows[recordName] = nil
        localVisitIndex[localVisitID] = nil
        likes = likes.filter { !$0.hasPrefix("\(recordName)-") }
    }

    func deleteVisit(recordName: String) async throws {
        guard members[currentUserRecordID] != nil else { throw CommunityServiceError.notAMember }
        guard let row = visits[recordName] else { throw CommunityServiceError.notFound }
        guard row.authorUserRecordID == currentUserRecordID else { throw CommunityServiceError.notAuthor }
        visits[recordName] = nil
        commentRows[recordName] = nil
        localVisitIndex = localVisitIndex.filter { $0.value != recordName }
        likes = likes.filter { !$0.hasPrefix("\(recordName)-") }
    }

    func fetchFeedPage(
        cursor: String?,
        limit: Int,
        authorIDsToInclude: Set<String>?,
        authorIDsToExclude: Set<String>
    ) async throws -> CommunityFeedPage {
        let offset = Int(cursor ?? "0") ?? 0
        var rows = visits.values.sorted { $0.publishedAt > $1.publishedAt }
        if let include = authorIDsToInclude {
            rows = rows.filter { include.contains($0.authorUserRecordID) }
        }
        rows = rows.filter { !authorIDsToExclude.contains($0.authorUserRecordID) }
        let page = Array(rows.dropFirst(offset).prefix(limit))
        let nextOffset = offset + page.count
        return CommunityFeedPage(
            rows: page,
            nextCursor: nextOffset < rows.count ? String(nextOffset) : nil
        )
    }

    func fetchVisits(matchingMapKitIdentifier identifier: String) async throws -> [CommunityVisitRow] {
        visits.values
            .filter { $0.placeMapKitIdentifier == identifier }
            .sorted { $0.visitDate > $1.visitDate }
    }

    func fetchVisits(near coordinate: CLLocationCoordinate2D, radiusMeters: Double, nameContains: String) async throws -> [CommunityVisitRow] {
        let needle = nameContains.lowercased()
        return visits.values
            .filter { row in
                guard
                    row.placeName.lowercased().contains(needle),
                    let latitude = row.placeLatitude,
                    let longitude = row.placeLongitude
                else { return false }
                let rowLocation = CLLocation(latitude: latitude, longitude: longitude)
                let target = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                return rowLocation.distance(from: target) <= radiusMeters
            }
            .sorted { $0.visitDate > $1.visitDate }
    }

    func fetchMember(userRecordID: String) async throws -> CommunityMemberSnapshot? {
        members[userRecordID]
    }

    func fetchVisitDetail(recordName: String) async throws -> CommunityVisitDetail? {
        guard let row = visits[recordName] else { return nil }
        return CommunityVisitDetail(
            row: row,
            comments: commentRows[recordName, default: []].sorted { $0.timestamp < $1.timestamp },
            likedByCurrentUser: likes.contains(likeKey(recordName))
        )
    }

    func fetchLikedVisitsByCurrentUser() async throws -> [CommunityVisitRow] {
        let likedRecordNames = Set(likes.compactMap { key -> String? in
            guard key.hasSuffix("-\(currentUserRecordID)") else { return nil }
            return String(key.dropLast(currentUserRecordID.count + 1))
        })
        return visits.values
            .filter { likedRecordNames.contains($0.id) }
            .sorted { $0.publishedAt > $1.publishedAt }
    }

    func like(visitRecordName: String) async throws {
        guard visits[visitRecordName] != nil else { throw CommunityServiceError.notFound }
        likes.insert(likeKey(visitRecordName))
        visits[visitRecordName]?.likeCount = likes.filter { $0.hasPrefix("\(visitRecordName)-") }.count
    }

    func unlike(visitRecordName: String) async throws {
        likes.remove(likeKey(visitRecordName))
        visits[visitRecordName]?.likeCount = likes.filter { $0.hasPrefix("\(visitRecordName)-") }.count
    }

    func isLikedByCurrentUser(_ recordName: String) async throws -> Bool {
        likes.contains(likeKey(recordName))
    }

    func comments(forVisitRecordName recordName: String) async throws -> [CommunityCommentRow] {
        commentRows[recordName, default: []].sorted { $0.timestamp < $1.timestamp }
    }

    func addComment(toVisitRecordName recordName: String, text: String) async throws -> CommunityCommentRow {
        guard visits[recordName] != nil else { throw CommunityServiceError.notFound }
        guard let member = members[currentUserRecordID] else { throw CommunityServiceError.notAMember }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CommunityServiceError.invalidInput }
        let row = CommunityCommentRow(
            id: UUID().uuidString,
            authorUserRecordID: currentUserRecordID,
            authorDisplayName: member.displayName,
            text: trimmed,
            timestamp: Date.now
        )
        commentRows[recordName, default: []].append(row)
        visits[recordName]?.commentCount = commentRows[recordName, default: []].count
        return row
    }

    func deleteComment(recordName: String) async throws {
        for visitID in commentRows.keys {
            commentRows[visitID]?.removeAll { $0.id == recordName && $0.authorUserRecordID == currentUserRecordID }
            visits[visitID]?.commentCount = commentRows[visitID, default: []].count
        }
    }

    private func row(from draft: CommunityVisitDraft, recordName: String, member: CommunityMemberSnapshot) -> CommunityVisitRow {
        CommunityVisitRow(
            id: recordName,
            authorUserRecordID: member.userRecordID,
            authorDisplayName: member.displayName,
            authorTasteProfile: member.tasteProfile,
            placeName: draft.placeName,
            placeKindRawValue: draft.placeKindRawValue,
            placeMapKitIdentifier: draft.placeMapKitIdentifier,
            placeLatitude: draft.placeLatitude,
            placeLongitude: draft.placeLongitude,
            visitDate: draft.visitDate,
            beanRating: draft.beanRating,
            drinkSummary: draft.drinkSummary,
            tagSummary: draft.tagSummary,
            publishedAt: Date.now,
            likeCount: likes.filter { $0.hasPrefix("\(recordName)-") }.count,
            commentCount: commentRows[recordName, default: []].count
        )
    }

    private func likeKey(_ visitRecordName: String) -> String {
        "\(visitRecordName)-\(currentUserRecordID)"
    }
}
