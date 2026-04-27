import CloudKit
import CoreLocation
import Foundation
import OSLog

#if DEBUG
actor CloudKitCommunitySchemaBootstrapper {
    private let container: CKContainer
    private let publicDB: CKDatabase
    private let encoder = JSONEncoder()
    private let logger = Logger(subsystem: "brainmeld.Road-Beans", category: "CommunitySchema")

    init(container: CKContainer = .default()) {
        self.container = container
        self.publicDB = container.publicCloudDatabase
    }

    func bootstrapDevelopmentSchema() async {
        do {
            let userID = try await currentUserRecordID().recordName
            let memberID = CKRecord.ID(recordName: "_schema_member_\(userID)")
            let visitID = CKRecord.ID(recordName: "_schema_visit_\(userID)")
            let likeID = CKRecord.ID(recordName: "_schema_like_\(userID)")
            let commentID = CKRecord.ID(recordName: "_schema_comment_\(userID)")
            let now = Date.now

            let member = CKRecord(recordType: CommunityRecordType.member, recordID: memberID)
            member["userRecordID"] = userID as NSString
            member["displayName"] = "Schema Bootstrap" as NSString
            member["tasteProfile"] = try encoder.encode(TasteProfile.midpoint) as NSData
            member["joinedAt"] = now as NSDate
            member["lastUpdatedAt"] = now as NSDate

            let visit = CKRecord(recordType: CommunityRecordType.visit, recordID: visitID)
            visit["localVisitID"] = UUID().uuidString as NSString
            visit["authorUserRecordID"] = userID as NSString
            visit["authorDisplayName"] = "Schema Bootstrap" as NSString
            visit["placeName"] = "Schema Cafe" as NSString
            visit["placeKind"] = PlaceKind.coffeeShop.rawValue as NSString
            visit["placeMapKitIdentifier"] = "schema-mapkit-id" as NSString
            visit["placeLatitude"] = 33.4484 as NSNumber
            visit["placeLongitude"] = -112.0740 as NSNumber
            visit["placeLocation"] = CLLocation(latitude: 33.4484, longitude: -112.0740)
            visit["visitDate"] = now as NSDate
            visit["beanRating"] = 4.2 as NSNumber
            visit["drinkSummary"] = "Latte (Coffee)" as NSString
            visit["tagSummary"] = "schema, bootstrap" as NSString
            visit["publishedAt"] = now as NSDate
            visit["lastUpdatedAt"] = now as NSDate

            let like = CKRecord(recordType: CommunityRecordType.like, recordID: likeID)
            like["communityVisitRecordName"] = visitID.recordName as NSString
            like["userRecordID"] = userID as NSString
            like["userDisplayName"] = "Schema Bootstrap" as NSString
            like["timestamp"] = now as NSDate

            let comment = CKRecord(recordType: CommunityRecordType.comment, recordID: commentID)
            comment["communityVisitRecordName"] = visitID.recordName as NSString
            comment["userRecordID"] = userID as NSString
            comment["userDisplayName"] = "Schema Bootstrap" as NSString
            comment["text"] = "Schema bootstrap comment" as NSString
            comment["timestamp"] = now as NSDate

            for record in [member, visit, like, comment] {
                _ = try await save(record)
            }

            await deleteBestEffort([commentID, likeID, visitID, memberID])
            logger.info("Community Development schema bootstrap completed")
        } catch {
            logger.error("Community Development schema bootstrap failed: \(String(describing: error), privacy: .public)")
        }
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

    private func save(_ record: CKRecord) async throws -> CKRecord {
        try await withCheckedThrowingContinuation { continuation in
            publicDB.save(record) { record, error in
                if let record {
                    continuation.resume(returning: record)
                } else {
                    continuation.resume(throwing: error ?? CommunityServiceError.underlying("CloudKit schema bootstrap save failed"))
                }
            }
        }
    }

    private func deleteBestEffort(_ recordIDs: [CKRecord.ID]) async {
        for recordID in recordIDs {
            do {
                _ = try await withCheckedThrowingContinuation { continuation in
                    publicDB.delete(withRecordID: recordID) { deletedID, error in
                        if let deletedID {
                            continuation.resume(returning: deletedID)
                        } else {
                            continuation.resume(throwing: error ?? CommunityServiceError.notFound)
                        }
                    }
                }
            } catch {
                logger.error("Community schema bootstrap cleanup failed for \(recordID.recordName, privacy: .public): \(String(describing: error), privacy: .public)")
            }
        }
    }
}
#endif
