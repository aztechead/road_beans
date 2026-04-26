import Testing
@testable import Road_Beans

@Suite("LocationPermissionService")
struct LocationPermissionServiceTests {
    @Test func fakeReportsAndStreamsStatus() async {
        let service = FakeLocationPermissionService(initial: .notDetermined)

        let initial = await service.status
        #expect(initial == .notDetermined)

        let stream = service.statusChanges
        let task = Task { () -> LocationAuthorization? in
            for await status in stream {
                return status
            }
            return nil
        }

        try? await Task.sleep(nanoseconds: 50_000_000)
        service.simulateChange(.authorized)

        let received = await task.value
        #expect(received == .authorized)
    }
}
