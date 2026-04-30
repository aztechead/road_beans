import CoreLocation
import Foundation
import Observation

@Observable
@MainActor
final class AddVisitFlowModel {
    static let quickLogRadiusMeters: Double = 250

    var placeRef: PlaceReference?
    var date: Date = .now
    var visitTags: [String] = []
    var drinks: [DrinkDraft] = []
    var photos: [PhotoDraft] = []

    var currentPage: Int = 0

    var searchText: String = ""
    var searchResults: [MapKitPlaceDraft] = []
    var searchState: ScreenState = .idle

    let visits: any VisitRepository
    let places: any PlaceRepository
    let tagsRepo: any TagRepository
    let searchService: any LocationSearchService
    let currentLocationProvider: any CurrentLocationProvider
    let photoProcessor: any PhotoProcessingService

    private var searchTask: Task<Void, Never>?

    init(
        visits: any VisitRepository,
        places: any PlaceRepository,
        tags: any TagRepository,
        search: any LocationSearchService,
        currentLocation: any CurrentLocationProvider,
        photoProcessor: any PhotoProcessingService
    ) {
        self.visits = visits
        self.places = places
        self.tagsRepo = tags
        self.searchService = search
        self.currentLocationProvider = currentLocation
        self.photoProcessor = photoProcessor
    }

    @discardableResult
    func search() -> Task<Void, Never>? {
        searchTask?.cancel()

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            searchState = .idle
            return nil
        }

        searchState = .loading
        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled, let self else { return }

            do {
                let currentCoordinate = try? await self.currentLocationProvider.currentCoordinate()
                guard !Task.isCancelled else { return }

                let results = try await self.searchService.search(query: query, near: currentCoordinate)
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.searchResults = results
                    self.searchState = results.isEmpty ? .empty : .loaded
                }
            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.searchResults = []
                    self.searchState = .failed("Road Beans could not search places. Check your connection and try again.")
                }
            }
        }
        return searchTask
    }

    func selectMapKit(_ draft: MapKitPlaceDraft) {
        placeRef = .newMapKit(draft)
        currentPage = 1
    }

    func prepareQuickLogHere() async throws {
        if drinks.isEmpty {
            drinks = [DrinkDraft(name: DrinkCategory.drip.displayName, category: .drip, rating: 3, tags: [])]
        }

        let coordinate = try await currentLocationProvider.currentCoordinate()
        let nearbyPlaces = try await places.summariesNear(
            coordinate: coordinate,
            radiusMeters: Self.quickLogRadiusMeters
        )

        guard let nearest = nearbyPlaces.nearest(to: coordinate) else {
            placeRef = nil
            currentPage = 0
            return
        }

        placeRef = .existing(id: nearest.id)
        currentPage = 2
    }
}

private extension Array where Element == PlaceSummary {
    func nearest(to coordinate: CLLocationCoordinate2D) -> PlaceSummary? {
        compactMap { place -> (place: PlaceSummary, distance: Double)? in
            guard let placeCoordinate = place.coordinate else { return nil }
            return (place, placeCoordinate.distance(to: coordinate))
        }
        .min { $0.distance < $1.distance }?
        .place
    }
}
