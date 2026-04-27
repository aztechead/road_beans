import CoreLocation
import Foundation
import Testing
@testable import Road_Beans

@Suite("CommunityOnboardingViewModel")
@MainActor
struct CommunityOnboardingViewModelTests {
    @Test func schemaErrorShowsActionableMessage() async throws {
        let service = FailingJoinCommunityService(error: CommunityServiceError.schemaNotConfigured)
        let viewModel = CommunityOnboardingViewModel(service: service)

        let joined = await viewModel.join()

        #expect(joined == false)
        #expect(viewModel.errorMessage == "Road Beans could not join the community: community sharing is not enabled for this build yet. The CloudKit production schema needs to be deployed.")
    }
}

private struct FailingJoinCommunityService: CommunityService {
    let error: CommunityServiceError

    func currentMember() async throws -> CommunityMemberSnapshot? { nil }
    func join(displayName: String, profile: TasteProfile, existingVisits: [CommunityVisitDraft]) async throws { throw error }
    func leave(deleteRatings: Bool) async throws {}
    func updateProfile(displayName: String, profile: TasteProfile) async throws {}
    func publish(_ visit: CommunityVisitDraft) async throws -> String { visit.localVisitID.uuidString }
    func updatePublishedVisit(_ visit: CommunityVisitDraft) async throws {}
    func deletePublishedVisit(localVisitID: UUID) async throws {}
    func deleteVisit(recordName: String) async throws {}

    func fetchFeedPage(
        cursor: String?,
        limit: Int,
        authorIDsToInclude: Set<String>?,
        authorIDsToExclude: Set<String>
    ) async throws -> CommunityFeedPage {
        CommunityFeedPage(rows: [], nextCursor: nil)
    }

    func fetchVisits(matchingMapKitIdentifier identifier: String) async throws -> [CommunityVisitRow] { [] }

    func fetchVisits(
        near coordinate: CLLocationCoordinate2D,
        radiusMeters: Double,
        nameContains: String
    ) async throws -> [CommunityVisitRow] {
        []
    }

    func fetchMember(userRecordID: String) async throws -> CommunityMemberSnapshot? { nil }
    func fetchVisitDetail(recordName: String) async throws -> CommunityVisitDetail? { nil }
    func fetchLikedVisitsByCurrentUser() async throws -> [CommunityVisitRow] { [] }
    func like(visitRecordName: String) async throws {}
    func unlike(visitRecordName: String) async throws {}
    func isLikedByCurrentUser(_ recordName: String) async throws -> Bool { false }
    func comments(forVisitRecordName recordName: String) async throws -> [CommunityCommentRow] { [] }

    func addComment(toVisitRecordName recordName: String, text: String) async throws -> CommunityCommentRow {
        CommunityCommentRow(
            id: UUID().uuidString,
            authorUserRecordID: "me",
            authorDisplayName: "Me",
            text: text,
            timestamp: Date.now
        )
    }

    func deleteComment(recordName: String) async throws {}
}
