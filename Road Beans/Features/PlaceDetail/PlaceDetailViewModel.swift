import Foundation
import Observation

@Observable
@MainActor
final class PlaceDetailViewModel {
    var detail: PlaceDetail?
    var state: ScreenState = .idle

    private let placeRepository: any PlaceRepository
    private let visitRepository: any VisitRepository

    init(placeRepo: any PlaceRepository, visitRepo: any VisitRepository) {
        self.placeRepository = placeRepo
        self.visitRepository = visitRepo
    }

    func load(id: UUID) async {
        state = .loading
        do {
            detail = try await placeRepository.detail(id: id)
            state = detail == nil ? .empty : .loaded
        } catch {
            detail = nil
            state = .failed("Road Beans could not load this stop. Try again.")
        }
    }

    func update(_ command: UpdatePlaceCommand) async throws {
        try await placeRepository.update(command)
        await load(id: command.id)
    }

    func deleteVisit(id: UUID, placeID: UUID) async throws {
        try await visitRepository.delete(DeleteVisitCommand(id: id))
        await load(id: placeID)
    }
}
