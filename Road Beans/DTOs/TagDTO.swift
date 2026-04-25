import Foundation

struct TagDTO: Codable, Hashable, Sendable {
    let id: UUID
    let remoteID: String?
    let name: String
    let lastModifiedAt: Date
    let createdAt: Date
}
