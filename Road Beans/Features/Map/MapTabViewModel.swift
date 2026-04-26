import CoreLocation
import Foundation
import Observation

@Observable
@MainActor
final class MapTabViewModel {
    var places: [PlaceSummary] = []
    var nearMeOn = false
    var permissionStatus: LocationAuthorization = .notDetermined

    private let placeRepository: any PlaceRepository
    private let permission: any LocationPermissionService

    init(places: any PlaceRepository, permission: any LocationPermissionService) {
        self.placeRepository = places
        self.permission = permission
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
                places = try await placeRepository.summariesNear(
                    coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                    radiusMeters: 50_000
                )
            } else {
                places = try await placeRepository.summaries()
            }
        } catch {
            places = []
        }
    }
}
