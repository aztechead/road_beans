import Foundation
import SwiftData

@Model
final class Tombstone {
    var id: UUID = UUID()
    var entityKind: String = ""
    var entityID: UUID = UUID()
    var remoteID: String?
    var deletedAt: Date = Date.now
    var authorIdentifier: String?
    var syncState: SyncState = SyncState.pendingUpload

    init() {}

    init(entityKind: String, entityID: UUID, remoteID: String? = nil) {
        self.entityKind = entityKind
        self.entityID = entityID
        self.remoteID = remoteID
    }
}
