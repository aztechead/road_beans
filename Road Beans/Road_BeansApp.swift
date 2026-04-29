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
    private let favoriteMemberRepository: any FavoriteMemberRepository
    private let communityService: any CommunityService
    private let communityMemberCache: CommunityMemberCache
    private let locationSearchService: any LocationSearchService
    private let locationPermissionService: any LocationPermissionService
    private let currentLocationProvider: any CurrentLocationProvider
    private let photoProcessingService: any PhotoProcessingService
    private let recommendationProfileService: any RecommendationProfileService
    private let nearbyRecommendationCandidateService: any NearbyRecommendationCandidateService
    private let recommendationEnrichmentService: any RecommendationEnrichmentService
    private let recommendationRankingService: any RecommendationRankingService

    @MainActor
    init() {
        #if DEBUG
        let screenshotMode = AppStoreScreenshotMode.isEnabled
        if screenshotMode {
            AppStoreScreenshotMode.completeOnboarding()
        }
        let icloud: any iCloudAvailabilityServiceProtocol = screenshotMode
            ? FakeICloudAvailabilityService(initialToken: "screenshot-user")
            : SystemICloudAvailabilityService()
        let persistence = PersistenceController(icloud: icloud, useInMemoryStores: screenshotMode)
        #else
        let icloud: any iCloudAvailabilityServiceProtocol = SystemICloudAvailabilityService()
        let persistence = PersistenceController(icloud: icloud)
        #endif
        let context = ModelContext(persistence.container)
        let sync = LocalOnlyRemoteSync()
        let photoProcessing = DefaultPhotoProcessingService()
        let tombstones = LocalTombstoneRepository(context: context, sync: sync)
        #if DEBUG
        let places: any PlaceRepository = screenshotMode
            ? AppStoreScreenshotMode.makePlaceRepository()
            : LocalPlaceRepository(context: context, sync: sync, tombstones: tombstones)
        #else
        let places: any PlaceRepository = LocalPlaceRepository(context: context, sync: sync, tombstones: tombstones)
        #endif
        let tags = LocalTagRepository(context: context, sync: sync)
        tags.seedDefaultsIfNeeded()
        let favoriteMembers = LocalFavoriteMemberRepository(context: context)
        let photos = LocalPhotoRepository(context: context, sync: sync)
        #if DEBUG
        let community: any CommunityService = screenshotMode
            ? AppStoreScreenshotMode.makeCommunityService()
            : CloudKitCommunityService()
        #else
        let community: any CommunityService = CloudKitCommunityService()
        #endif
        let communityMemberCache = CommunityMemberCache()
        #if DEBUG
        let visits: any VisitRepository
        if screenshotMode {
            visits = AppStoreScreenshotMode.makeVisitRepository()
        } else {
            visits = LocalVisitRepository(
                context: context,
                sync: sync,
                places: places,
                tags: tags,
                photos: photos,
                tombstones: tombstones,
                photoProcessor: photoProcessing
            )
        }
        #else
        let visits: any VisitRepository = LocalVisitRepository(
            context: context,
            sync: sync,
            places: places,
            tags: tags,
            photos: photos,
            tombstones: tombstones,
            photoProcessor: photoProcessing
        )
        #endif
        let publishCoordinator = CommunityPublishCoordinator(community: community) { id in
            try await visits.communityDraft(for: id)
        }
        if let localVisits = visits as? LocalVisitRepository {
            localVisits.attachCommunity(publishCoordinator)
        }

        self.icloud = icloud
        self.sync = sync
        self.placeRepository = places
        self.visitRepository = visits
        self.tagRepository = tags
        self.photoRepository = photos
        self.tombstoneRepository = tombstones
        self.favoriteMemberRepository = favoriteMembers
        self.communityService = community
        self.communityMemberCache = communityMemberCache
        self.locationSearchService = SystemLocationSearchService()
        self.locationPermissionService = SystemLocationPermissionService()
        self.currentLocationProvider = SystemCurrentLocationProvider()
        self.photoProcessingService = photoProcessing
        self.recommendationProfileService = LocalRecommendationProfileService()
        self.nearbyRecommendationCandidateService = AppleNativeRecommendationCandidateService(placeRepository: places)
        self.recommendationEnrichmentService = PassthroughRecommendationEnrichmentService()
        #if canImport(FoundationModels)
        self.recommendationRankingService = FoundationModelsRecommendationRankingService()
        #else
        self.recommendationRankingService = HeuristicRecommendationRankingService()
        #endif
        self._persistence = State(initialValue: persistence)

        #if DEBUG
        Task {
            await CloudKitCommunitySchemaBootstrapper().bootstrapDevelopmentSchema()
        }
        #endif

        Task {
            await communityMemberCache.preload(using: community)
        }
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
                .environment(\.favoriteMemberRepository, favoriteMemberRepository)
                .environment(\.communityService, communityService)
                .environment(\.communityMemberCache, communityMemberCache)
                .environment(\.locationSearchService, locationSearchService)
                .environment(\.locationPermissionService, locationPermissionService)
                .environment(\.currentLocationProvider, currentLocationProvider)
                .environment(\.photoProcessingService, photoProcessingService)
                .environment(\.recommendationProfileService, recommendationProfileService)
                .environment(\.nearbyRecommendationCandidateService, nearbyRecommendationCandidateService)
                .environment(\.recommendationEnrichmentService, recommendationEnrichmentService)
                .environment(\.recommendationRankingService, recommendationRankingService)
                .environment(\.iCloudAvailability, icloud)
                .environment(\.remoteSyncCoordinator, sync)
        }
    }
}
