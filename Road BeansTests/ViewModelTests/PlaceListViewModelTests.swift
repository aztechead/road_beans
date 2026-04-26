import Foundation
import Testing
@testable import Road_Beans

@Suite("PlaceListViewModel")
@MainActor
struct PlaceListViewModelTests {
    @Test func filteredByPlaceName() async {
        let places = FakePlaceRepository()
        places.stored = [
            PlaceSummary(id: UUID(), name: "Loves", kind: .truckStop, address: nil, coordinate: nil, averageRating: 4.0, visitCount: 1),
            PlaceSummary(id: UUID(), name: "QT", kind: .gasStation, address: nil, coordinate: nil, averageRating: 3.0, visitCount: 1)
        ]
        let visits = FakeVisitRepository()
        let viewModel = PlaceListViewModel(places: places, visits: visits)

        await viewModel.reload()
        viewModel.searchText = "lov"

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
