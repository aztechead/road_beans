import Foundation

enum SyncEntityKind: String, Sendable {
    case place
    case visit
    case drink
    case tag
    case visitPhoto
    case tombstone
}

protocol RemoteSyncCoordinator: Sendable {
    func markDirty(_ kind: SyncEntityKind, id: UUID) async
}

actor LocalOnlyRemoteSync: RemoteSyncCoordinator {
    struct Call: Sendable, Equatable {
        let kind: SyncEntityKind
        let id: UUID
    }

    private(set) var recordedCalls: [Call] = []

    func markDirty(_ kind: SyncEntityKind, id: UUID) async {
        recordedCalls.append(Call(kind: kind, id: id))
    }
}
