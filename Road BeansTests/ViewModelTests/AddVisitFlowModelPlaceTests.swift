import CoreLocation
import Testing
@testable import Road_Beans

@Suite("AddVisitFlowModel place")
@MainActor
struct AddVisitFlowModelPlaceTests {
    func makeModel() -> AddVisitFlowModel {
        AddVisitFlowModel(
            visits: FakeVisitRepository(),
            tags: FakeTagRepository(),
            search: FakeLocationSearchService(canned: []),
            currentLocation: FakeCurrentLocationProvider(coordinate: nil),
            photoProcessor: DefaultPhotoProcessingService()
        )
    }

    @Test func selectMapKitSetsRefAndAdvancesPage() {
        let model = makeModel()
        let draft = MapKitPlaceDraft(
            name: "Loves",
            kind: .truckStop,
            mapKitIdentifier: "x",
            mapKitName: nil,
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

        model.selectMapKit(draft)

        if case .newMapKit(let selected) = model.placeRef {
            #expect(selected.name == "Loves")
        } else {
            Issue.record("Expected newMapKit place reference")
        }
        #expect(model.currentPage == 1)
    }

    @Test func searchEmptyResultSetsEmptyState() async throws {
        let model = makeModel()

        model.searchText = "nothing"
        await model.search()?.value

        #expect(model.searchState == .empty)
        #expect(model.searchResults.isEmpty)
    }

    @Test func searchFailureSetsFailedState() async throws {
        let model = AddVisitFlowModel(
            visits: FakeVisitRepository(),
            tags: FakeTagRepository(),
            search: FakeLocationSearchService(canned: [], error: FakeViewModelError.failed),
            currentLocation: FakeCurrentLocationProvider(coordinate: nil),
            photoProcessor: DefaultPhotoProcessingService()
        )

        model.searchText = "coffee"
        await model.search()?.value

        #expect(model.searchState.errorMessage != nil)
        #expect(model.searchResults.isEmpty)
    }

    @Test func searchUsesCurrentLocationAndSortsNearestFirst() async throws {
        let nearby = MapKitPlaceDraft(
            name: "Nearby Latte",
            kind: .coffeeShop,
            mapKitIdentifier: "near",
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
            name: "Far Latte",
            kind: .coffeeShop,
            mapKitIdentifier: "far",
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
        let search = FakeLocationSearchService(canned: [far, nearby])
        let model = AddVisitFlowModel(
            visits: FakeVisitRepository(),
            tags: FakeTagRepository(),
            search: search,
            currentLocation: FakeCurrentLocationProvider(coordinate: CLLocationCoordinate2D(latitude: 33.4484, longitude: -112.0740)),
            photoProcessor: DefaultPhotoProcessingService()
        )

        model.searchText = "latte"
        await model.search()?.value

        #expect(search.lastNear?.latitude == 33.4484)
        #expect(model.searchResults.map(\.name) == ["Nearby Latte", "Far Latte"])
    }
}
