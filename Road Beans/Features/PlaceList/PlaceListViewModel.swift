import Foundation
import Observation

enum PlaceListMode: String, CaseIterable, Identifiable, Sendable {
    case byPlace = "By Place"
    case recentVisits = "Recent Visits"

    var id: String { rawValue }
}

@Observable
@MainActor
final class PlaceListViewModel {
    var mode: PlaceListMode = .byPlace
    var searchText = ""
    var places: [PlaceSummary] = []
    var recentVisits: [RecentVisitRow] = []

    private let placeRepository: any PlaceRepository
    private let visitRepository: any VisitRepository

    init(places: any PlaceRepository, visits: any VisitRepository) {
        self.placeRepository = places
        self.visitRepository = visits
    }

    func reload() async {
        do {
            async let loadedPlaces = placeRepository.summaries()
            async let loadedVisits = visitRepository.recentRows(limit: 200)
            places = try await loadedPlaces
            recentVisits = try await loadedVisits
        } catch {
            places = []
            recentVisits = []
        }
    }

    var filteredPlaces: [PlaceSummary] {
        let query = normalizedSearchText
        guard !query.isEmpty else { return places }
        return places.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var filteredVisits: [RecentVisitRow] {
        let query = normalizedSearchText
        guard !query.isEmpty else { return recentVisits }

        return recentVisits.filter { row in
            row.placeName.localizedCaseInsensitiveContains(query)
                || row.visit.tagNames.contains { $0.localizedCaseInsensitiveContains(query) }
                || row.drinkNames.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
