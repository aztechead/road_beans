import Foundation

struct DrinkDTO: Codable, Hashable, Sendable {
    let id: UUID
    let remoteID: String?
    let visitID: UUID
    let name: String
    let category: String
    let rating: Double
    let lastModifiedAt: Date
    let createdAt: Date
}
