import Foundation
import SwiftData

@Model
final class Visit {
    var id: UUID = UUID()
    var date: Date = Date.now
    var createdAt: Date = Date.now
    var lastModifiedAt: Date = Date.now

    var remoteID: String?
    var syncState: SyncState = SyncState.pendingUpload
    var authorIdentifier: String?

    var _place: Place?

    @Relationship(deleteRule: .cascade, inverse: \Drink._visit)
    var _drinks: [Drink]? = []

    @Relationship(inverse: \Tag._visits)
    var _tags: [Tag]? = []

    @Relationship(deleteRule: .cascade, inverse: \VisitPhoto._visit)
    var _photos: [VisitPhoto]? = []

    init() {}
}

extension Visit {
    var place: Place? {
        _place
    }

    var drinks: [Drink] {
        _drinks ?? []
    }

    var tags: [Tag] {
        _tags ?? []
    }

    var photos: [VisitPhoto] {
        _photos ?? []
    }
}
