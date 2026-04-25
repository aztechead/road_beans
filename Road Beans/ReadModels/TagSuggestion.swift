import Foundation

struct TagSuggestion: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let usageCount: Int
}
