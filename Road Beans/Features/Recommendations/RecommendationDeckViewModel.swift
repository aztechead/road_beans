import CoreLocation
import Foundation
import Observation

@Observable
@MainActor
final class RecommendationDeckViewModel {
    static let optInStorageKey = "recommendationsEnabled"
    static let radiusMeters: Double = 8_047

    var isOptedIn: Bool {
        didSet {
            UserDefaults.standard.set(isOptedIn, forKey: Self.optInStorageKey)
        }
    }
    var availability: RecommendationAvailability = .optedOut
    var recommendations: [PlaceRecommendation] = []
    var isLoading = false

    private let visits: any VisitRepository
    private let locationPermission: any LocationPermissionService
    private let currentLocation: any CurrentLocationProvider
    private let profileService: any RecommendationProfileService
    private let candidateService: any NearbyRecommendationCandidateService
    private let enrichmentService: any RecommendationEnrichmentService
    private let rankingService: any RecommendationRankingService

    init(
        visits: any VisitRepository,
        locationPermission: any LocationPermissionService,
        currentLocation: any CurrentLocationProvider,
        profileService: any RecommendationProfileService,
        candidateService: any NearbyRecommendationCandidateService,
        enrichmentService: any RecommendationEnrichmentService,
        rankingService: any RecommendationRankingService,
        defaults: UserDefaults = .standard
    ) {
        self.visits = visits
        self.locationPermission = locationPermission
        self.currentLocation = currentLocation
        self.profileService = profileService
        self.candidateService = candidateService
        self.enrichmentService = enrichmentService
        self.rankingService = rankingService
        self.isOptedIn = defaults.bool(forKey: Self.optInStorageKey)
        self.availability = isOptedIn ? .ready : .optedOut
    }

    func enable() async {
        isOptedIn = true
        await locationPermission.requestWhenInUse()
        await reload()
    }

    func reload() async {
        guard isOptedIn else {
            recommendations = []
            availability = .optedOut
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let permission = await locationPermission.status
            guard permission == .authorized else {
                recommendations = []
                availability = .locationUnavailable
                return
            }

            let rows = try await visits.recentRows(limit: 200)
            let ratedCount = rows.filter { $0.visit.averageRating != nil }.count
            let progress = LearningProgress(
                totalVisits: rows.count,
                ratedVisits: ratedCount,
                required: RecommendationTasteProfile.minimumVisitCount
            )
            guard let profile = try await profileService.buildProfile(from: rows) else {
                recommendations = []
                availability = .learning(progress)
                return
            }

            let coordinate = try await currentLocation.currentCoordinate()
            let candidates = try await candidateService.candidates(
                near: coordinate,
                radiusMeters: Self.radiusMeters,
                profile: profile
            )
            let enriched = try await enrichmentService.enrich(candidates)
            recommendations = try await rankingService.rank(profile: profile, candidates: enriched)
            availability = recommendations.isEmpty ? .unavailable("No nearby coffee or road stops matched your taste profile.") : .ready
        } catch is CurrentLocationError {
            recommendations = []
            availability = .locationUnavailable
        } catch {
            recommendations = []
            availability = .unavailable("Road Beans could not build nearby picks right now.")
        }
    }

    func dismiss(_ recommendation: PlaceRecommendation) {
        recommendations.removeAll { $0.id == recommendation.id }
    }

    func reset() async {
        isOptedIn = false
        recommendations = []
        availability = .optedOut
    }
}
