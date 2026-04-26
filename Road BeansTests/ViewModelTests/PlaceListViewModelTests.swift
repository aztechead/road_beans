import Foundation
import Testing
@testable import Road_Beans

@Suite("PlaceListViewModel")
@MainActor
struct PlaceListViewModelTests {
    @Test func filteredByPlaceName() async {
        let places = FakePlaceRepository()
        places.stored = [
            PlaceSummary(id: UUID(), name: "Loves", kind: .truckStop, address: "I-40", coordinate: nil, averageRating: 4.0, visitCount: 1),
            PlaceSummary(id: UUID(), name: "QT", kind: .gasStation, address: nil, coordinate: nil, averageRating: 3.0, visitCount: 1)
        ]
        let visits = FakeVisitRepository()
        let viewModel = PlaceListViewModel(places: places, visits: visits)

        await viewModel.reload()
        viewModel.searchText = "i-40"

        #expect(viewModel.state == .loaded)
        #expect(viewModel.filteredPlaces.count == 1)
        #expect(viewModel.filteredPlaces.first?.name == "Loves")
    }

    @Test func filteredVisitsByTag() async {
        let places = FakePlaceRepository()
        let visits = FakeVisitRepository()
        let firstID = UUID()
        let secondID = UUID()
        visits.recents = [
            RecentVisitRow(
                visit: VisitRow(id: firstID, date: .now, drinkCount: 1, tagNames: ["smooth"], photoCount: 0, averageRating: 4.0),
                placeName: "Loves",
                placeKind: .truckStop
            ),
            RecentVisitRow(
                visit: VisitRow(id: secondID, date: .now, drinkCount: 1, tagNames: ["burnt"], photoCount: 0, averageRating: 1.0),
                placeName: "Maverik",
                placeKind: .gasStation
            )
        ]
        let viewModel = PlaceListViewModel(places: places, visits: visits)

        await viewModel.reload()
        viewModel.searchText = "smooth"

        #expect(viewModel.filteredVisits.count == 1)
        #expect(viewModel.filteredVisits.first?.visit.id == firstID)
    }

    @Test func filteredVisitsByDrinkName() async {
        let places = FakePlaceRepository()
        let visits = FakeVisitRepository()
        let firstID = UUID()
        let secondID = UUID()
        visits.recents = [
            RecentVisitRow(
                visit: VisitRow(id: firstID, date: .now, drinkCount: 1, tagNames: [], photoCount: 0, averageRating: 4.0),
                placeName: "Loves",
                placeKind: .truckStop,
                drinkNames: ["cortado"]
            ),
            RecentVisitRow(
                visit: VisitRow(id: secondID, date: .now, drinkCount: 1, tagNames: [], photoCount: 0, averageRating: 1.0),
                placeName: "Maverik",
                placeKind: .gasStation,
                drinkNames: ["drip"]
            )
        ]
        let viewModel = PlaceListViewModel(places: places, visits: visits)

        await viewModel.reload()
        viewModel.searchText = "cort"

        #expect(viewModel.filteredVisits.count == 1)
        #expect(viewModel.filteredVisits.first?.visit.id == firstID)
    }

    @Test func modeSwitchingDoesNotLoseState() async {
        let places = FakePlaceRepository()
        places.stored = [
            PlaceSummary(id: UUID(), name: "Loves", kind: .truckStop, address: nil, coordinate: nil, averageRating: 4.0, visitCount: 1)
        ]
        let visits = FakeVisitRepository()
        let viewModel = PlaceListViewModel(places: places, visits: visits)

        await viewModel.reload()
        viewModel.searchText = "lov"
        viewModel.mode = .recentVisits
        viewModel.mode = .byPlace

        #expect(viewModel.searchText == "lov")
        #expect(viewModel.filteredPlaces.count == 1)
    }

    @Test func combinedPlaceFiltersMatchKindRatingTagAndDate() async {
        let baseDate = Date(timeIntervalSince1970: 1_800_000_000)
        let lovesID = UUID()
        let qtID = UUID()
        let places = FakePlaceRepository()
        places.stored = [
            PlaceSummary(id: lovesID, name: "Loves", kind: .truckStop, address: nil, coordinate: nil, averageRating: 4.5, visitCount: 2),
            PlaceSummary(id: qtID, name: "QT", kind: .gasStation, address: nil, coordinate: nil, averageRating: 4.8, visitCount: 1)
        ]
        let visits = FakeVisitRepository()
        visits.recents = [
            RecentVisitRow(
                visit: VisitRow(id: UUID(), date: baseDate, drinkCount: 1, tagNames: ["smooth", "roadtrip"], photoCount: 0, averageRating: 4.5),
                placeName: "Loves",
                placeKind: .truckStop
            ),
            RecentVisitRow(
                visit: VisitRow(id: UUID(), date: baseDate.addingTimeInterval(-90_000), drinkCount: 1, tagNames: ["smooth"], photoCount: 0, averageRating: 4.8),
                placeName: "QT",
                placeKind: .gasStation
            )
        ]
        let viewModel = PlaceListViewModel(places: places, visits: visits)

        await viewModel.reload()
        viewModel.selectedKind = .truckStop
        viewModel.ratingFilter = .fourPlus
        viewModel.selectedTags = ["roadtrip"]
        viewModel.isDateFilterEnabled = true
        viewModel.startDate = baseDate.addingTimeInterval(-3_600)
        viewModel.endDate = baseDate.addingTimeInterval(3_600)

        #expect(viewModel.filteredPlaces.map(\.id) == [lovesID])
        #expect(viewModel.activeFilterCount == 4)
    }

    @Test func combinedVisitFiltersMatchKindRatingTagDateAndSearch() async {
        let baseDate = Date(timeIntervalSince1970: 1_800_000_000)
        let firstID = UUID()
        let secondID = UUID()
        let places = FakePlaceRepository()
        let visits = FakeVisitRepository()
        visits.recents = [
            RecentVisitRow(
                visit: VisitRow(id: firstID, date: baseDate, drinkCount: 1, tagNames: ["smooth"], photoCount: 0, averageRating: 4.2),
                placeName: "Loves",
                placeKind: .truckStop,
                drinkNames: ["Cortado"]
            ),
            RecentVisitRow(
                visit: VisitRow(id: secondID, date: baseDate, drinkCount: 1, tagNames: ["burnt"], photoCount: 0, averageRating: 4.9),
                placeName: "Maverik",
                placeKind: .gasStation,
                drinkNames: ["Drip"]
            )
        ]
        let viewModel = PlaceListViewModel(places: places, visits: visits)

        await viewModel.reload()
        viewModel.mode = .recentVisits
        viewModel.searchText = "cort"
        viewModel.selectedKind = .truckStop
        viewModel.ratingFilter = .fourPlus
        viewModel.selectedTags = ["smooth"]
        viewModel.isDateFilterEnabled = true
        viewModel.startDate = baseDate.addingTimeInterval(-3_600)
        viewModel.endDate = baseDate.addingTimeInterval(3_600)

        #expect(viewModel.filteredVisits.map(\.visit.id) == [firstID])
        #expect(viewModel.availableTags == ["burnt", "smooth"])
    }

    @Test func clearFiltersPreservesModeAndSearch() async {
        let viewModel = PlaceListViewModel(places: FakePlaceRepository(), visits: FakeVisitRepository())

        viewModel.mode = .recentVisits
        viewModel.searchText = "latte"
        viewModel.selectedKind = .coffeeShop
        viewModel.ratingFilter = .threePlus
        viewModel.selectedTags = ["favorite"]
        viewModel.isDateFilterEnabled = true
        viewModel.clearFilters()

        #expect(viewModel.mode == .recentVisits)
        #expect(viewModel.searchText == "latte")
        #expect(viewModel.selectedKind == nil)
        #expect(viewModel.ratingFilter == .any)
        #expect(viewModel.selectedTags.isEmpty)
        #expect(!viewModel.isDateFilterEnabled)
    }

    @Test func emptyRepositoriesSetEmptyState() async {
        let viewModel = PlaceListViewModel(
            places: FakePlaceRepository(),
            visits: FakeVisitRepository()
        )

        await viewModel.reload()

        #expect(viewModel.state == .empty)
    }

    @Test func repositoryFailureSetsFailedState() async {
        let places = FakePlaceRepository()
        places.summariesError = FakeViewModelError.failed
        let viewModel = PlaceListViewModel(places: places, visits: FakeVisitRepository())

        await viewModel.reload()

        #expect(viewModel.state.errorMessage != nil)
        #expect(viewModel.places.isEmpty)
        #expect(viewModel.recentVisits.isEmpty)
    }
}
