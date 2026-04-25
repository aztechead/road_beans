import Foundation

enum TagRepositoryError: Error, Equatable {
    case emptyName
}

protocol TagRepository: Sendable {
    func findOrCreate(name: String) async throws -> UUID
    func suggestions(prefix: String, limit: Int) async throws -> [TagSuggestion]
    func all() async throws -> [TagSuggestion]
}
