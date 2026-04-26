import SwiftData
import Testing
@testable import Road_Beans

@Suite("PersistenceController")
@MainActor
struct PersistenceControllerTests {
    @Test func resolvesLocalOnlyWhenNoToken() {
        let icloud = FakeICloudAvailabilityService(initialToken: nil)
        let controller = PersistenceController(
            icloud: icloud,
            migrationDeferred: false,
            localStoreExists: false,
            useInMemoryStores: true
        )
        #expect(controller.mode == .localOnly)
    }

    @Test func resolvesCloudKitWhenTokenAndNoLocal() {
        let icloud = FakeICloudAvailabilityService(initialToken: "user1")
        let controller = PersistenceController(
            icloud: icloud,
            migrationDeferred: false,
            localStoreExists: false,
            useInMemoryStores: true
        )
        #expect(controller.mode == .cloudKitBacked)
    }

    @Test func forceLocalOnlyIgnoresICloudTokenAndLocalStore() {
        let icloud = FakeICloudAvailabilityService(initialToken: "user1")
        let controller = PersistenceController(
            icloud: icloud,
            migrationDeferred: false,
            localStoreExists: true,
            forceLocalOnly: true,
            useInMemoryStores: true
        )
        #expect(controller.mode == .localOnly)
    }

    @Test func resolvesPendingMigrationWhenTokenAndLocalExists() {
        let icloud = FakeICloudAvailabilityService(initialToken: "user1")
        let controller = PersistenceController(
            icloud: icloud,
            migrationDeferred: false,
            localStoreExists: true,
            useInMemoryStores: true
        )
        #expect(controller.mode == .pendingMigration)
    }

    @Test func deferredMigrationStaysLocalOnly() {
        let icloud = FakeICloudAvailabilityService(initialToken: "user1")
        let controller = PersistenceController(
            icloud: icloud,
            migrationDeferred: true,
            localStoreExists: true,
            useInMemoryStores: true
        )
        #expect(controller.mode == .localOnly)
    }

    @Test func identityChangeTriggersPendingRelaunch() async {
        let icloud = FakeICloudAvailabilityService(initialToken: "user1")
        let controller = PersistenceController(
            icloud: icloud,
            migrationDeferred: false,
            localStoreExists: false,
            useInMemoryStores: true
        )
        #expect(controller.mode == .cloudKitBacked)

        try? await Task.sleep(nanoseconds: 50_000_000)
        icloud.triggerIdentityChange()
        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(controller.mode == .pendingRelaunch)
    }

    @Test func migrateLocalToCloudKitCurrentlyThrowsExplicitError() async {
        let icloud = FakeICloudAvailabilityService(initialToken: "user1")
        let controller = PersistenceController(
            icloud: icloud,
            migrationDeferred: false,
            localStoreExists: true,
            useInMemoryStores: true
        )

        await #expect(throws: PersistenceMigrationError.notYetImplemented) {
            try await controller.migrateLocalToCloudKit()
        }
    }
}
