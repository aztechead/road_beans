import Foundation
import Testing
@testable import Road_Beans

@Suite("iCloudAvailabilityService")
struct iCloudAvailabilityServiceTests {
    @Test func fakeReportsTokenWhenSet() {
        let service = FakeICloudAvailabilityService()
        #expect(service.currentToken() == nil)
        service.token = "abc" as AnyHashable
        #expect(service.currentToken() == ("abc" as AnyHashable))
    }

    @Test func fakeNotifiesSubscriberOnIdentityChange() async {
        let service = FakeICloudAvailabilityService()
        let stream = service.identityChanges
        let task = Task { () -> Bool in
            for await _ in stream {
                return true
            }
            return false
        }

        try? await Task.sleep(nanoseconds: 50_000_000)
        service.triggerIdentityChange()

        let got = await task.value
        #expect(got)
    }

    @Test func fakeNotifiesMultipleSubscribersOnIdentityChange() async {
        let service = FakeICloudAvailabilityService()
        let first = service.identityChanges
        let second = service.identityChanges

        let firstTask = Task { () -> Bool in
            for await _ in first { return true }
            return false
        }
        let secondTask = Task { () -> Bool in
            for await _ in second { return true }
            return false
        }

        try? await Task.sleep(nanoseconds: 50_000_000)
        service.triggerIdentityChange()

        #expect(await firstTask.value)
        #expect(await secondTask.value)
    }
}
