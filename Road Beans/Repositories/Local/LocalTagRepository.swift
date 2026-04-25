import Foundation
import SwiftData

@MainActor
final class LocalTagRepository: TagRepository {
    private let context: ModelContext
    private let sync: any RemoteSyncCoordinator

    init(context: ModelContext, sync: any RemoteSyncCoordinator) {
        self.context = context
        self.sync = sync
    }

    static func normalize(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let collapsed = trimmed.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        return collapsed.lowercased()
    }

    func findOrCreate(name: String) async throws -> UUID {
        let normalized = Self.normalize(name)
        guard !normalized.isEmpty else { throw TagRepositoryError.emptyName }

        let predicate = #Predicate<Tag> { $0.name == normalized }
        var descriptor = FetchDescriptor<Tag>(predicate: predicate)
        descriptor.fetchLimit = 1

        if let existing = try context.fetch(descriptor).first {
            return existing.id
        }

        let tag = Tag()
        tag.name = normalized
        tag.lastModifiedAt = Date.now
        context.insert(tag)
        try context.save()
        await sync.markDirty(.tag, id: tag.id)
        return tag.id
    }

    func suggestions(prefix: String, limit: Int) async throws -> [TagSuggestion] {
        let needle = Self.normalize(prefix)
        let descriptor = FetchDescriptor<Tag>()
        let tags = try context.fetch(descriptor)
        let filtered = needle.isEmpty ? tags : tags.filter { $0.name.hasPrefix(needle) }
        let sorted = filtered.sorted { lhs, rhs in
            if lhs.usageCount != rhs.usageCount {
                return lhs.usageCount > rhs.usageCount
            }
            return lhs.lastModifiedAt > rhs.lastModifiedAt
        }

        return sorted.prefix(limit).map {
            TagSuggestion(id: $0.id, name: $0.name, usageCount: $0.usageCount)
        }
    }

    func all() async throws -> [TagSuggestion] {
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name)])
        let tags = try context.fetch(descriptor)
        return tags.map {
            TagSuggestion(id: $0.id, name: $0.name, usageCount: $0.usageCount)
        }
    }
}
