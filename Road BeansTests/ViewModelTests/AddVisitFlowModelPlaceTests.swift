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

    @Test func selectCustomSetsRefAndAdvancesPage() {
        let model = makeModel()

        model.selectCustom(CustomPlaceDraft(name: "My Stop", kind: .other, address: nil))

        if case .newCustom(let selected) = model.placeRef {
            #expect(selected.name == "My Stop")
        } else {
            Issue.record("Expected newCustom place reference")
        }
        #expect(model.currentPage == 1)
    }

    @Test func searchEmptyResultSetsEmptyState() async throws {
        let model = makeModel()

        model.searchText = "nothing"
        model.search()
        try await Task.sleep(nanoseconds: 350_000_000)

        #expect(model.searchState == .empty)
        #expect(model.searchResults.isEmpty)
    }

    @Test func searchFailureSetsFailedState() async throws {
        let model = AddVisitFlowModel(
            visits: FakeVisitRepository(),
            tags: FakeTagRepository(),
            search: FakeLocationSearchService(canned: [], error: FakeViewModelError.failed),
            photoProcessor: DefaultPhotoProcessingService()
        )

        model.searchText = "coffee"
        model.search()
        try await Task.sleep(nanoseconds: 350_000_000)

        #expect(model.searchState.errorMessage != nil)
        #expect(model.searchResults.isEmpty)
    }
}
