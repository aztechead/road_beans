import Foundation

struct DrinkRow: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let category: DrinkCategory
    let rating: Double
    let tagNames: [String]
}
