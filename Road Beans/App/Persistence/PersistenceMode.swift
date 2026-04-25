import Foundation

enum PersistenceMode: Equatable, Sendable {
    case localOnly
    case cloudKitBacked
    case pendingMigration
    case pendingRelaunch
}
