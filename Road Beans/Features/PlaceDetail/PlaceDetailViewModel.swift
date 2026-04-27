import CoreLocation
import Foundation
import Observation

@Observable
@MainActor
final class PlaceDetailViewModel {
    var detail: PlaceDetail?
    var communityRows: [CommunityVisitRow] = []
    var state: ScreenState = .idle

    private let placeRepository: any PlaceRepository
    private let visitRepository: any VisitRepository
    private let community: any CommunityService

    init(
        placeRepo: any PlaceRepository,
        visitRepo: any VisitRepository,
        community: (any CommunityService)? = nil
    ) {
        self.placeRepository = placeRepo
        self.visitRepository = visitRepo
        self.community = community ?? MissingCommunityService()
    }

    func load(id: UUID) async {
        state = .loading
        do {
            detail = try await placeRepository.detail(id: id)
            if let detail {
                await loadCommunityVisits(place: detail)
            } else {
                communityRows = []
            }
            state = detail == nil ? .empty : .loaded
        } catch {
            detail = nil
            communityRows = []
            state = .failed("Road Beans could not load this stop. Try again.")
        }
    }

    func loadCommunityVisits(place: PlaceDetail) async {
        guard (try? await community.currentMember()) != nil else {
            communityRows = []
            return
        }

        do {
            if let identifier = place.mapKitIdentifier {
                communityRows = try await community.fetchVisits(matchingMapKitIdentifier: identifier)
            } else if let latitude = place.latitude, let longitude = place.longitude {
                communityRows = try await community.fetchVisits(
                    near: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                    radiusMeters: 50,
                    nameContains: place.name
                )
            } else {
                communityRows = []
            }
        } catch {
            communityRows = []
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
