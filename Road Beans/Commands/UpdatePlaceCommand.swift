import Foundation

struct UpdatePlaceCommand: Sendable, Equatable {
    let id: UUID
    var name: String
    var kind: PlaceKind
    var address: String?
}
