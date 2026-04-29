import CoreLocation
import Foundation
import Testing
@testable import Road_Beans

@Suite("Recommendation services")
struct RecommendationServiceTests {
    @Test func profileRequiresEnoughRatedVisits() async throws {
        let service = LocalRecommendationProfileService()
        let profile = try await service.buildProfile(from: [
            row(tags: ["quiet"], rating: 5),
            row(tags: ["espresso"], rating: 4)
        ])

        #expect(profile == nil)
    }

    @Test func profileWeightsTagsAndDrinksFromRatedVisits() async throws {
        let service = LocalRecommendationProfileService()
        let profile = try #require(await service.buildProfile(from: [
            row(drinks: ["Cortado"], tags: ["quiet", "local"], rating: 5),
            row(drinks: ["Cortado"], tags: ["quiet"], rating: 4),
            row(drinks: ["Latte"], tags: ["patio"], rating: 3)
        ]))

        #expect(profile.preferredTags.first?.value == "quiet")
        #expect(profile.preferredDrinks.first?.value == "Cortado")
        #expect(profile.preferredPlaceKinds.contains(.coffeeShop))
    }

    @Test func profileExtractsDislikedSignalsFromLowRatedVisits() async throws {
        let service = LocalRecommendationProfileService()
        let profile = try #require(await service.buildProfile(from: [
            row(drinks: ["Cortado"], tags: ["quiet"], rating: 5),
            row(drinks: ["Cortado"], tags: ["quiet"], rating: 4),
            row(drinks: ["Drip"], tags: ["loud"], rating: 2),
            row(drinks: ["Drip"], tags: ["loud"], rating: 1)
        ]))

        #expect(profile.dislikedTags.contains { $0.value == "loud" })
        #expect(profile.dislikedDrinks.contains { $0.value == "Drip" })
        #expect(profile.preferredTags.contains { $0.value == "quiet" })
        #expect(profile.preferredDrinks.contains { $0.value == "Cortado" })
    }

    @Test func semanticMatcherHandlesExactAndUnknown() async throws {
        let matcher = NLEmbeddingSemanticSignalMatcher()
        let tokens = matcher.tokens(in: "Quiet cafe with outdoor patio seating")

        #expect(matcher.match(keyword: "patio", in: tokens) == .exact)
        #expect(matcher.match(keyword: "zzqxyfake", in: tokens) == .none)
    }

    @Test func literalMatcherIsExactOnly() async throws {
        let matcher = LiteralSemanticSignalMatcher()
        let tokens = matcher.tokens(in: "Outdoor patio cafe")
        #expect(matcher.match(keyword: "patio", in: tokens) == .exact)
        #expect(matcher.match(keyword: "espresso", in: tokens) == .none)
    }

    @Test func heuristicRankingPrefersRelevantNearbyCoffee() async throws {
        let profile = RecommendationTasteProfile(
            preferredTags: [WeightedKeyword(value: "quiet", weight: 9)],
            preferredDrinks: [WeightedKeyword(value: "espresso", weight: 8)],
            dislikedTags: [],
            dislikedDrinks: [],
            preferredPlaceKinds: [.coffeeShop],
            summary: "quiet espresso"
        )
        let service = HeuristicRecommendationRankingService()
        let recommendations = try await service.rank(profile: profile, candidates: [
            enriched(
                name: "Quiet Espresso Bar",
                kind: .coffeeShop,
                distanceMeters: 500,
                publicSignals: ["quiet", "espresso"]
            ),
            enriched(
                name: "Busy Fuel",
                kind: .gasStation,
                distanceMeters: 300,
                publicSignals: ["gas station"]
            )
        ])

        #expect(recommendations.first?.placeName == "Quiet Espresso Bar")
        #expect(recommendations.first?.matchedSignals.contains("quiet") == true)
    }

    @Test func formattedDistanceUsesImperialUnitsWithTwoDecimals() async throws {
        #expect(RecommendationRanking.formattedDistance(733) == "0.46 mi")
        #expect(RecommendationRanking.formattedDistance(1_609.344) == "1.00 mi")
    }

    @Test func personalHistoryReasonDoesNotMentionDistance() async throws {
        let candidate = RecommendationCandidate(
            id: "local:1",
            source: .local,
            placeID: UUID(),
            mapKitIdentifier: nil,
            name: "Test Stop",
            kind: .coffeeShop,
            address: nil,
            coordinate: nil,
            distanceMeters: 733,
            localAverageRating: 4.6,
            localVisitCount: 2,
            websiteURL: nil,
            phoneNumber: nil
        )

        #expect(RecommendationRanking.personalHistoryReason(for: candidate) == "You rated this stop 4.6 beans before.")
    }

    @Test func deckViewModelStaysOptedOutUntilEnabled() async throws {
        let defaults = UserDefaults(suiteName: "RecommendationServiceTests-\(UUID().uuidString)")!
        let visits = FakeVisitRepository()
        visits.recents = [
            row(drinks: ["Latte"], tags: ["quiet"], rating: 5),
            row(drinks: ["Cortado"], tags: ["espresso"], rating: 4),
            row(drinks: ["Drip"], tags: ["local"], rating: 4)
        ]
        let candidates = FakeNearbyRecommendationCandidateService(candidates: [
            candidate(name: "Quiet Espresso Bar", distanceMeters: 500)
        ])
        let model = RecommendationDeckViewModel(
            visits: visits,
            placeRepository: FakePlaceRepository(),
            locationPermission: FakeLocationPermissionService(initial: .authorized),
            currentLocation: FakeCurrentLocationProvider(coordinate: CLLocationCoordinate2D(latitude: 33.45, longitude: -112.07)),
            profileService: LocalRecommendationProfileService(),
            candidateService: candidates,
            enrichmentService: PassthroughRecommendationEnrichmentService(),
            rankingService: HeuristicRecommendationRankingService(),
            defaults: defaults
        )

        await model.reload()
        #expect(model.availability == .optedOut)
        #expect(model.recommendations.isEmpty)

        await model.enable()
        #expect(model.availability == .ready)
        #expect(model.recommendations.first?.placeName == "Quiet Espresso Bar")
    }

    @Test func deckViewModelPersistsOptInToInjectedDefaults() async throws {
        let defaults = UserDefaults(suiteName: "RecommendationServiceTests-\(UUID().uuidString)")!
        let standardBefore = UserDefaults.standard.bool(forKey: RecommendationDeckViewModel.optInStorageKey)
        let visits = FakeVisitRepository()
        visits.recents = [
            row(drinks: ["Latte"], tags: ["quiet"], rating: 5),
            row(drinks: ["Cortado"], tags: ["espresso"], rating: 4),
            row(drinks: ["Drip"], tags: ["local"], rating: 4)
        ]
        let model = RecommendationDeckViewModel(
            visits: visits,
            placeRepository: FakePlaceRepository(),
            locationPermission: FakeLocationPermissionService(initial: .authorized),
            currentLocation: FakeCurrentLocationProvider(coordinate: CLLocationCoordinate2D(latitude: 33.45, longitude: -112.07)),
            profileService: LocalRecommendationProfileService(),
            candidateService: FakeNearbyRecommendationCandidateService(candidates: [
                candidate(name: "Quiet Espresso Bar", distanceMeters: 500)
            ]),
            enrichmentService: PassthroughRecommendationEnrichmentService(),
            rankingService: HeuristicRecommendationRankingService(),
            defaults: defaults
        )

        await model.enable()

        #expect(defaults.bool(forKey: RecommendationDeckViewModel.optInStorageKey))
        #expect(UserDefaults.standard.bool(forKey: RecommendationDeckViewModel.optInStorageKey) == standardBefore)
    }

    @Test func deckViewModelUnlocksWithThreeDrinkRatingsAcrossFewerVisits() async throws {
        let defaults = UserDefaults(suiteName: "RecommendationServiceTests-\(UUID().uuidString)")!
        let visits = FakeVisitRepository()
        visits.recents = [
            row(drinks: ["Latte", "Cortado"], tags: ["quiet"], rating: 5),
            row(drinks: ["Drip"], tags: ["espresso"], rating: 4)
        ]
        let model = RecommendationDeckViewModel(
            visits: visits,
            placeRepository: FakePlaceRepository(),
            locationPermission: FakeLocationPermissionService(initial: .authorized),
            currentLocation: FakeCurrentLocationProvider(coordinate: CLLocationCoordinate2D(latitude: 33.45, longitude: -112.07)),
            profileService: LocalRecommendationProfileService(),
            candidateService: FakeNearbyRecommendationCandidateService(candidates: [
                candidate(name: "Quiet Espresso Bar", distanceMeters: 500)
            ]),
            enrichmentService: PassthroughRecommendationEnrichmentService(),
            rankingService: HeuristicRecommendationRankingService(),
            defaults: defaults
        )

        await model.enable()

        #expect(model.optInProgress.ratedVisits == 3)
        #expect(model.availability == .ready)
    }

    @Test func deckViewModelShowsLearningStateWhenTappedWithoutEnoughRatings() async throws {
        let defaults = UserDefaults(suiteName: "RecommendationServiceTests-\(UUID().uuidString)")!
        let visits = FakeVisitRepository()
        visits.recents = [
            row(drinks: ["Latte"], tags: ["quiet"], rating: 5),
            row(drinks: ["Cortado"], tags: ["espresso"], rating: 4)
        ]
        let model = RecommendationDeckViewModel(
            visits: visits,
            placeRepository: FakePlaceRepository(),
            locationPermission: FakeLocationPermissionService(initial: .authorized),
            currentLocation: FakeCurrentLocationProvider(coordinate: CLLocationCoordinate2D(latitude: 33.45, longitude: -112.07)),
            profileService: LocalRecommendationProfileService(),
            candidateService: FakeNearbyRecommendationCandidateService(candidates: []),
            enrichmentService: PassthroughRecommendationEnrichmentService(),
            rankingService: HeuristicRecommendationRankingService(),
            defaults: defaults
        )

        await model.enable()

        #expect(model.availability == .learning(LearningProgress(totalVisits: 2, ratedVisits: 2, required: 3)))
        #expect(!model.isOptedIn)
    }

    @Test func deckViewModelSurfacesRankingFallbackMessage() async throws {
        let defaults = UserDefaults(suiteName: "RecommendationServiceTests-\(UUID().uuidString)")!
        defaults.set(true, forKey: RecommendationDeckViewModel.optInStorageKey)
        let visits = FakeVisitRepository()
        visits.recents = [
            row(drinks: ["Latte"], tags: ["quiet"], rating: 5),
            row(drinks: ["Cortado"], tags: ["espresso"], rating: 4),
            row(drinks: ["Drip"], tags: ["local"], rating: 4)
        ]
        let model = RecommendationDeckViewModel(
            visits: visits,
            placeRepository: FakePlaceRepository(),
            locationPermission: FakeLocationPermissionService(initial: .authorized),
            currentLocation: FakeCurrentLocationProvider(coordinate: CLLocationCoordinate2D(latitude: 33.45, longitude: -112.07)),
            profileService: LocalRecommendationProfileService(),
            candidateService: FakeNearbyRecommendationCandidateService(candidates: [
                candidate(name: "Quiet Espresso Bar", distanceMeters: 500)
            ]),
            enrichmentService: PassthroughRecommendationEnrichmentService(),
            rankingService: FallbackMessageRankingService(),
            defaults: defaults
        )

        await model.reload()

        #expect(model.rankingStatusMessage == "Apple Intelligence is unavailable; using on-device matching.")
        #expect(model.recommendations.first?.placeName == "Quiet Espresso Bar")
    }

    @Test func deckViewModelPersistsDismissedRecommendationsAcrossReloads() async throws {
        let defaults = UserDefaults(suiteName: "RecommendationServiceTests-\(UUID().uuidString)")!
        defaults.set(true, forKey: RecommendationDeckViewModel.optInStorageKey)
        let visits = FakeVisitRepository()
        visits.recents = [
            row(drinks: ["Latte"], tags: ["quiet"], rating: 5),
            row(drinks: ["Cortado"], tags: ["espresso"], rating: 4),
            row(drinks: ["Drip"], tags: ["local"], rating: 4)
        ]
        let model = RecommendationDeckViewModel(
            visits: visits,
            placeRepository: FakePlaceRepository(),
            locationPermission: FakeLocationPermissionService(initial: .authorized),
            currentLocation: FakeCurrentLocationProvider(coordinate: CLLocationCoordinate2D(latitude: 33.45, longitude: -112.07)),
            profileService: LocalRecommendationProfileService(),
            candidateService: FakeNearbyRecommendationCandidateService(candidates: [
                candidate(name: "Quiet Espresso Bar", distanceMeters: 500),
                candidate(name: "Patio Coffee", distanceMeters: 600)
            ]),
            enrichmentService: PassthroughRecommendationEnrichmentService(),
            rankingService: HeuristicRecommendationRankingService(),
            defaults: defaults
        )

        await model.reload()
        let dismissed = try #require(model.recommendations.first)
        model.dismiss(dismissed)
        await model.reload()

        #expect(!model.recommendations.contains { $0.id == dismissed.id })
        #expect(!(defaults.stringArray(forKey: RecommendationDeckViewModel.dismissedStorageKey) ?? []).isEmpty)
    }

    @Test func deckViewModelSavesMapKitRecommendationAsPlace() async throws {
        let places = FakePlaceRepository()
        let model = RecommendationDeckViewModel(
            visits: FakeVisitRepository(),
            placeRepository: places,
            locationPermission: FakeLocationPermissionService(initial: .authorized),
            currentLocation: FakeCurrentLocationProvider(coordinate: nil),
            profileService: LocalRecommendationProfileService(),
            candidateService: FakeNearbyRecommendationCandidateService(candidates: []),
            enrichmentService: PassthroughRecommendationEnrichmentService(),
            rankingService: HeuristicRecommendationRankingService(),
            defaults: UserDefaults(suiteName: "RecommendationServiceTests-\(UUID().uuidString)")!
        )
        let recommendation = PlaceRecommendation(
            id: "mapkit:abc",
            source: .mapKit,
            placeID: nil,
            mapKitIdentifier: "abc",
            placeName: "Searchable Cafe",
            kind: .coffeeShop,
            address: "123 Main St",
            coordinate: CLLocationCoordinate2D(latitude: 33.45, longitude: -112.07),
            distanceMeters: 500,
            score: 82,
            confidence: .high,
            reasons: [],
            cautions: [],
            matchedSignals: [],
            attributions: []
        )

        let id = try await model.saveRecommendationAsPlace(recommendation)

        #expect(id == places.createdID)
        guard case .newMapKit(let draft)? = places.createdReferences.first else {
            Issue.record("Expected a MapKit place draft")
            return
        }
        #expect(draft.name == "Searchable Cafe")
        #expect(draft.mapKitIdentifier == "abc")
    }

    @Test func candidateDeduplicationMergesNearbySameNamedPlaces() async throws {
        let first = candidate(
            name: "Searchable Cafe",
            kind: .coffeeShop,
            distanceMeters: 500,
            coordinate: CLLocationCoordinate2D(latitude: 33.45, longitude: -112.07),
            address: nil
        )
        let duplicate = candidate(
            name: "searchable cafe",
            kind: .coffeeShop,
            distanceMeters: 510,
            coordinate: CLLocationCoordinate2D(latitude: 33.4502, longitude: -112.0702),
            address: nil
        )

        let deduped = AppleNativeRecommendationCandidateService.deduplicated([first, duplicate])

        #expect(deduped.count == 1)
        #expect(deduped.first?.name == "Searchable Cafe")
    }

    @Test func communityEnrichmentAddsAverageReviewSignals() async throws {
        let community = CommunityAverageCommunityService(rows: [
            communityRow(rating: 4),
            communityRow(rating: 5),
            communityRow(rating: 3)
        ])
        let service = CommunityAwareRecommendationEnrichmentService(
            community: community,
            fallback: PassthroughRecommendationEnrichmentService()
        )

        let enriched = try await service.enrich([
            candidate(
                name: "Searchable Cafe",
                kind: .coffeeShop,
                distanceMeters: 500,
                coordinate: CLLocationCoordinate2D(latitude: 33.45, longitude: -112.07),
                address: "123 Main St",
                mapKitIdentifier: "mapkit-cafe"
            )
        ])

        #expect(enriched.first?.publicSignals.contains("4.0-bean community average") == true)
        #expect(enriched.first?.publicSignals.contains("3 community reviews") == true)
    }

    private func row(
        drinks: [String] = [],
        tags: [String],
        kind: PlaceKind = .coffeeShop,
        rating: Double
    ) -> RecentVisitRow {
        RecentVisitRow(
            visit: VisitRow(
                id: UUID(),
                date: .now,
                drinkCount: drinks.count,
                tagNames: tags,
                photoCount: 0,
                averageRating: rating
            ),
            placeName: "Test Stop",
            placeKind: kind,
            drinkNames: drinks
        )
    }

    private func candidate(
        name: String,
        kind: PlaceKind = .coffeeShop,
        distanceMeters: Double
    ) -> RecommendationCandidate {
        RecommendationCandidate(
            id: name,
            source: .mapKit,
            placeID: nil,
            mapKitIdentifier: nil,
            name: name,
            kind: kind,
            address: nil,
            coordinate: CLLocationCoordinate2D(latitude: 33.45, longitude: -112.07),
            distanceMeters: distanceMeters,
            localAverageRating: nil,
            localVisitCount: 0,
            websiteURL: nil,
            phoneNumber: nil
        )
    }

    private func candidate(
        name: String,
        kind: PlaceKind = .coffeeShop,
        distanceMeters: Double,
        coordinate: CLLocationCoordinate2D?,
        address: String?,
        mapKitIdentifier: String? = nil
    ) -> RecommendationCandidate {
        RecommendationCandidate(
            id: mapKitIdentifier.map { "mapkit:\($0)" } ?? name,
            source: .mapKit,
            placeID: nil,
            mapKitIdentifier: mapKitIdentifier,
            name: name,
            kind: kind,
            address: address,
            coordinate: coordinate,
            distanceMeters: distanceMeters,
            localAverageRating: nil,
            localVisitCount: 0,
            websiteURL: nil,
            phoneNumber: nil
        )
    }

    private func communityRow(rating: Double) -> CommunityVisitRow {
        CommunityVisitRow(
            id: UUID().uuidString,
            authorUserRecordID: "other",
            authorDisplayName: "Other",
            authorTasteProfile: nil,
            placeName: "Searchable Cafe",
            placeKindRawValue: PlaceKind.coffeeShop.rawValue,
            placeMapKitIdentifier: "mapkit-cafe",
            placeLatitude: 33.45,
            placeLongitude: -112.07,
            visitDate: .now,
            beanRating: rating,
            drinkSummary: "Latte",
            tagSummary: "quiet",
            publishedAt: .now,
            likeCount: 0,
            commentCount: 0
        )
    }

    private func enriched(
        name: String,
        kind: PlaceKind,
        distanceMeters: Double,
        publicSignals: [String]
    ) -> EnrichedRecommendationCandidate {
        EnrichedRecommendationCandidate(
            candidate: candidate(name: name, kind: kind, distanceMeters: distanceMeters),
            publicSignals: publicSignals,
            attributions: [RecommendationAttribution(sourceName: "Test", detail: "Fixture")]
        )
    }
}

private struct FakeNearbyRecommendationCandidateService: NearbyRecommendationCandidateService {
    let candidates: [RecommendationCandidate]

    func candidates(
        near coordinate: CLLocationCoordinate2D,
        radiusMeters: Double,
        profile: RecommendationTasteProfile
    ) async throws -> [RecommendationCandidate] {
        candidates
    }
}

private struct FallbackMessageRankingService: RecommendationRankingService {
    var availabilityMessage: String? { "Apple Intelligence is unavailable; using on-device matching." }

    func rank(
        profile: RecommendationTasteProfile,
        candidates: [EnrichedRecommendationCandidate]
    ) async throws -> [PlaceRecommendation] {
        try await HeuristicRecommendationRankingService().rank(profile: profile, candidates: candidates)
    }
}

private struct CommunityAverageCommunityService: CommunityService {
    let rows: [CommunityVisitRow]

    func currentMember() async throws -> CommunityMemberSnapshot? { nil }
    func join(displayName: String, profile: TasteProfile, existingVisits: [CommunityVisitDraft]) async throws {}
    func leave(deleteRatings: Bool) async throws {}
    func updateProfile(displayName: String, profile: TasteProfile) async throws {}
    func publish(_ visit: CommunityVisitDraft) async throws -> String { UUID().uuidString }
    func updatePublishedVisit(_ visit: CommunityVisitDraft) async throws {}
    func deletePublishedVisit(localVisitID: UUID) async throws {}
    func deleteVisit(recordName: String) async throws {}
    func reportVisit(_ report: CommunityReportDraft) async throws {}

    func fetchFeedPage(
        cursor: String?,
        limit: Int,
        authorIDsToInclude: Set<String>?,
        authorIDsToExclude: Set<String>
    ) async throws -> CommunityFeedPage {
        CommunityFeedPage(rows: [], nextCursor: nil)
    }

    func fetchVisits(matchingMapKitIdentifier identifier: String) async throws -> [CommunityVisitRow] {
        rows.filter { $0.placeMapKitIdentifier == identifier }
    }

    func fetchVisits(
        near coordinate: CLLocationCoordinate2D,
        radiusMeters: Double,
        nameContains: String
    ) async throws -> [CommunityVisitRow] {
        rows
    }

    func fetchMember(userRecordID: String) async throws -> CommunityMemberSnapshot? { nil }
    func fetchVisitDetail(recordName: String) async throws -> CommunityVisitDetail? { nil }
    func fetchLikedVisitsByCurrentUser() async throws -> [CommunityVisitRow] { [] }
    func like(visitRecordName: String) async throws {}
    func unlike(visitRecordName: String) async throws {}
    func isLikedByCurrentUser(_ recordName: String) async throws -> Bool { false }
}
