import Foundation

struct TagAssignmentDTO: Codable, Hashable, Sendable {
    let tagID: UUID
    let entityID: UUID
}
