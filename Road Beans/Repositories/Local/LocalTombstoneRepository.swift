import Foundation
import SwiftData

@MainActor
final class LocalTombstoneRepository: TombstoneRepository {
    private let context: ModelContext
    private let sync: any RemoteSyncCoordinator

    init(context: ModelContext, sync: any RemoteSyncCoordinator) {
        self.context = context
        self.sync = sync
    }

    func insertTombstone(entityKind: SyncEntityKind, entityID: UUID, remoteID: String?) async throws {
        let tombstone = Tombstone(entityKind: entityKind.rawValue, entityID: entityID, remoteID: remoteID)
        context.insert(tombstone)
        try context.save()
        await sync.markDirty(.tombstone, id: tombstone.id)
    }

    func all() async throws -> [TombstoneDTO] {
        let descriptor = FetchDescriptor<Tombstone>(sortBy: [SortDescriptor(\.deletedAt)])
        return try context.fetch(descriptor).map {
            TombstoneDTO(
                id: $0.id,
                entityKind: $0.entityKind,
                entityID: $0.entityID,
                remoteID: $0.remoteID,
                deletedAt: $0.deletedAt
            )
        }
    }
}
