import SwiftData
import SwiftUI

struct ContentView: View {
    var body: some View {
        RootView()
    }
}

#Preview {
    let icloud = FakeICloudAvailabilityService()
    let persistence = PersistenceController(icloud: icloud, useInMemoryStores: true)
    let context = ModelContext(persistence.container)
    let sync = LocalOnlyRemoteSync()
    let photoProcessing = DefaultPhotoProcessingService()
    let places = LocalPlaceRepository(context: context, sync: sync)
    let tags = LocalTagRepository(context: context, sync: sync)
    let photos = LocalPhotoRepository(context: context, sync: sync)
    let tombstones = LocalTombstoneRepository(context: context, sync: sync)
    let visits = LocalVisitRepository(
        context: context,
        sync: sync,
        places: places,
        tags: tags,
        photos: photos,
        tombstones: tombstones,
        photoProcessor: photoProcessing
    )

    ContentView()
        .environment(persistence)
        .modelContainer(persistence.container)
        .environment(\.placeRepository, places)
        .environment(\.visitRepository, visits)
        .environment(\.tagRepository, tags)
        .environment(\.photoRepository, photos)
        .environment(\.tombstoneRepository, tombstones)
        .environment(\.locationSearchService, FakeLocationSearchService(canned: []))
        .environment(\.locationPermissionService, FakeLocationPermissionService(initial: .denied))
        .environment(\.photoProcessingService, photoProcessing)
        .environment(\.iCloudAvailability, icloud)
        .environment(\.remoteSyncCoordinator, sync)
}
