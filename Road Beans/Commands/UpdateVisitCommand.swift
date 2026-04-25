import Foundation

struct UpdateVisitCommand: Sendable {
    let id: UUID
    var date: Date?
    var tags: [String]?
    var drinks: [DrinkDraft]?
    var photoAdditions: [PhotoDraft]?
    var photoRemovals: [UUID]?
}
