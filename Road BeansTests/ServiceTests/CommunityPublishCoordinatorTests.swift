import Foundation
import Testing
@testable import Road_Beans

@Suite("CommunityPublishCoordinator")
struct CommunityPublishCoordinatorTests {
    @Test func publishesWhenMember() async throws {
        let service = InMemoryCommunityService(currentUserRecordID: "me")
        try await service.join(displayName: "Me", profile: .midpoint, existingVisits: [])
        let visitID = UUID()
        let coordinator = CommunityPublishCoordinator(community: service) { id in
            draft(id: id)
        }

        await coordinator.publishIfMember(visitID: visitID)

        let page = try await service.fetchFeedPage(cursor: nil, limit: 50, authorIDsToInclude: nil, authorIDsToExclude: [])
        #expect(page.rows.map(\.id) == [visitID.uuidString])
    }

    @Test func skipsWhenNotMember() async throws {
        let service = InMemoryCommunityService(currentUserRecordID: "me")
        let coordinator = CommunityPublishCoordinator(community: service) { id in
            draft(id: id)
        }

        await coordinator.publishIfMember(visitID: UUID())

        let page = try await service.fetchFeedPage(cursor: nil, limit: 50, authorIDsToInclude: nil, authorIDsToExclude: [])
        #expect(page.rows.isEmpty)
    }
}

nonisolated private func draft(id: UUID) -> CommunityVisitDraft {
    CommunityVisitDraft(
        localVisitID: id,
        placeName: "Cafe",
        placeKindRawValue: PlaceKind.coffeeShop.rawValue,
        placeMapKitIdentifier: nil,
        placeLatitude: nil,
        placeLongitude: nil,
        visitDate: Date.now,
        beanRating: 4,
        drinkSummary: "Latte",
        tagSummary: ""
    )
}
