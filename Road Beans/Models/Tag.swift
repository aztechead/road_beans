import Foundation
import SwiftData

@Model
final class Tag {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date.now
    var lastModifiedAt: Date = Date.now

    var remoteID: String?
    var syncState: SyncState = SyncState.pendingUpload
    var authorIdentifier: String?

    @Relationship
    var _visits: [Visit]? = []

    @Relationship
    var _drinks: [Drink]? = []

    init() {}
}

extension Tag {
    var visits: [Visit] {
        _visits ?? []
    }

    var drinks: [Drink] {
        _drinks ?? []
    }

    var usageCount: Int {
        (_visits?.count ?? 0) + (_drinks?.count ?? 0)
    }
}
