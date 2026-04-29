import CoreLocation
import Foundation
import MapKit

protocol RecommendationProfileService: Sendable {
    func buildProfile(from visits: [RecentVisitRow]) async throws -> RecommendationTasteProfile?
}

protocol NearbyRecommendationCandidateService: Sendable {
    func candidates(
        near coordinate: CLLocationCoordinate2D,
        radiusMeters: Double,
        profile: RecommendationTasteProfile
    ) async throws -> [RecommendationCandidate]
}

protocol RecommendationEnrichmentService: Sendable {
    func enrich(_ candidates: [RecommendationCandidate]) async throws -> [EnrichedRecommendationCandidate]
}

protocol RecommendationRankingService: Sendable {
    var availabilityMessage: String? { get }

    func rank(
        profile: RecommendationTasteProfile,
        candidates: [EnrichedRecommendationCandidate]
    ) async throws -> [PlaceRecommendation]
}

struct LocalRecommendationProfileService: RecommendationProfileService {
    static let preferredAverageThreshold: Double = 3.5
    static let dislikedAverageThreshold: Double = 2.5
    static let minimumOccurrences: Int = 2

    func buildProfile(from visits: [RecentVisitRow]) async throws -> RecommendationTasteProfile? {
        let ratedVisits = visits.filter { $0.visit.averageRating != nil }
        guard ratedVisits.count >= RecommendationTasteProfile.minimumVisitCount else { return nil }

        let tagStats = aggregateStats(items: ratedVisits.flatMap { row in
            row.visit.tagNames.map { ($0, row.visit.averageRating ?? 3) }
        })
        let drinkStats = aggregateStats(items: ratedVisits.flatMap { row in
            row.drinkNames.map { ($0, row.visit.averageRating ?? 3) }
        })

        let preferredTags = preferredKeywords(from: tagStats)
        let preferredDrinks = preferredKeywords(from: drinkStats)
        let dislikedTags = dislikedKeywords(from: tagStats)
        let dislikedDrinks = dislikedKeywords(from: drinkStats)

        let kindAverages = Dictionary(grouping: ratedVisits, by: \.placeKind)
            .mapValues { rows -> Double in
                let ratings = rows.compactMap { $0.visit.averageRating }
                guard !ratings.isEmpty else { return 0 }
                return ratings.reduce(0, +) / Double(ratings.count)
            }
        let preferredKinds = kindAverages
            .filter { $0.value >= 3 }
            .sorted { $0.value > $1.value }
            .map(\.key)

        let summaryBits = [
            preferredTags.prefix(3).map(\.value).joined(separator: ", "),
            preferredDrinks.prefix(2).map(\.value).joined(separator: ", "),
            dislikedTags.isEmpty && dislikedDrinks.isEmpty
                ? ""
                : "avoids " + (dislikedTags.prefix(2).map(\.value) + dislikedDrinks.prefix(1).map(\.value)).joined(separator: ", ")
        ].filter { !$0.isEmpty }

        return RecommendationTasteProfile(
            preferredTags: preferredTags,
            preferredDrinks: preferredDrinks,
            dislikedTags: dislikedTags,
            dislikedDrinks: dislikedDrinks,
            preferredPlaceKinds: preferredKinds.isEmpty ? [.coffeeShop] : preferredKinds,
            summary: summaryBits.isEmpty ? "Nearby coffee and road stops based on your visit history." : summaryBits.joined(separator: " / ")
        )
    }

    private struct KeywordStats {
        let key: String
        let occurrences: Int
        let averageRating: Double
    }

    private func aggregateStats(items: [(String, Double)]) -> [KeywordStats] {
        var sums: [String: (count: Int, total: Double)] = [:]
        for (rawValue, rating) in items {
            let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else { continue }
            let entry = sums[value] ?? (0, 0)
            sums[value] = (entry.count + 1, entry.total + rating)
        }
        return sums.map { KeywordStats(key: $0.key, occurrences: $0.value.count, averageRating: $0.value.total / Double($0.value.count)) }
    }

    private func preferredKeywords(from stats: [KeywordStats]) -> [WeightedKeyword] {
        stats
            .filter { $0.averageRating >= Self.preferredAverageThreshold && $0.occurrences >= Self.minimumOccurrences }
            .sorted { combinedScore($0) > combinedScore($1) }
            .prefix(8)
            .map { WeightedKeyword(value: $0.key, weight: $0.averageRating) }
    }

    private func dislikedKeywords(from stats: [KeywordStats]) -> [WeightedKeyword] {
        stats
            .filter { $0.averageRating <= Self.dislikedAverageThreshold && $0.occurrences >= Self.minimumOccurrences }
            .sorted { combinedScore($0) < combinedScore($1) }
            .prefix(8)
            .map { WeightedKeyword(value: $0.key, weight: $0.averageRating) }
    }

    private func combinedScore(_ stats: KeywordStats) -> Double {
        stats.averageRating * log(Double(stats.occurrences) + 1)
    }
}

final class AppleNativeRecommendationCandidateService: NearbyRecommendationCandidateService, @unchecked Sendable {
    private let placeRepository: any PlaceRepository

    init(placeRepository: any PlaceRepository) {
        self.placeRepository = placeRepository
    }

    func candidates(
        near coordinate: CLLocationCoordinate2D,
        radiusMeters: Double,
        profile: RecommendationTasteProfile
    ) async throws -> [RecommendationCandidate] {
        async let local = localCandidates(near: coordinate, radiusMeters: radiusMeters)
        async let discovered = mapKitCandidates(near: coordinate, radiusMeters: radiusMeters)
        let allowedKinds = Set(profile.preferredPlaceKinds.isEmpty ? [.coffeeShop] : profile.preferredPlaceKinds)
        let merged = deduplicated(try await local + discovered)
            .filter { allowedKinds.contains($0.kind) }
        let highlyRated = merged.filter(RecommendationRanking.isHighlyRatedLocal)
        let rest = merged
            .filter { !RecommendationRanking.isHighlyRatedLocal($0) }
            .sorted { ($0.distanceMeters ?? .greatestFiniteMagnitude) < ($1.distanceMeters ?? .greatestFiniteMagnitude) }
        let pinned = highlyRated.sorted { ($0.distanceMeters ?? .greatestFiniteMagnitude) < ($1.distanceMeters ?? .greatestFiniteMagnitude) }
        return Array((pinned + rest).prefix(18))
    }

    private func localCandidates(
        near coordinate: CLLocationCoordinate2D,
        radiusMeters: Double
    ) async throws -> [RecommendationCandidate] {
        try await placeRepository.summariesNear(coordinate: coordinate, radiusMeters: radiusMeters)
            .filter { $0.kind.isRecommendationEligible }
            .map { place in
                RecommendationCandidate(
                    id: "local:\(place.id.uuidString)",
                    source: .local,
                    placeID: place.id,
                    mapKitIdentifier: nil,
                    name: place.name,
                    kind: place.kind,
                    address: place.address,
                    coordinate: place.coordinate,
                    distanceMeters: place.coordinate.map { $0.distance(to: coordinate) },
                    localAverageRating: place.averageRating,
                    localVisitCount: place.visitCount,
                    websiteURL: nil,
                    phoneNumber: nil
                )
            }
    }

    private func mapKitCandidates(
        near coordinate: CLLocationCoordinate2D,
        radiusMeters: Double
    ) async throws -> [RecommendationCandidate] {
        let request = MKLocalPointsOfInterestRequest(center: coordinate, radius: radiusMeters)
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.cafe, .bakery, .restaurant, .foodMarket, .gasStation, .evCharger])

        let response = try await MKLocalSearch(request: request).start()
        return response.mapItems.compactMap { item in
            let draft = SystemLocationSearchService.draft(from: item)
            guard draft.kind.isRecommendationEligible else { return nil }
            let itemCoordinate = item.location.coordinate
            let distance = itemCoordinate.distance(to: coordinate)
            guard distance <= radiusMeters else { return nil }

            return RecommendationCandidate(
                id: "mapkit:\(draft.mapKitIdentifier ?? "\(draft.name)-\(itemCoordinate.latitude)-\(itemCoordinate.longitude)")",
                source: .mapKit,
                placeID: nil,
                mapKitIdentifier: draft.mapKitIdentifier,
                name: draft.name,
                kind: draft.kind,
                address: draft.address,
                coordinate: itemCoordinate,
                distanceMeters: distance,
                localAverageRating: nil,
                localVisitCount: 0,
                websiteURL: draft.websiteURL,
                phoneNumber: draft.phoneNumber
            )
        }
    }

    private func deduplicated(_ candidates: [RecommendationCandidate]) -> [RecommendationCandidate] {
        var seen: Set<String> = []
        var unique: [RecommendationCandidate] = []

        for candidate in candidates {
            let key = [
                candidate.name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current),
                candidate.address?.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            ]
                .compactMap { $0 }
                .joined(separator: "|")
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            unique.append(candidate)
        }

        return unique
    }
}

struct PassthroughRecommendationEnrichmentService: RecommendationEnrichmentService {
    func enrich(_ candidates: [RecommendationCandidate]) async throws -> [EnrichedRecommendationCandidate] {
        candidates.map { candidate in
            EnrichedRecommendationCandidate(
                candidate: candidate,
                publicSignals: publicSignals(for: candidate),
                attributions: [RecommendationAttribution(sourceName: sourceName(for: candidate.source), detail: "Nearby place data")]
            )
        }
    }

    private func publicSignals(for candidate: RecommendationCandidate) -> [String] {
        var signals = [candidate.kind.displayName]
        if let rating = candidate.localAverageRating, candidate.localVisitCount > 0 {
            signals.append("\(String(format: "%.1f", rating))-bean local average")
            signals.append("\(candidate.localVisitCount) saved visit\(candidate.localVisitCount == 1 ? "" : "s")")
        }
        if candidate.websiteURL != nil { signals.append("Has website") }
        if candidate.phoneNumber != nil { signals.append("Has phone") }
        return signals
    }

    private func sourceName(for source: RecommendationPlaceSource) -> String {
        switch source {
        case .local: "Road Beans"
        case .mapKit: "Apple Maps"
        case .external: "External provider"
        }
    }
}

private extension PlaceKind {
    var isRecommendationEligible: Bool {
        switch self {
        case .coffeeShop, .truckStop, .gasStation, .fastFood:
            true
        case .other:
            false
        }
    }
}
