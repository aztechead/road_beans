import CoreLocation
import Foundation

enum RecommendationAvailability: Equatable, Sendable {
    case ready
    case optedOut
    case learning(LearningProgress)
    case locationUnavailable
    case unavailable(String)
}

struct LearningProgress: Equatable, Sendable {
    let totalVisits: Int
    let ratedVisits: Int
    let required: Int

    var fraction: Double {
        guard required > 0 else { return 1 }
        return min(1, Double(ratedVisits) / Double(required))
    }

    var remaining: Int { max(0, required - ratedVisits) }
    var isComplete: Bool { ratedVisits >= required }
}

enum RecommendationConfidence: String, Codable, Sendable {
    case high
    case medium
    case low

    var displayName: String {
        switch self {
        case .high: "High Match"
        case .medium: "Good Match"
        case .low: "Possible Match"
        }
    }
}

enum RecommendationPlaceSource: String, Codable, Sendable {
    case local
    case mapKit
    case external
}

struct WeightedKeyword: Codable, Hashable, Sendable {
    let value: String
    let weight: Double
}

struct RecommendationTasteProfile: Codable, Equatable, Sendable {
    static let minimumVisitCount = 3

    let preferredTags: [WeightedKeyword]
    let preferredDrinks: [WeightedKeyword]
    let dislikedTags: [WeightedKeyword]
    let dislikedDrinks: [WeightedKeyword]
    let preferredPlaceKinds: [PlaceKind]
    let summary: String

    var searchTerms: [String] {
        var terms = ["coffee", "cafe", "espresso", "truck stop", "gas station"]
        terms.append(contentsOf: preferredTags.prefix(4).map(\.value))
        terms.append(contentsOf: preferredDrinks.prefix(3).map(\.value))
        return Array(NSOrderedSet(array: terms)) as? [String] ?? terms
    }
}

struct RecommendationCandidate: Identifiable, Sendable {
    let id: String
    let source: RecommendationPlaceSource
    let placeID: UUID?
    let mapKitIdentifier: String?
    let name: String
    let kind: PlaceKind
    let address: String?
    let coordinate: CLLocationCoordinate2D?
    let distanceMeters: Double?
    let localAverageRating: Double?
    let localVisitCount: Int
    let websiteURL: URL?
    let phoneNumber: String?
}

struct EnrichedRecommendationCandidate: Identifiable, Sendable {
    let candidate: RecommendationCandidate
    let publicSignals: [String]
    let attributions: [RecommendationAttribution]

    var id: String { candidate.id }
}

struct RecommendationAttribution: Codable, Hashable, Sendable {
    let sourceName: String
    let detail: String
}

struct PlaceRecommendation: Identifiable, Sendable {
    let id: String
    let source: RecommendationPlaceSource
    let placeID: UUID?
    let mapKitIdentifier: String?
    let placeName: String
    let kind: PlaceKind
    let address: String?
    let coordinate: CLLocationCoordinate2D?
    let distanceMeters: Double?
    let score: Int
    let confidence: RecommendationConfidence
    let reasons: [String]
    let cautions: [String]
    let matchedSignals: [String]
    let attributions: [RecommendationAttribution]
}
