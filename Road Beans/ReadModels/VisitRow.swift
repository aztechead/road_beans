import Foundation

struct VisitRow: Identifiable, Hashable, Sendable {
    let id: UUID
    let date: Date
    let drinkCount: Int
    let tagNames: [String]
    let photoCount: Int
    let averageRating: Double?
}
