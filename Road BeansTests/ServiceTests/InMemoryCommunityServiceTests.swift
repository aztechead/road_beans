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

    @Test func leaveCanRemoveAuthoredRecords() async throws {
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

        try await service.leave(deleteRatings: true)

        let page = try await service.fetchFeedPage(cursor: nil, limit: 50, authorIDsToInclude: nil, authorIDsToExclude: [])
        #expect(try await service.currentMember() == nil)
        #expect(page.rows.isEmpty)
    }

    @Test func leaveCanKeepAuthoredRecords() async throws {
        let service = InMemoryCommunityService(currentUserRecordID: "me")
        try await service.join(displayName: "Me", profile: .midpoint, existingVisits: [])
        let recordName = try await service.publish(draft())

        try await service.leave(deleteRatings: false)

        let page = try await service.fetchFeedPage(cursor: nil, limit: 50, authorIDsToInclude: nil, authorIDsToExclude: [])
        #expect(try await service.currentMember() == nil)
        #expect(page.rows.map(\.id) == [recordName])
    }

    @Test func deleteVisitRemovesOwnPublishedReviewAndSocialRows() async throws {
        let service = InMemoryCommunityService(currentUserRecordID: "me")
        try await service.join(displayName: "Me", profile: .midpoint, existingVisits: [])
        let recordName = try await service.publish(draft())
        try await service.like(visitRecordName: recordName)
        _ = try await service.addComment(toVisitRecordName: recordName, text: "Deleting this")

        try await service.deleteVisit(recordName: recordName)

        #expect(try await service.fetchVisitDetail(recordName: recordName) == nil)
        let page = try await service.fetchFeedPage(cursor: nil, limit: 50, authorIDsToInclude: nil, authorIDsToExclude: [])
        #expect(page.rows.isEmpty)
    }

    @Test func deleteVisitRejectsReviewsFromOtherMembers() async throws {
        let otherRow = CommunityVisitRow(
            id: "other-review",
            authorUserRecordID: "other",
            authorDisplayName: "Other",
            authorTasteProfile: .midpoint,
            placeName: "Cafe",
            placeKindRawValue: PlaceKind.coffeeShop.rawValue,
            placeMapKitIdentifier: nil,
            placeLatitude: nil,
            placeLongitude: nil,
            visitDate: Date.now,
            beanRating: 4,
            drinkSummary: "Drip",
            tagSummary: "",
            publishedAt: Date.now,
            likeCount: 0,
            commentCount: 0
        )
        let service = InMemoryCommunityService(
            currentUserRecordID: "me",
            members: [
                CommunityMemberSnapshot(userRecordID: "me", displayName: "Me", tasteProfile: .midpoint, joinedAt: Date.now),
                CommunityMemberSnapshot(userRecordID: "other", displayName: "Other", tasteProfile: .midpoint, joinedAt: Date.now)
            ],
            visits: [otherRow]
        )

        await #expect(throws: CommunityServiceError.notAuthor) {
            try await service.deleteVisit(recordName: "other-review")
        }
        #expect(try await service.fetchVisitDetail(recordName: "other-review") != nil)
    }

    private func draft() -> CommunityVisitDraft {
        CommunityVisitDraft(
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
    }
}
