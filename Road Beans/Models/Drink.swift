import Foundation
import SwiftData

@Model
final class Drink {
    var id: UUID = UUID()
    var name: String = ""
    var category: DrinkCategory = DrinkCategory.other
    var rating: Double = 3.0
    var createdAt: Date = Date.now
    var lastModifiedAt: Date = Date.now

    var remoteID: String?
    var syncState: SyncState = SyncState.pendingUpload
    var authorIdentifier: String?

    var _visit: Visit?

    @Relationship(inverse: \Tag._drinks)
    var _tags: [Tag]? = []

    init() {}
}

extension Drink {
    var visit: Visit? {
        _visit
    }

    var tags: [Tag] {
        _tags ?? []
    }
}
