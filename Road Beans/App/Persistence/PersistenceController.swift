import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class PersistenceController {
    private(set) var mode: PersistenceMode
    let container: ModelContainer

    private let defaults: UserDefaults
    private var cloudKitIdentityToken: AnyHashable?
    private static let migrationDeferredKey = "RoadBeans.migrationDeferred"

    init(
        icloud: iCloudAvailabilityServiceProtocol,
        migrationDeferred: Bool? = nil,
        localStoreExists: Bool? = nil,
        forceLocalOnly: Bool = false,
        useInMemoryStores: Bool = false,
        defaults: UserDefaults = .standard
    ) {
        self.defaults = defaults

        let deferredFlag = migrationDeferred ?? defaults.bool(forKey: Self.migrationDeferredKey)
        let hasLocalStore = localStoreExists ?? Self.localStoreExistsOnDisk()
        let initialICloudToken = icloud.currentToken()
        let hasICloudToken = initialICloudToken != nil
        cloudKitIdentityToken = initialICloudToken

        let resolvedMode: PersistenceMode
        if forceLocalOnly {
            resolvedMode = .localOnly
        } else if !hasICloudToken {
            resolvedMode = .localOnly
        } else if hasLocalStore && !deferredFlag {
            resolvedMode = .pendingMigration
        } else if hasLocalStore && deferredFlag {
            resolvedMode = .localOnly
        } else {
            resolvedMode = .cloudKitBacked
        }
        mode = resolvedMode

        do {
            container = try Self.makeContainer(mode: resolvedMode, inMemory: useInMemoryStores)
        } catch {
            fatalError("ModelContainer init failed: \(error)")
        }

        Task { [weak self] in
            for await _ in icloud.identityChanges {
                let latestToken = icloud.currentToken()
                await MainActor.run {
                    guard let self, self.mode == .cloudKitBacked else { return }
                    guard latestToken != self.cloudKitIdentityToken else { return }
                    self.cloudKitIdentityToken = latestToken
                    self.mode = .pendingRelaunch
                }
            }
        }
    }

    func deferMigration() {
        defaults.set(true, forKey: Self.migrationDeferredKey)
        mode = .localOnly
    }

    func migrateLocalToCloudKit() async throws {
        throw PersistenceMigrationError.notYetImplemented
    }

    private static func makeContainer(mode: PersistenceMode, inMemory: Bool) throws -> ModelContainer {
        if inMemory {
            return try ModelContainer(
                for: AppSchema.all,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        }

        let configuration: ModelConfiguration
        switch mode {
        case .cloudKitBacked:
            configuration = ModelConfiguration(
                "CloudKitStore",
                schema: AppSchema.all,
                cloudKitDatabase: .private("iCloud.brainmeld.Road-Beans")
            )
        case .localOnly, .pendingMigration, .pendingRelaunch:
            configuration = ModelConfiguration(
                "LocalStore",
                schema: AppSchema.all,
                cloudKitDatabase: .none
            )
        }

        return try ModelContainer(for: AppSchema.all, configurations: [configuration])
    }

    private static func localStoreExistsOnDisk() -> Bool {
        let url = URL.applicationSupportDirectory.appendingPathComponent("LocalStore.sqlite")
        return FileManager.default.fileExists(atPath: url.path)
    }
}

enum PersistenceMigrationError: Error, Equatable {
    case notYetImplemented
    case copyFailed
}
