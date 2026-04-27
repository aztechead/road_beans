import Foundation
import Testing
@testable import Road_Beans

@Suite("InMemoryCommunityService")
struct InMemoryCommunityServiceTests {
    @Test func joinPublishLikeAndComment() async throws {
        let service = InMemoryCommunityService(currentUserRecordID: "me")
        try await service.join(displayName: "Me", profile: .midpoint, existingVisits: [])
        let visit = CommunityVisitDraft(
            localVisitID: UUID(),
            placeName: "Cafe",
            placeKindRawValue: PlaceKind.coffeeShop.rawValue,
            placeMapKitIdentifier: "mapkit-1",
            placeLatitude: 33.4,
            placeLongitude: -111.9,
            visitDate: Date.now,
            beanRating: 4.5,
            drinkSummary: "Latte",
            tagSummary: "remote work friendly"
        )

        let recordName = try await service.publish(visit)
        try await service.like(visitRecordName: recordName)
        _ = try await service.addComment(toVisitRecordName: recordName, text: "Great stop")

        let detail = try await service.fetchVisitDetail(recordName: recordName)
        #expect(detail?.likedByCurrentUser == true)
        #expect(detail?.comments.map(\.text) == ["Great stop"])
        #expect(detail?.row.likeCount == 1)
        #expect(detail?.row.commentCount == 1)
    }

    @Test func leaveRemovesAuthoredRecords() async throws {
        let service = InMemoryCommunityService(currentUserRecordID: "me")
        try await service.join(displayName: "Me", profile: .midpoint, existingVisits: [
            CommunityVisitDraft(
                localVisitID: UUID(),
                placeName: "Cafe",
                placeKindRawValue: PlaceKind.coffeeShop.rawValue,
                placeMapKitIdentifier: nil,
                placeLatitude: nil,
                placeLongitude: nil,
                visitDate: Date.now,
                beanRating: 4,
                drinkSummary: "Drip",
                tagSummary: ""
            )
        ])

        try await service.leave()

        let page = try await service.fetchFeedPage(cursor: nil, limit: 50, authorIDsToInclude: nil, authorIDsToExclude: [])
        #expect(try await service.currentMember() == nil)
        #expect(page.rows.isEmpty)
    }
}
