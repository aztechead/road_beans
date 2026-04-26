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
        let location = FakeCurrentLocationProvider(coordinate: CLLocationCoordinate2D(latitude: 35, longitude: -111))
        let viewModel = MapTabViewModel(places: places, permission: permission, currentLocation: location)

        await viewModel.reload(allowingNearMe: false)

        #expect(viewModel.places.count == 1)
        #expect(places.summariesNearCalls.isEmpty)
        #expect(viewModel.mapCenter == nil)
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
        let location = FakeCurrentLocationProvider(coordinate: CLLocationCoordinate2D(latitude: 34.5, longitude: -112.25))
        let viewModel = MapTabViewModel(places: places, permission: permission, currentLocation: location)

        await viewModel.refreshPermissionStatus()
        await viewModel.reload(allowingNearMe: true)

        #expect(viewModel.places.count == 1)
        #expect(places.summariesNearCalls.count == 1)
        #expect(places.summariesNearCalls[0].coordinate.latitude == 34.5)
        #expect(places.summariesNearCalls[0].coordinate.longitude == -112.25)
        #expect(viewModel.currentLocationUnavailable == false)
        #expect(viewModel.isLoadingCurrentLocation == false)
        #expect(viewModel.mapCenter?.latitude == 34.5)
        #expect(viewModel.mapCenter?.longitude == -112.25)
    }

    @Test func deniedPermissionExposed() async {
        let places = FakePlaceRepository()
        let permission = FakeLocationPermissionService(initial: .denied)
        let location = FakeCurrentLocationProvider(coordinate: nil)
        let viewModel = MapTabViewModel(places: places, permission: permission, currentLocation: location)

        await viewModel.refreshPermissionStatus()

        #expect(viewModel.permissionStatus == .denied)
    }

    @Test func authorizedNearMeExposesUnavailableLocation() async {
        let places = FakePlaceRepository()
        let permission = FakeLocationPermissionService(initial: .authorized)
        let location = FakeCurrentLocationProvider(coordinate: nil)
        let viewModel = MapTabViewModel(places: places, permission: permission, currentLocation: location)

        await viewModel.refreshPermissionStatus()
        await viewModel.reload(allowingNearMe: true)

        #expect(viewModel.currentLocationUnavailable)
        #expect(viewModel.places.isEmpty)
        #expect(places.summariesNearCalls.isEmpty)
        #expect(viewModel.currentLocationErrorMessage != nil)
        #expect(viewModel.isLoadingCurrentLocation == false)
    }

    @Test func retryNearMeReloadsAfterUnavailableLocation() async {
        let places = FakePlaceRepository()
        places.stored = [
            PlaceSummary(
                id: UUID(),
                name: "Bean Stop",
                kind: .coffeeShop,
                address: nil,
                coordinate: CLLocationCoordinate2D(latitude: 34.1, longitude: -112.1),
                averageRating: nil,
                visitCount: 1
            )
        ]
        let permission = FakeLocationPermissionService(initial: .authorized)
        let location = FakeCurrentLocationProvider(coordinate: CLLocationCoordinate2D(latitude: 34.1, longitude: -112.1))
        let viewModel = MapTabViewModel(places: places, permission: permission, currentLocation: location)

        await viewModel.refreshPermissionStatus()
        await viewModel.retryNearMe()

        #expect(viewModel.nearMeOn)
        #expect(viewModel.currentLocationUnavailable == false)
        #expect(viewModel.places.count == 1)
        #expect(places.summariesNearCalls.count == 1)
    }

    @Test func usableSnapshotDrivesMapCenter() async {
        let places = FakePlaceRepository()
        let snapshot = CurrentLocationSnapshot(
            coordinate: CLLocationCoordinate2D(latitude: 35.2, longitude: -111.9),
            horizontalAccuracy: 42,
            timestamp: .now
        )
        let permission = FakeLocationPermissionService(initial: .authorized)
        let location = FakeCurrentLocationProvider(snapshot: snapshot)
        let viewModel = MapTabViewModel(places: places, permission: permission, currentLocation: location)

        await viewModel.refreshPermissionStatus()
        await viewModel.reload(allowingNearMe: true)

        #expect(viewModel.mapCenter == MapCenter(snapshot))
        #expect(viewModel.currentLocation == snapshot)
    }
}
