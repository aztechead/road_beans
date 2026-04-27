import Foundation

enum PersistenceMode: Equatable, Sendable {
    case cloudKitBacked
    case iCloudUnavailable
    case pendingRelaunch
}
