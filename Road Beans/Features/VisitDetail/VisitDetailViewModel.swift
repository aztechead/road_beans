import Foundation
import Observation

@Observable
@MainActor
final class VisitDetailViewModel {
    var detail: VisitDetail?

    private let visits: any VisitRepository
    let visitID: UUID

    init(visits: any VisitRepository, visitID: UUID) {
        self.visits = visits
        self.visitID = visitID
    }

    func load() async {
        detail = try? await visits.detail(id: visitID)
    }

    func delete() async throws {
        try await visits.delete(DeleteVisitCommand(id: visitID))
    }
}
