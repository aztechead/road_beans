import CoreLocation
import Foundation

struct MissingCommunityService: CommunityService {
    func currentMember() async throws -> CommunityMemberSnapshot? { throw CommunityServiceError.missing }
    func join(displayName: String, profile: TasteProfile, existingVisits: [CommunityVisitDraft]) async throws { throw CommunityServiceError.missing }
    func leave(deleteRatings: Bool) async throws { throw CommunityServiceError.missing }
    func updateProfile(displayName: String, profile: TasteProfile) async throws { throw CommunityServiceError.missing }
    func publish(_ visit: CommunityVisitDraft) async throws -> String { throw CommunityServiceError.missing }
    func updatePublishedVisit(_ visit: CommunityVisitDraft) async throws { throw CommunityServiceError.missing }
    func deletePublishedVisit(localVisitID: UUID) async throws { throw CommunityServiceError.missing }
    func deleteVisit(recordName: String) async throws { throw CommunityServiceError.missing }
    func fetchFeedPage(cursor: String?, limit: Int, authorIDsToInclude: Set<String>?, authorIDsToExclude: Set<String>) async throws -> CommunityFeedPage { throw CommunityServiceError.missing }
    func fetchVisits(matchingMapKitIdentifier identifier: String) async throws -> [CommunityVisitRow] { throw CommunityServiceError.missing }
    func fetchVisits(near coordinate: CLLocationCoordinate2D, radiusMeters: Double, nameContains: String) async throws -> [CommunityVisitRow] { throw CommunityServiceError.missing }
    func fetchMember(userRecordID: String) async throws -> CommunityMemberSnapshot? { throw CommunityServiceError.missing }
    func fetchVisitDetail(recordName: String) async throws -> CommunityVisitDetail? { throw CommunityServiceError.missing }
    func like(visitRecordName: String) async throws { throw CommunityServiceError.missing }
    func unlike(visitRecordName: String) async throws { throw CommunityServiceError.missing }
    func isLikedByCurrentUser(_ recordName: String) async throws -> Bool { throw CommunityServiceError.missing }
    func comments(forVisitRecordName recordName: String) async throws -> [CommunityCommentRow] { throw CommunityServiceError.missing }
    func addComment(toVisitRecordName recordName: String, text: String) async throws -> CommunityCommentRow { throw CommunityServiceError.missing }
    func deleteComment(recordName: String) async throws { throw CommunityServiceError.missing }
}
