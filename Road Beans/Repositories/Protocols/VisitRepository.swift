import Foundation

enum VisitValidationError: Error, Equatable {
    case missingDrinks
}

enum VisitRepositoryError: Error, Equatable {
    case notFound
}

struct RecentVisitRow: Sendable {
    let visit: VisitRow
    let placeName: String
    let placeKind: PlaceKind
}

protocol VisitRepository: Sendable {
    func save(_ command: CreateVisitCommand) async throws -> UUID
    func update(_ command: UpdateVisitCommand) async throws
    func delete(_ command: DeleteVisitCommand) async throws
    func recentRows(limit: Int) async throws -> [RecentVisitRow]
    func detail(id: UUID) async throws -> VisitDetail?
}
