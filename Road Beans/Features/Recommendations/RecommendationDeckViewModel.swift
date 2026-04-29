import CoreLocation
import Foundation
import Observation

@Observable
@MainActor
final class RecommendationDeckViewModel {
    static let optInStorageKey = "recommendationsEnabled"
    static let dismissedStorageKey = "recommendationsDismissedIDs"
    static let radiusMeters: Double = 8_047

    var isOptedIn: Bool {
        didSet {
            defaults.set(isOptedIn, forKey: Self.optInStorageKey)
        }
    }
    var availability: RecommendationAvailability = .optedOut
    var recommendations: [PlaceRecommendation] = []
    var isLoading = false
    var isEnabling = false
    var rankingStatusMessage: String?
    var optInProgress = LearningProgress(
        totalVisits: 0,
        ratedVisits: 0,
        required: RecommendationTasteProfile.minimumVisitCount
    )

    private let visits: any VisitRepository
    private let placeRepository: any PlaceRepository
    private let locationPermission: any LocationPermissionService
    private let currentLocation: any CurrentLocationProvider
    private let profileService: any RecommendationProfileService
    private let candidateService: any NearbyRecommendationCandidateService
    private let enrichmentService: any RecommendationEnrichmentService
    private let rankingService: any RecommendationRankingService
    private let defaults: UserDefaults
    private var activeReloadID: UUID?
    private var cache: RecommendationCache?

    init(
        visits: any VisitRepository,
        placeRepository: any PlaceRepository,
        locationPermission: any LocationPermissionService,
        currentLocation: any CurrentLocationProvider,
        profileService: any RecommendationProfileService,
        candidateService: any NearbyRecommendationCandidateService,
        enrichmentService: any RecommendationEnrichmentService,
        rankingService: any RecommendationRankingService,
        defaults: UserDefaults = .standard
    ) {
        self.visits = visits
        self.placeRepository = placeRepository
        self.locationPermission = locationPermission
        self.currentLocation = currentLocation
        self.profileService = profileService
        self.candidateService = candidateService
        self.enrichmentService = enrichmentService
        self.rankingService = rankingService
        self.defaults = defaults
        self.isOptedIn = defaults.bool(forKey: Self.optInStorageKey)
        self.availability = isOptedIn ? .ready : .optedOut
        self.rankingStatusMessage = rankingService.availabilityMessage
    }

    func enable() async {
        guard !isEnabling else { return }
        isEnabling = true
        defer { isEnabling = false }

        await updateOptInProgress()
        guard optInProgress.isComplete else {
            recommendations = []
            availability = .learning(optInProgress)
            return
        }
        isOptedIn = true
        await locationPermission.requestWhenInUse()
        await reload()
    }

    func reload() async {
        guard isOptedIn else {
            recommendations = []
            await updateOptInProgress()
            availability = .optedOut
            return
        }

        let reloadID = UUID()
        activeReloadID = reloadID
        isLoading = true
        defer {
            if activeReloadID == reloadID {
                isLoading = false
            }
        }

        do {
            let permission = await locationPermission.status
            guard activeReloadID == reloadID else { return }
            guard permission == .authorized else {
                recommendations = []
                availability = .locationUnavailable
                return
            }

            let rows = try await visits.recentRows(limit: 200)
            guard activeReloadID == reloadID else { return }
            let progress = progress(from: rows)
            let visitSignature = signature(for: rows)
            optInProgress = progress
            guard progress.isComplete else {
                isOptedIn = false
                recommendations = []
                availability = .learning(progress)
                return
            }
            guard let profile = try await profileService.buildProfile(from: rows) else {
                recommendations = []
                availability = .learning(progress)
                return
            }

            let coordinate = try await currentLocation.currentCoordinate()
            let dismissedIDs = Set(defaults.stringArray(forKey: Self.dismissedStorageKey) ?? [])
            if let cache, cache.visitSignature == visitSignature, cache.isFresh(near: coordinate) {
                guard activeReloadID == reloadID else { return }
                recommendations = cache.recommendations.filter { !dismissedIDs.contains($0.id) }
                rankingStatusMessage = cache.rankingStatusMessage
                availability = recommendations.isEmpty ? .unavailable("No nearby coffee or road stops matched your taste profile.") : .ready
                return
            }
            let candidates = try await candidateService.candidates(
                near: coordinate,
                radiusMeters: Self.radiusMeters,
                profile: profile
            )
            let enriched = try await enrichmentService.enrich(candidates)
            let unfilteredRanked = try await rankingService.rank(profile: profile, candidates: enriched)
            let ranked = unfilteredRanked.filter { !dismissedIDs.contains($0.id) }
            guard activeReloadID == reloadID else { return }
            cache = RecommendationCache(
                coordinate: coordinate,
                visitSignature: visitSignature,
                createdAt: Date(),
                recommendations: unfilteredRanked,
                rankingStatusMessage: rankingService.availabilityMessage
            )
            recommendations = ranked
            rankingStatusMessage = rankingService.availabilityMessage
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
        var dismissed = Set(defaults.stringArray(forKey: Self.dismissedStorageKey) ?? [])
        dismissed.insert(recommendation.id)
        defaults.set(Array(dismissed).sorted(), forKey: Self.dismissedStorageKey)
    }

    func reset() async {
        isOptedIn = false
        recommendations = []
        availability = .optedOut
        defaults.removeObject(forKey: Self.dismissedStorageKey)
        cache = nil
    }

    func saveRecommendationAsPlace(_ recommendation: PlaceRecommendation) async throws -> UUID {
        if let placeID = recommendation.placeID {
            return placeID
        }
        guard recommendation.source == .mapKit || recommendation.source == .external else {
            throw RecommendationActionError.unsaveableRecommendation
        }
        let draft = MapKitPlaceDraft(
            name: recommendation.placeName,
            kind: recommendation.kind,
            mapKitIdentifier: recommendation.mapKitIdentifier,
            mapKitName: recommendation.placeName,
            address: recommendation.address,
            latitude: recommendation.coordinate?.latitude,
            longitude: recommendation.coordinate?.longitude,
            phoneNumber: nil,
            websiteURL: nil,
            streetNumber: nil,
            streetName: nil,
            city: nil,
            region: nil,
            postalCode: nil,
            country: nil
        )
        return try await placeRepository.findOrCreate(reference: .newMapKit(draft))
    }

    func handlePermissionChange(_ status: LocationAuthorization) async {
        guard isOptedIn else { return }
        if status == .authorized || availability == .locationUnavailable {
            await reload()
        }
    }

    private func updateOptInProgress() async {
        let rows = (try? await visits.recentRows(limit: 200)) ?? []
        optInProgress = progress(from: rows)
    }

    private func progress(from rows: [RecentVisitRow]) -> LearningProgress {
        LearningProgress(
            totalVisits: rows.count,
            ratedVisits: rows
                .filter { $0.visit.averageRating != nil }
                .reduce(0) { $0 + $1.visit.drinkCount },
            required: RecommendationTasteProfile.minimumVisitCount
        )
    }

    private func signature(for rows: [RecentVisitRow]) -> String {
        rows.map { row in
            [
                row.visit.id.uuidString,
                "\(row.visit.drinkCount)",
                row.visit.averageRating.map { String(format: "%.2f", $0) } ?? "nil",
                row.visit.tagNames.joined(separator: ","),
                row.drinkNames.joined(separator: ",")
            ].joined(separator: ":")
        }
        .joined(separator: "|")
    }
}

enum RecommendationActionError: Error {
    case unsaveableRecommendation
}

private struct RecommendationCache {
    static let maximumAge: TimeInterval = 10 * 60
    static let maximumDistanceMeters: CLLocationDistance = 250

    let coordinate: CLLocationCoordinate2D
    let visitSignature: String
    let createdAt: Date
    let recommendations: [PlaceRecommendation]
    let rankingStatusMessage: String?

    func isFresh(near other: CLLocationCoordinate2D, now: Date = Date()) -> Bool {
        now.timeIntervalSince(createdAt) <= Self.maximumAge
            && coordinate.distance(to: other) <= Self.maximumDistanceMeters
    }
}
