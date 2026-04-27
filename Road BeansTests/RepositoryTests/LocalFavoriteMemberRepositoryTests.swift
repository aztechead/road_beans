import Foundation
import SwiftData
import Testing
@testable import Road_Beans

@Suite("LocalFavoriteMemberRepository")
@MainActor
struct LocalFavoriteMemberRepositoryTests {
    private func makeRepo() throws -> LocalFavoriteMemberRepository {
        let container = try ModelContainer(
            for: AppSchema.all,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return LocalFavoriteMemberRepository(context: ModelContext(container))
    }

    @Test func addInsertsRecord() throws {
        let repo = try makeRepo()

        try repo.add(memberUserRecordID: "abc")

        #expect(try repo.all().map(\.memberUserRecordID) == ["abc"])
    }

    @Test func addIsIdempotent() throws {
        let repo = try makeRepo()

        try repo.add(memberUserRecordID: "abc")
        try repo.add(memberUserRecordID: "abc")

        #expect(try repo.all().count == 1)
    }

    @Test func removeDeletesRecord() throws {
        let repo = try makeRepo()
        try repo.add(memberUserRecordID: "abc")

        try repo.remove(memberUserRecordID: "abc")

        #expect(try repo.all().isEmpty)
    }
}
