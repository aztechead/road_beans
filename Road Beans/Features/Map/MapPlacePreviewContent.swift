import Foundation

struct MapPlacePreviewContent: Equatable, Sendable {
    let title: String
    let eyebrow: String
    let ratingLabel: String
    let reviewCountLabel: String
    let contextLine: String
    let routeButtonTitle: String
    let reviewsButtonTitle: String
    let featuredReview: CommunityVisitRow?

    static func personal(_ place: PlaceSummary) -> MapPlacePreviewContent {
        MapPlacePreviewContent(
            title: place.name,
            eyebrow: place.kind.displayName,
            ratingLabel: ratingLabel(place.averageRating),
            reviewCountLabel: reviewCountLabel(place.visitCount),
            contextLine: place.visitCount == 1
                ? "Your review and notes at this stop."
                : "Your reviews and notes at this stop.",
            routeButtonTitle: "Route in Maps",
            reviewsButtonTitle: "View all Reviews",
            featuredReview: nil
        )
    }

    static func community(_ annotation: CommunityPlaceAnnotation) -> MapPlacePreviewContent {
        MapPlacePreviewContent(
            title: annotation.name,
            eyebrow: "Community \(annotation.kind.displayName)",
            ratingLabel: ratingLabel(annotation.averageRating),
            reviewCountLabel: reviewCountLabel(annotation.reviewCount),
            contextLine: "Community-tested stop with \(annotation.reviewCount) shared review\(annotation.reviewCount == 1 ? "" : "s").",
            routeButtonTitle: "Route in Maps",
            reviewsButtonTitle: "View all Reviews",
            featuredReview: annotation.reviews.sorted { $0.visitDate > $1.visitDate }.first
        )
    }

    private static func ratingLabel(_ rating: Double?) -> String {
        guard let rating else { return "No ratings yet" }
        return "\(String(format: "%.1f", rating)) beans"
    }

    private static func reviewCountLabel(_ count: Int) -> String {
        "\(count) review\(count == 1 ? "" : "s")"
    }
}
