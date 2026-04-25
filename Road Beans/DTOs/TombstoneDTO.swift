import Foundation

struct TombstoneDTO: Codable, Hashable, Sendable {
    let id: UUID
    let entityKind: String
    let entityID: UUID
    let remoteID: String?
    let deletedAt: Date
}
