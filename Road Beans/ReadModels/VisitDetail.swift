import Foundation

struct VisitDetail: Identifiable, Hashable, Sendable {
    let id: UUID
    let date: Date
    let placeID: UUID
    let placeName: String
    let placeKind: PlaceKind
    let drinks: [DrinkRow]
    let tagNames: [String]
    let photos: [PhotoReference]
}
