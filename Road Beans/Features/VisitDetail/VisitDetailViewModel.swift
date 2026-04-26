import Foundation
import Observation

@Observable
@MainActor
final class VisitDetailViewModel {
    var detail: VisitDetail?
    var state: ScreenState = .idle

    private let visits: any VisitRepository
    let visitID: UUID

    init(visits: any VisitRepository, visitID: UUID) {
        self.visits = visits
        self.visitID = visitID
    }

    func load() async {
        state = .loading
        do {
            detail = try await visits.detail(id: visitID)
            state = detail == nil ? .empty : .loaded
        } catch {
            detail = nil
            state = .failed("Road Beans could not load this visit. Try again.")
        }
    }

    func delete() async throws {
        try await visits.delete(DeleteVisitCommand(id: visitID))
    }

    func update(_ command: UpdateVisitCommand) async throws {
        try await visits.update(command)
        await load()
    }
}
