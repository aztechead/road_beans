import Foundation
import SwiftData

@MainActor
final class LocalFavoriteMemberRepository: FavoriteMemberRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func add(memberUserRecordID: String) throws {
        let normalized = memberUserRecordID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        guard try !contains(memberUserRecordID: normalized) else { return }

        let record = FavoriteMember()
        record.memberUserRecordID = normalized
        record.addedAt = Date.now
        context.insert(record)
        try context.save()
    }

    func remove(memberUserRecordID: String) throws {
        let predicate = #Predicate<FavoriteMember> { $0.memberUserRecordID == memberUserRecordID }
        let descriptor = FetchDescriptor<FavoriteMember>(predicate: predicate)
        for record in try context.fetch(descriptor) {
            context.delete(record)
        }
        try context.save()
    }

    func all() throws -> [FavoriteMemberSummary] {
        let descriptor = FetchDescriptor<FavoriteMember>(
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map(Self.summary(_:))
    }

    func contains(memberUserRecordID: String) throws -> Bool {
        let predicate = #Predicate<FavoriteMember> { $0.memberUserRecordID == memberUserRecordID }
        var descriptor = FetchDescriptor<FavoriteMember>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try !context.fetch(descriptor).isEmpty
    }

    private static func summary(_ member: FavoriteMember) -> FavoriteMemberSummary {
        FavoriteMemberSummary(
            id: member.id,
            memberUserRecordID: member.memberUserRecordID,
            addedAt: member.addedAt
        )
    }
}
