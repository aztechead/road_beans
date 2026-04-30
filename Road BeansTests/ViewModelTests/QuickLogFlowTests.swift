import CoreLocation
import Testing
@testable import Road_Beans

@Suite("Quick log flow")
@MainActor
struct QuickLogFlowTests {
    @Test func quickLogHerePrefillsNearestSavedPlaceAndDrink() async throws {
        let nearestID = UUID()
        let fartherID = UUID()
        let places = FakePlaceRepository()
        places.stored = [
            place(id: fartherID, name: "Far Beans", latitude: 34.05, longitude: -112.05),
            place(id: nearestID, name: "Near Beans", latitude: 34.0004, longitude: -112.0004)
        ]
        let model = makeModel(
            places: places,
            currentLocation: FakeCurrentLocationProvider(coordinate: CLLocationCoordinate2D(latitude: 34, longitude: -112))
        )

        try await model.prepareQuickLogHere()

        #expect(model.placeRef == .existing(id: nearestID))
        #expect(model.currentPage == 2)
        #expect(model.drinks == [DrinkDraft(name: "Drip", category: .drip, rating: 3, tags: [])])
    }

    @Test func quickLogHereKeepsPlaceStepWhenNoNearbySavedPlaceExists() async throws {
        let places = FakePlaceRepository()
        places.stored = []
        let model = makeModel(
            places: places,
            currentLocation: FakeCurrentLocationProvider(coordinate: CLLocationCoordinate2D(latitude: 34, longitude: -112))
        )

        try await model.prepareQuickLogHere()

        #expect(model.placeRef == nil)
        #expect(model.currentPage == 0)
        #expect(model.drinks == [DrinkDraft(name: "Drip", category: .drip, rating: 3, tags: [])])
    }

    @Test func quickLogSaveUsesPrefilledPlaceAndMinimalDrink() async throws {
        let placeID = UUID()
        let visits = FakeVisitRepository()
        let places = FakePlaceRepository()
        places.stored = [place(id: placeID, name: "Near Beans", latitude: 34, longitude: -112)]
        let model = makeModel(
            visits: visits,
            places: places,
            currentLocation: FakeCurrentLocationProvider(coordinate: CLLocationCoordinate2D(latitude: 34, longitude: -112))
        )

        try await model.prepareQuickLogHere()
        model.drinks[0].rating = 4.5

        _ = try await model.save()

        #expect(visits.saved.count == 1)
        #expect(visits.saved[0].placeRef == .existing(id: placeID))
        #expect(visits.saved[0].drinks == [DrinkDraft(name: "Drip", category: .drip, rating: 4.5, tags: [])])
    }

    private func makeModel(
        visits: FakeVisitRepository = FakeVisitRepository(),
        places: FakePlaceRepository = FakePlaceRepository(),
        currentLocation: FakeCurrentLocationProvider
    ) -> AddVisitFlowModel {
        AddVisitFlowModel(
            visits: visits,
            places: places,
            tags: FakeTagRepository(),
            search: FakeLocationSearchService(canned: []),
            currentLocation: currentLocation,
            photoProcessor: DefaultPhotoProcessingService()
        )
    }

    private func place(id: UUID, name: String, latitude: Double, longitude: Double) -> PlaceSummary {
        PlaceSummary(
            id: id,
            name: name,
            kind: .coffeeShop,
            address: nil,
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            averageRating: nil,
            visitCount: 0
        )
    }
}
