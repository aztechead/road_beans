import CoreLocation
import Foundation
import Testing
@testable import Road_Beans

@Suite("MapPlacePreviewContent")
struct MapPlacePreviewContentTests {
    @Test func personalPreviewShowsBrandedMetadataAndRouteTitle() {
        let place = PlaceSummary(
            id: UUID(),
            name: "Loves Travel Stop",
            kind: .truckStop,
            address: nil,
            coordinate: CLLocationCoordinate2D(latitude: 35.2, longitude: -112.1),
            averageRating: 4.2,
            visitCount: 3
        )

        let content = MapPlacePreviewContent.personal(place)

        #expect(content.title == "Loves Travel Stop")
        #expect(content.eyebrow == "Truck Stop")
        #expect(content.ratingLabel == "4.2 beans")
        #expect(content.reviewCountLabel == "3 reviews")
        #expect(content.contextLine == "Your reviews and notes at this stop.")
        #expect(content.routeButtonTitle == "Route in Maps")
        #expect(content.reviewsButtonTitle == "View all Reviews")
    }

    @Test func communityPreviewHighlightsReviewCountAndLatestReview() {
        let now = Date.now
        let older = CommunityVisitRow(
            id: "older",
            authorUserRecordID: "older-author",
            authorDisplayName: "Mara",
            authorTasteProfile: .midpoint,
            placeName: "Loves Travel Stop",
            placeKindRawValue: PlaceKind.truckStop.rawValue,
            placeMapKitIdentifier: nil,
            placeLatitude: 35.2,
            placeLongitude: -112.1,
            visitDate: now.addingTimeInterval(-600),
            beanRating: 3.8,
            drinkSummary: "Latte",
            tagSummary: "quiet",
            publishedAt: now.addingTimeInterval(-600),
            likeCount: 0,
            commentCount: 0
        )
        let newer = CommunityVisitRow(
            id: "newer",
            authorUserRecordID: "newer-author",
            authorDisplayName: "Jo",
            authorTasteProfile: .midpoint,
            placeName: "Loves Travel Stop",
            placeKindRawValue: PlaceKind.truckStop.rawValue,
            placeMapKitIdentifier: nil,
            placeLatitude: 35.2,
            placeLongitude: -112.1,
            visitDate: now,
            beanRating: 4.6,
            drinkSummary: "House Drip",
            tagSummary: "smooth, roadtrip",
            publishedAt: now,
            likeCount: 0,
            commentCount: 0
        )
        let annotation = CommunityPlaceAnnotation(
            id: "loves",
            name: "Loves Travel Stop",
            kind: .truckStop,
            coordinate: CLLocationCoordinate2D(latitude: 35.2, longitude: -112.1),
            averageRating: 4.2,
            reviewCount: 2,
            reviews: [older, newer]
        )

        let content = MapPlacePreviewContent.community(annotation)

        #expect(content.title == "Loves Travel Stop")
        #expect(content.eyebrow == "Community Truck Stop")
        #expect(content.ratingLabel == "4.2 beans")
        #expect(content.reviewCountLabel == "2 reviews")
        #expect(content.contextLine == "Community-tested stop with 2 shared reviews.")
        #expect(content.featuredReview?.id == "newer")
        #expect(content.routeButtonTitle == "Route in Maps")
    }
}
