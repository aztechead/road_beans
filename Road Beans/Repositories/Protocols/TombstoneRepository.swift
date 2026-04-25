import Foundation

protocol TombstoneRepository: Sendable {
    func insertTombstone(entityKind: SyncEntityKind, entityID: UUID, remoteID: String?) async throws
    func all() async throws -> [TombstoneDTO]
}
