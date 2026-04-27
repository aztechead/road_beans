import Foundation

struct CommunityVisitRow: Identifiable, Sendable, Equatable, Codable {
    let id: String
    let authorUserRecordID: String
    let authorDisplayName: String
    let authorTasteProfile: TasteProfile?
    let placeName: String
    let placeKindRawValue: String
    let placeMapKitIdentifier: String?
    let placeLatitude: Double?
    let placeLongitude: Double?
    let visitDate: Date
    let beanRating: Double
    let drinkSummary: String
    let tagSummary: String
    let publishedAt: Date
    var likeCount: Int
    var commentCount: Int
}

struct CommunityFeedPage: Sendable, Equatable {
    let rows: [CommunityVisitRow]
    let nextCursor: String?
}
