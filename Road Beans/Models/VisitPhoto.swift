import Foundation
import SwiftData

@Model
final class VisitPhoto {
    var id: UUID = UUID()

    @Attribute(.externalStorage)
    var imageData: Data = Data()

    @Attribute(.externalStorage)
    var thumbnailData: Data = Data()

    var caption: String?
    var widthPx: Int = 0
    var heightPx: Int = 0
    var createdAt: Date = Date.now
    var lastModifiedAt: Date = Date.now

    var remoteID: String?
    var syncState: SyncState = SyncState.pendingUpload
    var authorIdentifier: String?

    var _visit: Visit?

    init() {}
}

extension VisitPhoto {
    var visit: Visit? {
        _visit
    }
}
