import Foundation

struct UploadEnvelope: Codable, Hashable, Sendable {
    let schemaVersion: Int
    let exportedAt: Date
    let authorIdentifier: String?
    let places: [PlaceDTO]
    let visits: [VisitDTO]
    let drinks: [DrinkDTO]
    let tags: [TagDTO]
    let visitPhotos: [VisitPhotoDTO]
    let visitTagAssignments: [TagAssignmentDTO]
    let drinkTagAssignments: [TagAssignmentDTO]
    let tombstones: [TombstoneDTO]
}
