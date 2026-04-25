import Foundation

struct CreateVisitCommand: Sendable {
    let placeRef: PlaceReference
    let date: Date
    let drinks: [DrinkDraft]
    let tags: [String]
    let photos: [PhotoDraft]
}
