import Foundation
import Testing
@testable import Road_Beans

@Suite("AddVisitFlowModel save")
@MainActor
struct AddVisitSaveTests {
    func makeModel() -> (AddVisitFlowModel, FakeVisitRepository) {
        let visits = FakeVisitRepository()
        let model = AddVisitFlowModel(
            visits: visits,
            tags: FakeTagRepository(),
            search: FakeLocationSearchService(canned: []),
            currentLocation: FakeCurrentLocationProvider(coordinate: nil),
            photoProcessor: DefaultPhotoProcessingService()
        )
        return (model, visits)
    }

    @Test func emptyDrinksRejected() async {
        let (model, _) = makeModel()
        model.placeRef = .newMapKit(mapKitDraft(name: "X", kind: .coffeeShop, identifier: "empty-drinks"))

        await #expect(throws: VisitValidationError.missingDrinks) {
            _ = try await model.save()
        }
    }

    @Test func missingPlaceRejected() async {
        let (model, _) = makeModel()
        model.drinks = [DrinkDraft(name: "Drip", category: .drip, rating: 3, tags: [])]

        await #expect(throws: VisitValidationError.missingPlace) {
            _ = try await model.save()
        }
    }

    @Test func savePassesCommand() async throws {
        let (model, visits) = makeModel()
        model.placeRef = .newMapKit(mapKitDraft(name: "Loves", kind: .truckStop, identifier: "loves"))
        model.drinks = [DrinkDraft(name: "CFHB", category: .drip, rating: 4.2, tags: ["bold"])]
        model.visitTags = ["roadtrip"]
        model.photos = [PhotoDraft(rawImageData: Data([1, 2, 3]), caption: "Counter")]

        let toast = try await model.save()

        #expect(toast == "Added to Loves.")
        #expect(visits.saved.count == 1)
        #expect(visits.saved[0].drinks == model.drinks)
        #expect(visits.saved[0].tags == ["roadtrip"])
        #expect(visits.saved[0].photos.count == 1)
    }

    private func mapKitDraft(name: String, kind: PlaceKind, identifier: String) -> MapKitPlaceDraft {
        MapKitPlaceDraft(
            name: name,
            kind: kind,
            mapKitIdentifier: identifier,
            mapKitName: name,
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
    }
}
