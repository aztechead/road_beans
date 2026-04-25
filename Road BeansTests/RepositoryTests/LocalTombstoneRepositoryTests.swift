import Foundation
import SwiftData
import Testing
@testable import Road_Beans

@Suite("LocalTombstoneRepository")
@MainActor
struct LocalTombstoneRepositoryTests {
    @Test func insertAndListRoundtrip() async throws {
        let container = try ModelContainer(
            for: AppSchema.all,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let sync = LocalOnlyRemoteSync()
        let repository = LocalTombstoneRepository(context: context, sync: sync)
        let visitID = UUID()

        try await repository.insertTombstone(entityKind: .visit, entityID: visitID, remoteID: nil)

        let all = try await repository.all()
        #expect(all.count == 1)
        #expect(all[0].entityID == visitID)
        #expect(all[0].entityKind == "visit")
        #expect(await sync.recordedCalls == [.init(kind: .tombstone, id: all[0].id)])
    }
}
