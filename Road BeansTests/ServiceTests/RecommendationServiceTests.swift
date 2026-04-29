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

    @Test func deckViewModelStaysOptedOutUntilEnabled() async throws {
        let defaults = UserDefaults(suiteName: "RecommendationServiceTests-\(UUID().uuidString)")!
        let visits = FakeVisitRepository()
        visits.recents = [
            row(tags: ["quiet"], rating: 5),
            row(tags: ["espresso"], rating: 4),
            row(tags: ["local"], rating: 4)
        ]
        let candidates = FakeNearbyRecommendationCandidateService(candidates: [
            candidate(name: "Quiet Espresso Bar", distanceMeters: 500)
        ])
        let model = RecommendationDeckViewModel(
            visits: visits,
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
