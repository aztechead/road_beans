import CoreLocation
import Foundation
import Testing
@testable import Road_Beans

@Suite("CommunityFeedViewModel")
@MainActor
struct CommunityFeedViewModelTests {
    @Test func fetchFailureShowsErrorInsteadOfEmptyLoadedFeed() async throws {
        let service = ThrowingFeedCommunityService()
        let viewModel = CommunityFeedViewModel(service: service, favorites: FakeFavoriteMemberRepository())

        await viewModel.refresh()

        #expect(viewModel.state == .failed("Road Beans could not load community visits."))
        #expect(viewModel.everyoneRows.isEmpty)
    }

    @Test func allFilterExcludesCurrentMember() async throws {
        let service = InMemoryCommunityService(currentUserRecordID: "me")
        try await service.join(displayName: "Me", profile: .midpoint, existingVisits: [])
        _ = try await service.publish(draft())
        let viewModel = CommunityFeedViewModel(service: service, favorites: FakeFavoriteMemberRepository())

        await viewModel.refresh()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.everyoneRows.isEmpty)
    }

    @Test func mineFilterShowsOwnRows() async throws {
        let service = InMemoryCommunityService(currentUserRecordID: "me")
        try await service.join(displayName: "Me", profile: .midpoint, existingVisits: [])
        _ = try await service.publish(draft())
        let viewModel = CommunityFeedViewModel(service: service, favorites: FakeFavoriteMemberRepository())

        viewModel.filter = .mine
        await viewModel.refresh()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.everyoneRows.map(\.authorUserRecordID) == ["me"])
    }

    private func draft() -> CommunityVisitDraft {
        CommunityVisitDraft(
            localVisitID: UUID(),
            placeName: "Cafe",
            placeKindRawValue: PlaceKind.coffeeShop.rawValue,
            placeMapKitIdentifier: nil,
            placeLatitude: nil,
            placeLongitude: nil,
            visitDate: Date.now,
            beanRating: 4.2,
            drinkSummary: "Latte (Coffee)",
            tagSummary: "bright"
        )
    }
}

private final class FakeFavoriteMemberRepository: FavoriteMemberRepository, @unchecked Sendable {
    var memberIDs: Set<String> = []

    func add(memberUserRecordID: String) throws {
        memberIDs.insert(memberUserRecordID)
    }

    func remove(memberUserRecordID: String) throws {
        memberIDs.remove(memberUserRecordID)
    }

    func all() throws -> [FavoriteMemberSummary] {
        memberIDs.map {
            FavoriteMemberSummary(id: UUID(), memberUserRecordID: $0, addedAt: Date.now)
        }
    }

    func contains(memberUserRecordID: String) throws -> Bool {
        memberIDs.contains(memberUserRecordID)
    }
}

private struct ThrowingFeedCommunityService: CommunityService {
    func currentMember() async throws -> CommunityMemberSnapshot? {
        CommunityMemberSnapshot(userRecordID: "me", displayName: "Me", tasteProfile: .midpoint, joinedAt: Date.now)
    }

    func join(displayName: String, profile: TasteProfile, existingVisits: [CommunityVisitDraft]) async throws {}
    func leave() async throws {}
    func updateProfile(displayName: String, profile: TasteProfile) async throws {}
    func publish(_ visit: CommunityVisitDraft) async throws -> String { visit.localVisitID.uuidString }
    func updatePublishedVisit(_ visit: CommunityVisitDraft) async throws {}
    func deletePublishedVisit(localVisitID: UUID) async throws {}

    func fetchFeedPage(
        cursor: String?,
        limit: Int,
        authorIDsToInclude: Set<String>?,
        authorIDsToExclude: Set<String>
    ) async throws -> CommunityFeedPage {
        throw CommunityServiceError.underlying("boom")
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
    func like(visitRecordName: String) async throws {}
    func unlike(visitRecordName: String) async throws {}
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
