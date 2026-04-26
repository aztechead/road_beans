import CoreLocation
import Foundation
import Observation

@Observable
@MainActor
final class MapTabViewModel {
    var places: [PlaceSummary] = []
    var nearMeOn = false
    var permissionStatus: LocationAuthorization = .notDetermined
    var currentLocationUnavailable = false

    private let placeRepository: any PlaceRepository
    private let permission: any LocationPermissionService
    private let currentLocation: any CurrentLocationProvider

    init(
        places: any PlaceRepository,
        permission: any LocationPermissionService,
        currentLocation: any CurrentLocationProvider
    ) {
        self.placeRepository = places
        self.permission = permission
        self.currentLocation = currentLocation
    }

    func refreshPermissionStatus() async {
        permissionStatus = await permission.status
    }

    func requestPermissionIfNeeded() async {
        guard permissionStatus == .notDetermined else { return }
        await permission.requestWhenInUse()
        permissionStatus = await permission.status
    }

    func reload(allowingNearMe: Bool) async {
        do {
            if allowingNearMe, permissionStatus == .authorized {
                let coordinate = try await currentLocation.currentCoordinate()
                places = try await placeRepository.summariesNear(
                    coordinate: coordinate,
                    radiusMeters: 50_000
                )
            } else {
                places = try await placeRepository.summaries()
            }
            currentLocationUnavailable = false
        } catch {
            currentLocationUnavailable = allowingNearMe && permissionStatus == .authorized
            places = []
        }
    }
}
