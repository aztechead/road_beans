import Foundation

struct VisitPhotoDTO: Codable, Hashable, Sendable {
    let id: UUID
    let remoteID: String?
    let visitID: UUID
    let caption: String?
    let widthPx: Int
    let heightPx: Int
    let assetReference: String
    let lastModifiedAt: Date
    let createdAt: Date
}
