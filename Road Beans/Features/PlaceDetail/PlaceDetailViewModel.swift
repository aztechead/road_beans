import Foundation
import Observation

@Observable
@MainActor
final class PlaceDetailViewModel {
    var detail: PlaceDetail?
    var state: ScreenState = .idle

    private let placeRepository: any PlaceRepository

    init(placeRepo: any PlaceRepository) {
        self.placeRepository = placeRepo
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
}
