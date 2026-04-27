import Foundation

struct FavoriteMemberSummary: Identifiable, Sendable, Equatable {
    let id: UUID
    let memberUserRecordID: String
    let addedAt: Date
}

@MainActor
protocol FavoriteMemberRepository: Sendable {
    func add(memberUserRecordID: String) throws
    func remove(memberUserRecordID: String) throws
    func all() throws -> [FavoriteMemberSummary]
    func contains(memberUserRecordID: String) throws -> Bool
}
