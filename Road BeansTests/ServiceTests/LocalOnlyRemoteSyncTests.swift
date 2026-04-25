import Foundation
import Testing
@testable import Road_Beans

@Suite("LocalOnlyRemoteSync")
struct LocalOnlyRemoteSyncTests {
    @Test func markDirtyRecordsCalls() async {
        let sync = LocalOnlyRemoteSync()
        let id = UUID()

        await sync.markDirty(.visit, id: id)

        let calls = await sync.recordedCalls
        #expect(calls.count == 1)
        #expect(calls.first?.kind == .visit)
        #expect(calls.first?.id == id)
    }
}
