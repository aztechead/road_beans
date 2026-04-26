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
            photoProcessor: DefaultPhotoProcessingService()
        )
        return (model, visits)
    }

    @Test func emptyDrinksRejected() async {
        let (model, _) = makeModel()
        model.placeRef = .newCustom(CustomPlaceDraft(name: "X", kind: .other, address: nil))

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
        model.placeRef = .newCustom(CustomPlaceDraft(name: "Loves", kind: .truckStop, address: nil))
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
}
