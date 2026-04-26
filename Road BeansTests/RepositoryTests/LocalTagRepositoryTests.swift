import Foundation
import SwiftData
import Testing
@testable import Road_Beans

@Suite("LocalTagRepository")
@MainActor
struct LocalTagRepositoryTests {
    func makeRepo() throws -> (LocalTagRepository, ModelContext, LocalOnlyRemoteSync) {
        let container = try ModelContainer(
            for: AppSchema.all,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let sync = LocalOnlyRemoteSync()
        return (LocalTagRepository(context: context, sync: sync), context, sync)
    }

    @Test func findOrCreateNormalizes() async throws {
        let (repo, _, _) = try makeRepo()

        let id1 = try await repo.findOrCreate(name: "  Smooth  ")
        let id2 = try await repo.findOrCreate(name: "smooth")
        let id3 = try await repo.findOrCreate(name: "SMOOTH")
        let id4 = try await repo.findOrCreate(name: "smooth   and  sweet")
        let id5 = try await repo.findOrCreate(name: "smooth and sweet")

        #expect(id1 == id2)
        #expect(id2 == id3)
        #expect(id4 == id5)
    }

    @Test func emptyNameThrows() async throws {
        let (repo, _, _) = try makeRepo()

        await #expect(throws: TagRepositoryError.self) {
            _ = try await repo.findOrCreate(name: "   ")
        }
    }

    @Test func suggestionsFilterAndSort() async throws {
        let (repo, context, _) = try makeRepo()
        _ = try await repo.findOrCreate(name: "smooth")
        _ = try await repo.findOrCreate(name: "smoky")
        _ = try await repo.findOrCreate(name: "burnt")

        let tags = try context.fetch(FetchDescriptor<Road_Beans.Tag>())
        let smooth = try #require(tags.first { $0.name == "smooth" })
        let smoky = try #require(tags.first { $0.name == "smoky" })
        smooth._visits = [Visit()]
        smooth._drinks = [Drink()]
        smoky._visits = [Visit()]
        try context.save()

        let suggestions = try await repo.suggestions(prefix: "sm", limit: 5)

        #expect(suggestions.map(\.name) == ["smooth", "smoky"])
        #expect(suggestions.map(\.usageCount) == [2, 1])
    }

    @Test func suggestionsLimitHonored() async throws {
        let (repo, _, _) = try makeRepo()
        for name in ["smooth", "smoky", "smoke", "smush", "small"] {
            _ = try await repo.findOrCreate(name: name)
        }

        let suggestions = try await repo.suggestions(prefix: "sm", limit: 3)

        #expect(suggestions.count == 3)
    }

    @Test func allReturnsNameSortedSuggestions() async throws {
        let (repo, _, _) = try makeRepo()
        _ = try await repo.findOrCreate(name: "zesty")
        _ = try await repo.findOrCreate(name: "bright")

        let suggestions = try await repo.all()

        #expect(suggestions.map(\.name) == ["bright", "zesty"])
    }

    @Test func markDirtyCalledOnCreateOnly() async throws {
        let (repo, _, sync) = try makeRepo()

        let id = try await repo.findOrCreate(name: "smooth")
        _ = try await repo.findOrCreate(name: "smooth")

        let calls = await sync.recordedCalls
        #expect(calls == [.init(kind: .tag, id: id)])
    }

    @Test func seedDefaultsCreatesExpectedTags() async throws {
        let (repo, _, _) = try makeRepo()
        let testDefaults = UserDefaults(suiteName: "test-seed-\(UUID().uuidString)")!

        repo.seedDefaultsIfNeeded(defaults: testDefaults)

        let all = try await repo.all()
        let names = all.map(\.name)
        #expect(names.contains("trailer parking"))
        #expect(names.contains("good food options"))
        #expect(names.contains("remote work friendly"))
        #expect(testDefaults.bool(forKey: "hasSeededDefaultTags") == true)
    }

    @Test func seedDefaultsIsIdempotent() async throws {
        let (repo, _, _) = try makeRepo()
        let testDefaults = UserDefaults(suiteName: "test-seed-idempotent-\(UUID().uuidString)")!

        repo.seedDefaultsIfNeeded(defaults: testDefaults)
        repo.seedDefaultsIfNeeded(defaults: testDefaults)

        let all = try await repo.all()
        #expect(all.count == 3)
        #expect(all.filter { $0.name == "trailer parking" }.count == 1)
        #expect(all.filter { $0.name == "good food options" }.count == 1)
        #expect(all.filter { $0.name == "remote work friendly" }.count == 1)
    }
}
