import CoreLocation
import Foundation
import Testing
@testable import Road_Beans

@Suite("MapTabViewModel")
@MainActor
struct MapTabViewModelTests {
    @Test func reloadFetchesAllWhenNearMeOff() async {
        let places = FakePlaceRepository()
        places.stored = [
            PlaceSummary(
                id: UUID(),
                name: "Loves",
                kind: .truckStop,
                address: nil,
                coordinate: CLLocationCoordinate2D(latitude: 34, longitude: -112),
                averageRating: nil,
                visitCount: 1
            )
        ]
        let permission = FakeLocationPermissionService(initial: .authorized)
        let viewModel = MapTabViewModel(places: places, permission: permission)

        await viewModel.reload(allowingNearMe: false)

        #expect(viewModel.places.count == 1)
        #expect(places.summariesNearCalls.isEmpty)
    }

    @Test func reloadFetchesNearWhenAuthorized() async {
        let places = FakePlaceRepository()
        places.stored = [
            PlaceSummary(
                id: UUID(),
                name: "Pilot",
                kind: .truckStop,
                address: nil,
                coordinate: CLLocationCoordinate2D(latitude: 34, longitude: -112),
                averageRating: nil,
                visitCount: 1
            )
        ]
        let permission = FakeLocationPermissionService(initial: .authorized)
        let viewModel = MapTabViewModel(places: places, permission: permission)

        await viewModel.refreshPermissionStatus()
        await viewModel.reload(allowingNearMe: true)

        #expect(viewModel.places.count == 1)
        #expect(places.summariesNearCalls.count == 1)
    }

    @Test func deniedPermissionExposed() async {
        let places = FakePlaceRepository()
        let permission = FakeLocationPermissionService(initial: .denied)
        let viewModel = MapTabViewModel(places: places, permission: permission)

        await viewModel.refreshPermissionStatus()

        #expect(viewModel.permissionStatus == .denied)
    }
}
