import Foundation

struct VisitDTO: Codable, Hashable, Sendable {
    let id: UUID
    let remoteID: String?
    let placeID: UUID
    let date: Date
    let lastModifiedAt: Date
    let createdAt: Date
}
