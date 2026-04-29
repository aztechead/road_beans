import CoreLocation
import Foundation
import Observation

@Observable
@MainActor
final class MapTabViewModel {
    // MARK: - Personal places
    var places: [PlaceSummary] = []
    var nearMeOn = false
    var permissionStatus: LocationAuthorization = .notDetermined
    var isLoadingCurrentLocation = false
    var currentLocation: CurrentLocationSnapshot?
    var currentLocationErrorMessage: String?
    var currentLocationUnavailable = false
    var mapCenter: MapCenter?
    var state: ScreenState = .idle

    // MARK: - Community
    var communityReviewsOn = false
    var communityAnnotations: [CommunityPlaceAnnotation] = []
    var communityLoadState: ScreenState = .idle
    var isCommunityMember = false

    private var rawCommunityAnnotations: [CommunityPlaceAnnotation] = []

    // MARK: - Dependencies
    private let placeRepository: any PlaceRepository
    private let permission: any LocationPermissionService
    private let currentLocationProvider: any CurrentLocationProvider
    private let communityService: any CommunityService
    private let memberCache: CommunityMemberCache

    var hasVisibleMapContent: Bool {
        !places.isEmpty || currentLocation != nil || (communityReviewsOn && !communityAnnotations.isEmpty)
    }

    init(
        places: any PlaceRepository,
        permission: any LocationPermissionService,
        currentLocation: any CurrentLocationProvider,
        community: any CommunityService,
        memberCache: CommunityMemberCache = CommunityMemberCache()
    ) {
        self.placeRepository = places
        self.permission = permission
        self.currentLocationProvider = currentLocation
        self.communityService = community
        self.memberCache = memberCache
    }

    convenience init(
        places: any PlaceRepository,
        permission: any LocationPermissionService,
        currentLocation: any CurrentLocationProvider
    ) {
        self.init(
            places: places,
            permission: permission,
            currentLocation: currentLocation,
            community: MissingCommunityService()
        )
    }

    // MARK: - Location

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
        if places.isEmpty && currentLocation == nil {
            state = .loading
        }
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
            state = places.isEmpty ? .empty : .loaded
        } catch {
            isLoadingCurrentLocation = false
            currentLocationUnavailable = allowingNearMe && permissionStatus == .authorized
            currentLocationErrorMessage = "Road Beans could not get your current location. Check Location Services and try again."
            state = currentLocationUnavailable
                ? .failed(currentLocationErrorMessage ?? "Current location is unavailable.")
                : .failed("Road Beans could not load map stops. Try again.")
            places = []
        }
        if communityReviewsOn {
            applyFilters()
        }
    }

    // MARK: - Community

    func checkCommunityMembership() async {
        isCommunityMember = await memberCache.snapshot() != nil
    }

    func reloadCommunityAnnotations(enabled: Bool) async {
        guard enabled else {
            rawCommunityAnnotations = []
            communityAnnotations = []
            communityLoadState = .idle
            return
        }
        communityLoadState = .loading
        do {
            let authorIDsToExclude = await currentMemberIDToExclude()
            let page = try await communityService.fetchFeedPage(
                cursor: nil,
                limit: 200,
                authorIDsToInclude: nil,
                authorIDsToExclude: authorIDsToExclude
            )
            rawCommunityAnnotations = CommunityPlaceAnnotation.group(from: page.rows)
            applyFilters()
            communityLoadState = communityAnnotations.isEmpty ? .empty : .loaded
        } catch {
            rawCommunityAnnotations = []
            communityAnnotations = []
            communityLoadState = .failed("Could not load community reviews.")
        }
    }

    private func applyFilters() {
        communityAnnotations = rawCommunityAnnotations
    }

    private func currentMemberIDToExclude() async -> Set<String> {
        if let member = await memberCache.snapshot() {
            return [member.userRecordID]
        }
        guard let member = try? await communityService.currentMember() else {
            return []
        }
        await memberCache.store(member)
        return [member.userRecordID]
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
