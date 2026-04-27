import CoreLocation
import MapKit
import Testing
@testable import Road_Beans

@Suite("LocationSearchService")
struct LocationSearchServiceTests {
    @Test func emptyQueryThrows() async {
        let service = FakeLocationSearchService(canned: [])

        await #expect(throws: LocationSearchError.self) {
            _ = try await service.search(query: "  ", near: nil)
        }
    }

    @Test func fakeReturnsCanned() async throws {
        let draft = MapKitPlaceDraft(
            name: "Love's",
            kind: .truckStop,
            mapKitIdentifier: "x",
            mapKitName: "Love's",
            address: nil,
            latitude: 34,
            longitude: -112,
            phoneNumber: nil,
            websiteURL: nil,
            streetNumber: nil,
            streetName: nil,
            city: nil,
            region: nil,
            postalCode: nil,
            country: nil
        )
        let service = FakeLocationSearchService(canned: [draft])

        let results = try await service.search(
            query: "loves",
            near: CLLocationCoordinate2D(latitude: 34, longitude: -112)
        )

        #expect(results.count == 1)
        #expect(results[0].name == "Love's")
        #expect(results[0].mapKitIdentifier == "x")
    }

    @Test func sortsResultsByDistanceWhenCoordinateIsAvailable() {
        let nearby = MapKitPlaceDraft(
            name: "Nearby",
            kind: .coffeeShop,
            mapKitIdentifier: nil,
            mapKitName: nil,
            address: nil,
            latitude: 33.45,
            longitude: -112.07,
            phoneNumber: nil,
            websiteURL: nil,
            streetNumber: nil,
            streetName: nil,
            city: nil,
            region: nil,
            postalCode: nil,
            country: nil
        )
        let far = MapKitPlaceDraft(
            name: "Far",
            kind: .coffeeShop,
            mapKitIdentifier: nil,
            mapKitName: nil,
            address: nil,
            latitude: 35.20,
            longitude: -111.65,
            phoneNumber: nil,
            websiteURL: nil,
            streetNumber: nil,
            streetName: nil,
            city: nil,
            region: nil,
            postalCode: nil,
            country: nil
        )

        let sorted = SystemLocationSearchService.sortedByDistance(
            [far, nearby],
            from: CLLocationCoordinate2D(latitude: 33.4484, longitude: -112.0740)
        )

        #expect(sorted.map(\.name) == ["Nearby", "Far"])
    }

    @Test func mapKitDraftUsesIOS26LocationAndAddress() {
        let address = MKAddress(
            fullAddress: "1 Coffee Way, Quartzsite, AZ 85346",
            shortAddress: "1 Coffee Way"
        )
        let item = MKMapItem(
            location: CLLocation(latitude: 33.6639, longitude: -114.2299),
            address: address
        )
        item.name = "Road Bean Cafe"
        item.phoneNumber = "555-0101"
        item.url = URL(string: "https://example.com")
        item.pointOfInterestCategory = .cafe

        let draft = SystemLocationSearchService.draft(from: item)

        #expect(draft.name == "Road Bean Cafe")
        #expect(draft.kind == .coffeeShop)
        #expect(draft.address == "1 Coffee Way")
        #expect(draft.latitude == 33.6639)
        #expect(draft.longitude == -114.2299)
        #expect(draft.phoneNumber == "555-0101")
        #expect(draft.websiteURL == URL(string: "https://example.com"))
        #expect(draft.streetNumber == nil)
        #expect(draft.streetName == nil)
        #expect(draft.postalCode == nil)
    }

    @Test func mapKitDraftFallsBackToFullAddress() {
        let address = MKAddress(
            fullAddress: "Quartzsite, AZ, United States",
            shortAddress: nil
        )
        let item = MKMapItem(
            location: CLLocation(latitude: 33.6639, longitude: -114.2299),
            address: address
        )

        let draft = SystemLocationSearchService.draft(from: item)

        #expect(draft.address?.contains("Quartzsite") == true)
    }
}
