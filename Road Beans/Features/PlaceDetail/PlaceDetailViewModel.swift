import Foundation
import Observation

@Observable
@MainActor
final class PlaceDetailViewModel {
    var detail: PlaceDetail?

    private let placeRepository: any PlaceRepository

    init(placeRepo: any PlaceRepository) {
        self.placeRepository = placeRepo
    }

    func load(id: UUID) async {
        detail = try? await placeRepository.detail(id: id)
    }
}
