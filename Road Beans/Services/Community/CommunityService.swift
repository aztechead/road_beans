import CoreLocation
import Foundation

struct CommunityVisitDraft: Sendable, Equatable {
    let localVisitID: UUID
    let placeName: String
    let placeKindRawValue: String
    let placeMapKitIdentifier: String?
    let placeLatitude: Double?
    let placeLongitude: Double?
    let visitDate: Date
    let beanRating: Double
    let drinkSummary: String
    let tagSummary: String
}

protocol CommunityService: Sendable {
    func currentMember() async throws -> CommunityMemberSnapshot?
    func join(displayName: String, profile: TasteProfile, existingVisits: [CommunityVisitDraft]) async throws
    func leave(deleteRatings: Bool) async throws
    func updateProfile(displayName: String, profile: TasteProfile) async throws

    func publish(_ visit: CommunityVisitDraft) async throws -> String
    func updatePublishedVisit(_ visit: CommunityVisitDraft) async throws
    func deletePublishedVisit(localVisitID: UUID) async throws
    func deleteVisit(recordName: String) async throws
    func reportVisit(_ report: CommunityReportDraft) async throws

    func fetchFeedPage(
        cursor: String?,
        limit: Int,
        authorIDsToInclude: Set<String>?,
        authorIDsToExclude: Set<String>
    ) async throws -> CommunityFeedPage

    func fetchVisits(matchingMapKitIdentifier identifier: String) async throws -> [CommunityVisitRow]
    func fetchVisits(near coordinate: CLLocationCoordinate2D, radiusMeters: Double, nameContains: String) async throws -> [CommunityVisitRow]
    func fetchMember(userRecordID: String) async throws -> CommunityMemberSnapshot?
    func fetchVisitDetail(recordName: String) async throws -> CommunityVisitDetail?
    func fetchLikedVisitsByCurrentUser() async throws -> [CommunityVisitRow]

    func like(visitRecordName: String) async throws
    func unlike(visitRecordName: String) async throws
    func isLikedByCurrentUser(_ recordName: String) async throws -> Bool
    func likedVisitIDsByCurrentUser(in recordNames: Set<String>) async throws -> Set<String>
}

extension CommunityService {
    func likedVisitIDsByCurrentUser(in recordNames: Set<String>) async throws -> Set<String> {
        var liked: Set<String> = []
        for recordName in recordNames {
            if try await isLikedByCurrentUser(recordName) {
                liked.insert(recordName)
            }
        }
        return liked
    }
}
