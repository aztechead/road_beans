import Foundation

enum SyncState: String, Codable, CaseIterable, Sendable {
    case pendingUpload
    case synced
    case failed
}
