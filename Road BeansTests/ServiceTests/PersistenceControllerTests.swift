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

        await expect(controller, eventually: .cloudKitBacked)
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

        await expect(controller, eventually: .pendingRelaunch)
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

        await expect(controller, eventually: .iCloudUnavailable)
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

        await expect(controller, eventually: .cloudKitBacked)
    }

    private func expect(
        _ controller: PersistenceController,
        eventually expectedMode: PersistenceMode,
        timeoutNanoseconds: UInt64 = 1_000_000_000
    ) async {
        let deadline = ContinuousClock.now + .nanoseconds(Int64(timeoutNanoseconds))
        while ContinuousClock.now < deadline {
            if controller.mode == expectedMode {
                break
            }
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        #expect(controller.mode == expectedMode)
    }
}
