import CoreLocation
import Foundation
import Observation

@Observable
@MainActor
final class MapTabViewModel {
    var places: [PlaceSummary] = []
    var nearMeOn = false
    var permissionStatus: LocationAuthorization = .notDetermined
    var isLoadingCurrentLocation = false
    var currentLocation: CurrentLocationSnapshot?
    var currentLocationErrorMessage: String?
    var currentLocationUnavailable = false
    var mapCenter: MapCenter?

    private let placeRepository: any PlaceRepository
    private let permission: any LocationPermissionService
    private let currentLocationProvider: any CurrentLocationProvider

    init(
        places: any PlaceRepository,
        permission: any LocationPermissionService,
        currentLocation: any CurrentLocationProvider
    ) {
        self.placeRepository = places
        self.permission = permission
        self.currentLocationProvider = currentLocation
    }

    func refreshPermissionStatus() async {
        permissionStatus = await permission.status
    }

    func requestPermissionIfNeeded() async {
        guard permissionStatus == .notDetermined else { return }
        await permission.requestWhenInUse()
        permissionStatus = await permission.status
    }

    func retryNearMe() async {
        nearMeOn = true
        await reload(allowingNearMe: true)
    }

    func reload(allowingNearMe: Bool) async {
        do {
            if allowingNearMe, permissionStatus == .authorized {
                isLoadingCurrentLocation = true
                defer { isLoadingCurrentLocation = false }

                let location = try await currentLocationProvider.currentLocation()
                self.currentLocation = location
                mapCenter = MapCenter(location)
                places = try await placeRepository.summariesNear(
                    coordinate: location.coordinate,
                    radiusMeters: 50_000
                )
            } else {
                currentLocation = nil
                mapCenter = nil
                places = try await placeRepository.summaries()
            }
            currentLocationUnavailable = false
            currentLocationErrorMessage = nil
        } catch {
            isLoadingCurrentLocation = false
            currentLocationUnavailable = allowingNearMe && permissionStatus == .authorized
            currentLocationErrorMessage = "Road Beans could not get your current location. Check Location Services and try again."
            places = []
        }
    }
}

struct MapCenter: Equatable, Sendable {
    let latitude: Double
    let longitude: Double
    let horizontalAccuracy: Double

    init(_ location: CurrentLocationSnapshot) {
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        horizontalAccuracy = location.horizontalAccuracy
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
