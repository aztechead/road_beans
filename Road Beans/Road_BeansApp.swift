import SwiftUI
import SwiftData

@main
struct Road_BeansApp: App {
    @State private var persistence: PersistenceController

    private let icloud: any iCloudAvailabilityServiceProtocol
    private let sync: any RemoteSyncCoordinator
    private let placeRepository: any PlaceRepository
    private let visitRepository: any VisitRepository
    private let tagRepository: any TagRepository
    private let photoRepository: any PhotoRepository
    private let tombstoneRepository: any TombstoneRepository
    private let locationSearchService: any LocationSearchService
    private let locationPermissionService: any LocationPermissionService
    private let currentLocationProvider: any CurrentLocationProvider
    private let photoProcessingService: any PhotoProcessingService

    @MainActor
    init() {
        let icloud = SystemICloudAvailabilityService()
        let persistence = PersistenceController(icloud: icloud)
        let context = ModelContext(persistence.container)
        let sync = LocalOnlyRemoteSync()
        let photoProcessing = DefaultPhotoProcessingService()
        let tombstones = LocalTombstoneRepository(context: context, sync: sync)
        let places = LocalPlaceRepository(context: context, sync: sync, tombstones: tombstones)
        let tags = LocalTagRepository(context: context, sync: sync)
        tags.seedDefaultsIfNeeded()
        let photos = LocalPhotoRepository(context: context, sync: sync)
        let visits = LocalVisitRepository(
            context: context,
            sync: sync,
            places: places,
            tags: tags,
            photos: photos,
            tombstones: tombstones,
            photoProcessor: photoProcessing
        )

        self.icloud = icloud
        self.sync = sync
        self.placeRepository = places
        self.visitRepository = visits
        self.tagRepository = tags
        self.photoRepository = photos
        self.tombstoneRepository = tombstones
        self.locationSearchService = SystemLocationSearchService()
        self.locationPermissionService = SystemLocationPermissionService()
        self.currentLocationProvider = SystemCurrentLocationProvider()
        self.photoProcessingService = photoProcessing
        self._persistence = State(initialValue: persistence)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(persistence)
                .modelContainer(persistence.container)
                .environment(\.placeRepository, placeRepository)
                .environment(\.visitRepository, visitRepository)
                .environment(\.tagRepository, tagRepository)
                .environment(\.photoRepository, photoRepository)
                .environment(\.tombstoneRepository, tombstoneRepository)
                .environment(\.locationSearchService, locationSearchService)
                .environment(\.locationPermissionService, locationPermissionService)
                .environment(\.currentLocationProvider, currentLocationProvider)
                .environment(\.photoProcessingService, photoProcessingService)
                .environment(\.iCloudAvailability, icloud)
                .environment(\.remoteSyncCoordinator, sync)
        }
    }
}
