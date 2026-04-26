import Foundation
import Observation

@Observable
@MainActor
final class AddVisitFlowModel {
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
    let tagsRepo: any TagRepository
    let searchService: any LocationSearchService
    let photoProcessor: any PhotoProcessingService

    private var searchTask: Task<Void, Never>?

    init(
        visits: any VisitRepository,
        tags: any TagRepository,
        search: any LocationSearchService,
        photoProcessor: any PhotoProcessingService
    ) {
        self.visits = visits
        self.tagsRepo = tags
        self.searchService = search
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
                let results = try await self.searchService.search(query: query, near: nil)
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

    func selectCustom(_ draft: CustomPlaceDraft) {
        placeRef = .newCustom(draft)
        currentPage = 1
    }
}
