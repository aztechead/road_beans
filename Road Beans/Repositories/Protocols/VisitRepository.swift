import Foundation

enum VisitValidationError: Error, Equatable {
    case missingPlace
    case missingDrinks
}

enum VisitRepositoryError: Error, Equatable {
    case notFound
}

struct RecentVisitRow: Sendable {
    let visit: VisitRow
    let placeName: String
    let placeKind: PlaceKind
    let drinkNames: [String]

    init(visit: VisitRow, placeName: String, placeKind: PlaceKind, drinkNames: [String] = []) {
        self.visit = visit
        self.placeName = placeName
        self.placeKind = placeKind
        self.drinkNames = drinkNames
    }
}

protocol VisitRepository: Sendable {
    func save(_ command: CreateVisitCommand) async throws -> UUID
    func update(_ command: UpdateVisitCommand) async throws
    func delete(_ command: DeleteVisitCommand) async throws
    func recentRows(limit: Int) async throws -> [RecentVisitRow]
    func detail(id: UUID) async throws -> VisitDetail?
}
