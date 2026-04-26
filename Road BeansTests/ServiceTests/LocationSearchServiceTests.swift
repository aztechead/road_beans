import CoreLocation
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
}
