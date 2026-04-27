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

        #expect(viewModel.state == .loaded)
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
        #expect(viewModel.state == .loaded)
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
        #expect(viewModel.state.errorMessage != nil)
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

    @Test func emptyMapSetsEmptyState() async {
        let places = FakePlaceRepository()
        let permission = FakeLocationPermissionService(initial: .authorized)
        let location = FakeCurrentLocationProvider(coordinate: CLLocationCoordinate2D(latitude: 34.5, longitude: -112.25))
        let viewModel = MapTabViewModel(places: places, permission: permission, currentLocation: location)

        await viewModel.refreshPermissionStatus()
        await viewModel.reload(allowingNearMe: true)

        #expect(viewModel.state == .empty)
    }

    @Test func communityAnnotationsCountAsVisibleMapContent() async {
        let viewModel = MapTabViewModel(
            places: FakePlaceRepository(),
            permission: FakeLocationPermissionService(initial: .authorized),
            currentLocation: FakeCurrentLocationProvider(coordinate: nil)
        )

        viewModel.communityReviewsOn = true
        viewModel.communityAnnotations = [
            CommunityPlaceAnnotation(
                id: "qa-bot",
                name: "Loves Travel Stop",
                kind: .truckStop,
                coordinate: CLLocationCoordinate2D(latitude: 35.4364, longitude: -112.482),
                averageRating: 4.2
            )
        ]

        #expect(viewModel.hasVisibleMapContent)
    }

    @Test func communityAnnotationsRemainVisibleBesidePersonalStops() async throws {
        let sharedCoordinate = CLLocationCoordinate2D(latitude: 33.4484, longitude: -112.074)
        let places = FakePlaceRepository()
        places.stored = [
            PlaceSummary(
                id: UUID(),
                name: "Schema Cafe",
                kind: .coffeeShop,
                address: nil,
                coordinate: sharedCoordinate,
                averageRating: nil,
                visitCount: 1
            )
        ]

        let service = InMemoryCommunityService(
            currentUserRecordID: "me",
            members: [
                CommunityMemberSnapshot(userRecordID: "other", displayName: "Other", tasteProfile: .midpoint, joinedAt: Date.now)
            ],
            visits: [
                CommunityVisitRow(
                    id: "other-review",
                    authorUserRecordID: "other",
                    authorDisplayName: "Other",
                    authorTasteProfile: .midpoint,
                    placeName: "Schema Cafe",
                    placeKindRawValue: PlaceKind.coffeeShop.rawValue,
                    placeMapKitIdentifier: "schema-mapkit-id",
                    placeLatitude: sharedCoordinate.latitude,
                    placeLongitude: sharedCoordinate.longitude,
                    visitDate: Date.now,
                    beanRating: 4.5,
                    drinkSummary: "Latte",
                    tagSummary: "",
                    publishedAt: Date.now,
                    likeCount: 0,
                    commentCount: 0
                )
            ]
        )

        let viewModel = MapTabViewModel(
            places: places,
            permission: FakeLocationPermissionService(initial: .authorized),
            currentLocation: FakeCurrentLocationProvider(coordinate: nil),
            community: service
        )

        await viewModel.reload(allowingNearMe: false)
        await viewModel.reloadCommunityAnnotations(enabled: true)

        #expect(viewModel.communityLoadState == .loaded)
        #expect(viewModel.communityAnnotations.map(\.id) == ["schema-mapkit-id"])
    }

    @Test func communityAnnotationsIgnorePersonalNearMeFilter() async throws {
        let communityCoordinate = CLLocationCoordinate2D(latitude: 35.4364, longitude: -112.482)
        let service = InMemoryCommunityService(
            currentUserRecordID: "me",
            members: [
                CommunityMemberSnapshot(userRecordID: "qa-bot", displayName: "QA Bot", tasteProfile: .midpoint, joinedAt: Date.now)
            ],
            visits: [
                CommunityVisitRow(
                    id: "qa-review",
                    authorUserRecordID: "qa-bot",
                    authorDisplayName: "QA Bot",
                    authorTasteProfile: .midpoint,
                    placeName: "QA Bot Loves Travel Stop",
                    placeKindRawValue: PlaceKind.truckStop.rawValue,
                    placeMapKitIdentifier: nil,
                    placeLatitude: communityCoordinate.latitude,
                    placeLongitude: communityCoordinate.longitude,
                    visitDate: Date.now,
                    beanRating: 4.2,
                    drinkSummary: "House Drip",
                    tagSummary: "",
                    publishedAt: Date.now,
                    likeCount: 0,
                    commentCount: 0
                )
            ]
        )
        let viewModel = MapTabViewModel(
            places: FakePlaceRepository(),
            permission: FakeLocationPermissionService(initial: .authorized),
            currentLocation: FakeCurrentLocationProvider(coordinate: CLLocationCoordinate2D(latitude: 33.4484, longitude: -112.074)),
            community: service
        )

        await viewModel.refreshPermissionStatus()
        viewModel.nearMeOn = true
        await viewModel.reload(allowingNearMe: true)
        await viewModel.reloadCommunityAnnotations(enabled: true)

        #expect(viewModel.nearMeOn)
        #expect(viewModel.communityAnnotations.map(\.name) == ["QA Bot Loves Travel Stop"])
    }

    @Test func communityAnnotationsExcludeCurrentMemberReviews() async throws {
        let service = InMemoryCommunityService(
            currentUserRecordID: "me",
            members: [
                CommunityMemberSnapshot(userRecordID: "me", displayName: "Me", tasteProfile: .midpoint, joinedAt: Date.now),
                CommunityMemberSnapshot(userRecordID: "other", displayName: "Other", tasteProfile: .midpoint, joinedAt: Date.now)
            ],
            visits: [
                CommunityVisitRow(
                    id: "self-review",
                    authorUserRecordID: "me",
                    authorDisplayName: "Me",
                    authorTasteProfile: .midpoint,
                    placeName: "My Local Stop",
                    placeKindRawValue: PlaceKind.coffeeShop.rawValue,
                    placeMapKitIdentifier: "self-place",
                    placeLatitude: 33.4484,
                    placeLongitude: -112.074,
                    visitDate: Date.now,
                    beanRating: 4.8,
                    drinkSummary: "Latte",
                    tagSummary: "",
                    publishedAt: Date.now,
                    likeCount: 0,
                    commentCount: 0
                ),
                CommunityVisitRow(
                    id: "other-review",
                    authorUserRecordID: "other",
                    authorDisplayName: "Other",
                    authorTasteProfile: .midpoint,
                    placeName: "Other Stop",
                    placeKindRawValue: PlaceKind.truckStop.rawValue,
                    placeMapKitIdentifier: "other-place",
                    placeLatitude: 35.4364,
                    placeLongitude: -112.482,
                    visitDate: Date.now,
                    beanRating: 4.2,
                    drinkSummary: "House Drip",
                    tagSummary: "",
                    publishedAt: Date.now,
                    likeCount: 0,
                    commentCount: 0
                )
            ]
        )
        let cache = CommunityMemberCache()
        await cache.store(CommunityMemberSnapshot(userRecordID: "me", displayName: "Me", tasteProfile: .midpoint, joinedAt: Date.now))
        let viewModel = MapTabViewModel(
            places: FakePlaceRepository(),
            permission: FakeLocationPermissionService(initial: .authorized),
            currentLocation: FakeCurrentLocationProvider(coordinate: nil),
            community: service,
            memberCache: cache
        )

        await viewModel.reloadCommunityAnnotations(enabled: true)

        #expect(viewModel.communityAnnotations.map(\.id) == ["other-place"])
    }
}
