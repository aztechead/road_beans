import CoreLocation
import Testing
@testable import Road_Beans

@Suite("Smoke")
@MainActor
struct SmokeTests {
    @Test func seedDataIsDeterministicAndConnected() {
        #expect(RoadBeansSeedData.places.count == 2)
        #expect(RoadBeansSeedData.recentVisits.count == 2)
        #expect(RoadBeansSeedData.placeDetails[RoadBeansSeedData.lovesID]?.visits.first?.id == RoadBeansSeedData.lovesVisitID)
        #expect(RoadBeansSeedData.visitDetails[RoadBeansSeedData.lovesVisitID]?.placeID == RoadBeansSeedData.lovesID)
    }

    @Test func primaryNavigationViewModelsLoadSeededData() async {
        let places = FakePlaceRepository()
        places.stored = RoadBeansSeedData.places
        places.details = RoadBeansSeedData.placeDetails

        let visits = FakeVisitRepository()
        visits.recents = RoadBeansSeedData.recentVisits
        visits.details = RoadBeansSeedData.visitDetails

        let list = PlaceListViewModel(places: places, visits: visits)
        await list.reload()
        #expect(list.state == .loaded)
        #expect(list.filteredPlaces.count == 2)

        list.mode = .recentVisits
        list.searchText = "drip"
        #expect(list.filteredVisits.map(\.visit.id) == [RoadBeansSeedData.lovesVisitID])

        let map = MapTabViewModel(
            places: places,
            permission: FakeLocationPermissionService(initial: .authorized),
            currentLocation: FakeCurrentLocationProvider(coordinate: CLLocationCoordinate2D(latitude: 35.2, longitude: -112.4))
        )
        await map.refreshPermissionStatus()
        await map.reload(allowingNearMe: false)
        #expect(map.state == .loaded)
        #expect(map.places.map(\.id) == RoadBeansSeedData.places.map(\.id))

        let placeDetail = PlaceDetailViewModel(placeRepo: places, visitRepo: visits)
        await placeDetail.load(id: RoadBeansSeedData.lovesID)
        #expect(placeDetail.state == .loaded)
        #expect(placeDetail.detail?.name == "Loves Travel Stop")

        let visitDetail = VisitDetailViewModel(visits: visits, visitID: RoadBeansSeedData.lovesVisitID)
        await visitDetail.load()
        #expect(visitDetail.state == .loaded)
        #expect(visitDetail.detail?.drinks.first?.name == "House Drip")
    }

    @Test func emptyListAndMapDoNotFailSmokeState() async {
        let places = FakePlaceRepository()
        let visits = FakeVisitRepository()

        let list = PlaceListViewModel(places: places, visits: visits)
        await list.reload()
        #expect(list.state == .empty)

        let map = MapTabViewModel(
            places: places,
            permission: FakeLocationPermissionService(initial: .denied),
            currentLocation: FakeCurrentLocationProvider(coordinate: nil)
        )
        await map.refreshPermissionStatus()
        await map.reload(allowingNearMe: false)
        #expect(map.state == .empty)
    }
}
