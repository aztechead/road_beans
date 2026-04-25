import Foundation
import SwiftData

@MainActor
final class LocalPhotoRepository: PhotoRepository {
    private let context: ModelContext
    private let sync: any RemoteSyncCoordinator

    init(context: ModelContext, sync: any RemoteSyncCoordinator) {
        self.context = context
        self.sync = sync
    }

    func insertProcessed(_ processed: ProcessedPhoto, caption: String?, into visitID: UUID) async throws -> UUID {
        let predicate = #Predicate<Visit> { $0.id == visitID }
        var descriptor = FetchDescriptor<Visit>(predicate: predicate)
        descriptor.fetchLimit = 1
        guard let visit = try context.fetch(descriptor).first else {
            throw PhotoRepositoryError.visitNotFound
        }

        let photo = VisitPhoto()
        photo.imageData = processed.imageData
        photo.thumbnailData = processed.thumbnailData
        photo.widthPx = processed.widthPx
        photo.heightPx = processed.heightPx
        photo.caption = caption
        photo._visit = visit
        context.insert(photo)
        try context.save()
        await sync.markDirty(.visitPhoto, id: photo.id)
        return photo.id
    }

    func remove(_ photoID: UUID) async throws {
        let predicate = #Predicate<VisitPhoto> { $0.id == photoID }
        var descriptor = FetchDescriptor<VisitPhoto>(predicate: predicate)
        descriptor.fetchLimit = 1
        guard let photo = try context.fetch(descriptor).first else { return }

        let entityID = photo.id
        let remoteID = photo.remoteID
        context.delete(photo)

        let tombstone = Tombstone(entityKind: SyncEntityKind.visitPhoto.rawValue, entityID: entityID, remoteID: remoteID)
        context.insert(tombstone)
        try context.save()
        await sync.markDirty(.tombstone, id: tombstone.id)
    }
}
