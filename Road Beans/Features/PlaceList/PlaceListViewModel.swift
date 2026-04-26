import Foundation
import Observation

enum PlaceListMode: String, CaseIterable, Identifiable, Sendable {
    case byPlace = "By Place"
    case recentVisits = "Recent Visits"

    var id: String { rawValue }
}

enum PlaceRatingFilter: String, CaseIterable, Identifiable, Sendable {
    case any = "Any Rating"
    case threePlus = "3+ Beans"
    case fourPlus = "4+ Beans"
    case five = "5 Beans"

    var id: String { rawValue }

    var minimumRating: Double? {
        switch self {
        case .any:
            nil
        case .threePlus:
            3
        case .fourPlus:
            4
        case .five:
            5
        }
    }
}

@Observable
@MainActor
final class PlaceListViewModel {
    var mode: PlaceListMode = .byPlace
    var searchText = ""
    var selectedKind: PlaceKind?
    var ratingFilter: PlaceRatingFilter = .any
    var selectedTags: [String] = []
    var isDateFilterEnabled = false
    var startDate = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
    var endDate = Date.now
    var places: [PlaceSummary] = []
    var recentVisits: [RecentVisitRow] = []
    var state: ScreenState = .idle

    private let placeRepository: any PlaceRepository
    private let visitRepository: any VisitRepository

    init(places: any PlaceRepository, visits: any VisitRepository) {
        self.placeRepository = places
        self.visitRepository = visits
    }

    func reload() async {
        state = .loading
        do {
            async let loadedPlaces = placeRepository.summaries()
            async let loadedVisits = visitRepository.recentRows(limit: 200)
            places = try await loadedPlaces
            recentVisits = try await loadedVisits
            state = places.isEmpty && recentVisits.isEmpty ? .empty : .loaded
        } catch {
            places = []
            recentVisits = []
            state = .failed("Road Beans could not load your stops. Pull to retry.")
        }
    }

    var filteredPlaces: [PlaceSummary] {
        places.filter { place in
            matchesSearch(place)
                && matchesKind(place.kind)
                && matchesRating(place.averageRating)
                && matchesPlaceVisitFilters(place)
        }
    }

    var filteredVisits: [RecentVisitRow] {
        recentVisits.filter { row in
            matchesSearch(row)
                && matchesKind(row.placeKind)
                && matchesRating(row.visit.averageRating)
                && matchesTags(row.visit.tagNames)
                && matchesDate(row.visit.date)
        }
    }

    var availableTags: [String] {
        let tags = recentVisits.flatMap(\.visit.tagNames)
        return Array(Set(tags)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    var activeFilterCount: Int {
        var count = 0
        if selectedKind != nil { count += 1 }
        if ratingFilter != .any { count += 1 }
        if !selectedTags.isEmpty { count += 1 }
        if isDateFilterEnabled { count += 1 }
        return count
    }

    func clearFilters() {
        selectedKind = nil
        ratingFilter = .any
        selectedTags = []
        isDateFilterEnabled = false
    }

    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.removeAll { $0 == tag }
        } else {
            selectedTags.append(tag)
        }
    }

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var normalizedDateRange: ClosedRange<Date> {
        min(startDate, endDate)...max(startDate, endDate)
    }

    private func matchesSearch(_ place: PlaceSummary) -> Bool {
        let query = normalizedSearchText
        guard !query.isEmpty else { return true }

        return place.name.localizedCaseInsensitiveContains(query)
            || (place.address?.localizedCaseInsensitiveContains(query) ?? false)
    }

    private func matchesSearch(_ row: RecentVisitRow) -> Bool {
        let query = normalizedSearchText
        guard !query.isEmpty else { return true }

        return row.placeName.localizedCaseInsensitiveContains(query)
            || row.visit.tagNames.contains { $0.localizedCaseInsensitiveContains(query) }
            || row.drinkNames.contains { $0.localizedCaseInsensitiveContains(query) }
    }

    private func matchesKind(_ kind: PlaceKind) -> Bool {
        guard let selectedKind else { return true }
        return kind == selectedKind
    }

    private func matchesRating(_ rating: Double?) -> Bool {
        guard let minimumRating = ratingFilter.minimumRating else { return true }
        guard let rating else { return false }
        return rating >= minimumRating
    }

    private func matchesTags(_ tags: [String]) -> Bool {
        guard !selectedTags.isEmpty else { return true }
        return selectedTags.allSatisfy { selected in
            tags.contains { $0.localizedCaseInsensitiveCompare(selected) == .orderedSame }
        }
    }

    private func matchesDate(_ date: Date) -> Bool {
        guard isDateFilterEnabled else { return true }
        return normalizedDateRange.contains(date)
    }

    private func matchesPlaceVisitFilters(_ place: PlaceSummary) -> Bool {
        guard !selectedTags.isEmpty || isDateFilterEnabled else { return true }

        return recentVisits.contains { row in
            row.placeName.localizedCaseInsensitiveCompare(place.name) == .orderedSame
                && matchesTags(row.visit.tagNames)
                && matchesDate(row.visit.date)
        }
    }

    var isShowingEmptyResults: Bool {
        switch mode {
        case .byPlace:
            filteredPlaces.isEmpty
        case .recentVisits:
            filteredVisits.isEmpty
        }
    }
}
