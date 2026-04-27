import Testing
@testable import Road_Beans

@Suite("PersistenceController")
@MainActor
struct PersistenceControllerTests {
    @Test func resolvesICloudUnavailableWhenNoToken() {
        let icloud = FakeICloudAvailabilityService(initialToken: nil)
        let controller = PersistenceController(
            icloud: icloud,
            useInMemoryStores: true
        )

        #expect(controller.mode == .iCloudUnavailable)
    }

    @Test func resolvesCloudKitBackedWhenTokenExists() {
        let icloud = FakeICloudAvailabilityService(initialToken: "user1")
        let controller = PersistenceController(
            icloud: icloud,
            useInMemoryStores: true
        )

        #expect(controller.mode == .cloudKitBacked)
    }

    @Test func sameIdentityChangeDoesNotTriggerPendingRelaunch() async {
        let icloud = FakeICloudAvailabilityService(initialToken: "user1")
        let controller = PersistenceController(
            icloud: icloud,
            useInMemoryStores: true
        )
        #expect(controller.mode == .cloudKitBacked)

        try? await Task.sleep(nanoseconds: 50_000_000)
        icloud.triggerIdentityChange()
        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(controller.mode == .cloudKitBacked)
    }

    @Test func changedCloudKitIdentityTriggersPendingRelaunch() async {
        let icloud = FakeICloudAvailabilityService(initialToken: "user1")
        let controller = PersistenceController(
            icloud: icloud,
            useInMemoryStores: true
        )
        #expect(controller.mode == .cloudKitBacked)

        try? await Task.sleep(nanoseconds: 50_000_000)
        icloud.token = "user2"
        icloud.triggerIdentityChange()
        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(controller.mode == .pendingRelaunch)
    }

    @Test func signingOutSwitchesToICloudUnavailable() async {
        let icloud = FakeICloudAvailabilityService(initialToken: "user1")
        let controller = PersistenceController(
            icloud: icloud,
            useInMemoryStores: true
        )
        #expect(controller.mode == .cloudKitBacked)

        try? await Task.sleep(nanoseconds: 50_000_000)
        icloud.token = nil
        icloud.triggerIdentityChange()
        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(controller.mode == .iCloudUnavailable)
    }

    @Test func signingInFromUnavailableSwitchesToCloudKitBacked() async {
        let icloud = FakeICloudAvailabilityService(initialToken: nil)
        let controller = PersistenceController(
            icloud: icloud,
            useInMemoryStores: true
        )
        #expect(controller.mode == .iCloudUnavailable)

        try? await Task.sleep(nanoseconds: 50_000_000)
        icloud.token = "user1"
        icloud.triggerIdentityChange()
        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(controller.mode == .cloudKitBacked)
    }
}
