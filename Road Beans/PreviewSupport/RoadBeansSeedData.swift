import CoreLocation
import Foundation

enum RoadBeansSeedData {
    static let lovesID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    static let dinerID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    static let lovesVisitID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
    static let dinerVisitID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
    static let dripID = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
    static let latteID = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!

    static let baseDate = Date(timeIntervalSince1970: 1_800_000_000)

    static var places: [PlaceSummary] {
        [
            PlaceSummary(
                id: lovesID,
                name: "Loves Travel Stop",
                kind: .truckStop,
                address: "I-40 Exit 140",
                coordinate: CLLocationCoordinate2D(latitude: 35.219, longitude: -112.482),
                averageRating: 4.2,
                visitCount: 2
            ),
            PlaceSummary(
                id: dinerID,
                name: "Sunrise Diner Coffee",
                kind: .coffeeShop,
                address: "88 Route 66",
                coordinate: CLLocationCoordinate2D(latitude: 35.191, longitude: -112.401),
                averageRating: 3.7,
                visitCount: 1
            )
        ]
    }

    static var recentVisits: [RecentVisitRow] {
        [
            RecentVisitRow(
                visit: VisitRow(
                    id: lovesVisitID,
                    date: baseDate,
                    drinkCount: 1,
                    tagNames: ["smooth", "roadtrip"],
                    photoCount: 0,
                    averageRating: 4.2
                ),
                placeName: "Loves Travel Stop",
                placeKind: .truckStop,
                drinkNames: ["House Drip"]
            ),
            RecentVisitRow(
                visit: VisitRow(
                    id: dinerVisitID,
                    date: baseDate.addingTimeInterval(-7_200),
                    drinkCount: 1,
                    tagNames: ["breakfast"],
                    photoCount: 0,
                    averageRating: 3.7
                ),
                placeName: "Sunrise Diner Coffee",
                placeKind: .coffeeShop,
                drinkNames: ["Road Latte"]
            )
        ]
    }

    static var placeDetails: [UUID: PlaceDetail] {
        [
            lovesID: PlaceDetail(
                id: lovesID,
                name: "Loves Travel Stop",
                kind: .truckStop,
                source: .mapKit,
                address: "I-40 Exit 140",
                streetNumber: nil,
                streetName: nil,
                city: "Seligman",
                region: "AZ",
                postalCode: nil,
                country: "US",
                phoneNumber: nil,
                websiteURL: nil,
                coordinate: CLLocationCoordinate2D(latitude: 35.219, longitude: -112.482),
                averageRating: 4.2,
                visits: [recentVisits[0].visit]
            ),
            dinerID: PlaceDetail(
                id: dinerID,
                name: "Sunrise Diner Coffee",
                kind: .coffeeShop,
                source: .custom,
                address: "88 Route 66",
                streetNumber: "88",
                streetName: "Route 66",
                city: "Seligman",
                region: "AZ",
                postalCode: nil,
                country: "US",
                phoneNumber: nil,
                websiteURL: nil,
                coordinate: CLLocationCoordinate2D(latitude: 35.191, longitude: -112.401),
                averageRating: 3.7,
                visits: [recentVisits[1].visit]
            )
        ]
    }

    static var visitDetails: [UUID: VisitDetail] {
        [
            lovesVisitID: VisitDetail(
                id: lovesVisitID,
                date: baseDate,
                placeID: lovesID,
                placeName: "Loves Travel Stop",
                placeKind: .truckStop,
                drinks: [
                    DrinkRow(id: dripID, name: "House Drip", category: .drip, rating: 4.2, tagNames: ["smooth"])
                ],
                tagNames: ["smooth", "roadtrip"],
                photos: []
            ),
            dinerVisitID: VisitDetail(
                id: dinerVisitID,
                date: baseDate.addingTimeInterval(-7_200),
                placeID: dinerID,
                placeName: "Sunrise Diner Coffee",
                placeKind: .coffeeShop,
                drinks: [
                    DrinkRow(id: latteID, name: "Road Latte", category: .latte, rating: 3.7, tagNames: ["breakfast"])
                ],
                tagNames: ["breakfast"],
                photos: []
            )
        ]
    }
}
