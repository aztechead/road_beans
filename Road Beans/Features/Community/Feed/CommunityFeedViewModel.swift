import Foundation
import Observation
import OSLog

enum CommunityFeedFilter: String, CaseIterable, Identifiable {
    case all
    case favorites
    case mine

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: "All"
        case .favorites: "Favorites"
        case .mine: "Mine"
        }
    }
}

enum CommunityFeedSort: String, CaseIterable, Identifiable {
    case newest
    case rating
    case likes

    var id: String { rawValue }

    var label: String {
        switch self {
        case .newest: "Newest"
        case .rating: "Rating"
        case .likes: "Likes"
        }
    }
}

@Observable
@MainActor
final class CommunityFeedViewModel {
    var favoritesRows: [CommunityVisitRow] = []
    var everyoneRows: [CommunityVisitRow] = []
    var state: ScreenState = .idle
    var nextCursor: String?
    var currentMember: CommunityMemberSnapshot?
    var filter: CommunityFeedFilter = .all
    var sort: CommunityFeedSort = .newest
    var isRefreshing = false
    var likedVisitIDs: Set<String> = []
    var blockedAuthorIDs = CommunityModerationStore.blockedAuthorIDs
    var moderationMessage: String?
    var reviewContextSummaries: [String: String] = [:]

    private struct CachedFeed {
        var favorites: [CommunityVisitRow]
        var everyone: [CommunityVisitRow]
        var nextCursor: String?
    }

    private var cache: [CommunityFeedFilter: CachedFeed] = [:]
    private var hasHydrated = false
    private let service: any CommunityService
    private let memberCache: CommunityMemberCache?
    private let favorites: any FavoriteMemberRepository
    private let diskCache: CommunityFeedDiskCache
    private let contextSummaryProvider: CommunityReviewContextSummaryProvider
    private let logger = Logger(subsystem: "brainmeld.Road-Beans", category: "CommunityFeed")

    init(
        service: any CommunityService,
        favorites: any FavoriteMemberRepository,
        memberCache: CommunityMemberCache? = nil,
        diskCache: CommunityFeedDiskCache = CommunityFeedDiskCache(),
        contextSummaryProvider: CommunityReviewContextSummaryProvider = CommunityReviewContextSummaryProvider()
    ) {
        self.service = service
        self.favorites = favorites
        self.memberCache = memberCache
        self.diskCache = diskCache
        self.contextSummaryProvider = contextSummaryProvider
    }

    func hydrateFromDisk() async {
        guard !hasHydrated else { return }
        hasHydrated = true
        await CommunityFeedDiskCache(filename: CommunityFeedDiskCache.legacyFilename).clear()
        let entries = await diskCache.load()
        for (key, entry) in entries {
            guard let filter = CommunityFeedFilter(rawValue: key) else { continue }
            cache[filter] = CachedFeed(
                favorites: visibleRows(entry.favorites),
                everyone: visibleRows(entry.everyone),
                nextCursor: entry.nextCursor
            )
        }
        if let cached = cache[filter] {
            favoritesRows = visibleRows(cached.favorites)
            everyoneRows = visibleRows(cached.everyone)
            nextCursor = cached.nextCursor
            refreshReviewContextSummaries()
            if !cached.favorites.isEmpty || !cached.everyone.isEmpty {
                state = .loaded
            }
        }
    }

    private func persistCacheToDisk() async {
        var entries: [String: CommunityFeedDiskCache.Entry] = [:]
        for (filter, cached) in cache {
            entries[filter.rawValue] = CommunityFeedDiskCache.Entry(
                favorites: cached.favorites,
                everyone: cached.everyone,
                nextCursor: cached.nextCursor,
                savedAt: Date.now
            )
        }
        await diskCache.save(entries)
    }

    func selectFilter(_ newFilter: CommunityFeedFilter) {
        filter = newFilter
        if let cached = cache[newFilter] {
            favoritesRows = visibleRows(cached.favorites)
            everyoneRows = visibleRows(cached.everyone)
            nextCursor = cached.nextCursor
        } else {
            favoritesRows = []
            everyoneRows = []
            nextCursor = nil
        }
    }

    func refresh() async {
        let shouldShowFullScreenLoading = state == .idle
        if shouldShowFullScreenLoading {
            state = .loading
        }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            currentMember = try await service.currentMember()
            guard let currentMember else {
                await memberCache?.store(nil)
                favoritesRows = []
                everyoneRows = []
                nextCursor = nil
                state = .empty
                cache.removeAll()
                await persistCacheToDisk()
                return
            }
            await memberCache?.store(currentMember)

            let favoriteIDs = Set((try? favorites.all().map(\.memberUserRecordID)) ?? [])
            let excludeSelf: Set<String> = [currentMember.userRecordID]
            switch filter {
            case .all:
                let favoritePage = try await loadPage(
                    cursor: nil,
                    limit: 20,
                    authorIDsToInclude: favoriteIDs.isEmpty ? [] : favoriteIDs,
                    authorIDsToExclude: excludeSelf,
                    label: "favorites"
                )
                let everyonePage = try await loadPage(
                    cursor: nil,
                    limit: 50,
                    authorIDsToInclude: nil,
                    authorIDsToExclude: excludeSelf,
                    label: "everyone"
                )
                favoritesRows = visibleRows(sorted(favoritePage.rows))
                everyoneRows = visibleRows(sorted(everyonePage.rows))
                nextCursor = sort == .newest ? everyonePage.nextCursor : nil
                cache[.all] = CachedFeed(
                    favorites: favoritesRows,
                    everyone: everyoneRows,
                    nextCursor: nextCursor
                )
                await persistCacheToDisk()
            case .favorites:
                let likedRows = try await service.fetchLikedVisitsByCurrentUser()
                favoritesRows = []
                everyoneRows = visibleRows(sorted(likedRows))
                nextCursor = nil
                cache[.favorites] = CachedFeed(favorites: [], everyone: everyoneRows, nextCursor: nil)
                await persistCacheToDisk()
            case .mine:
                let minePage = try await loadPage(
                    cursor: nil,
                    limit: 50,
                    authorIDsToInclude: [currentMember.userRecordID],
                    authorIDsToExclude: [],
                    label: "mine"
                )
                favoritesRows = []
                everyoneRows = visibleRows(sorted(minePage.rows))
                nextCursor = sort == .newest ? minePage.nextCursor : nil
                cache[.mine] = CachedFeed(favorites: [], everyone: everyoneRows, nextCursor: nextCursor)
                await persistCacheToDisk()
            }
            state = .loaded
            refreshReviewContextSummaries()
            await hydrateLikedStateForVisibleRows()
        } catch {
            if shouldShowFullScreenLoading {
                state = .failed("Road Beans could not load community visits.")
            } else {
                logger.error("Community refresh failed: \(String(describing: error), privacy: .public)")
            }
        }
    }

    func loadNextPage() async {
        guard let nextCursor else { return }
        do {
            let include: Set<String>? = filter == .mine ? currentMember.map { Set([$0.userRecordID]) } : nil
            let exclude: Set<String> = filter == .mine ? [] : currentMember.map { Set([$0.userRecordID]) } ?? []
            let page = try await service.fetchFeedPage(
                cursor: nextCursor,
                limit: 50,
                authorIDsToInclude: include,
                authorIDsToExclude: exclude
            )
            everyoneRows.append(contentsOf: visibleRows(sorted(page.rows)))
            self.nextCursor = page.nextCursor
            refreshReviewContextSummaries()
        } catch {
            state = .failed("Road Beans could not load more community visits.")
        }
    }

    func isFavorite(_ row: CommunityVisitRow) -> Bool {
        (try? favorites.contains(memberUserRecordID: row.authorUserRecordID)) ?? false
    }

    func isLiked(_ row: CommunityVisitRow) -> Bool {
        likedVisitIDs.contains(row.id)
    }

    func reviewContextSummary(for row: CommunityVisitRow) -> String? {
        reviewContextSummaries[row.id] ?? CommunityReviewContextSummary.fallbackSummary(for: row)
    }

    func toggleLike(_ row: CommunityVisitRow) async {
        let wasLiked = likedVisitIDs.contains(row.id)
        setLiked(!wasLiked, for: row.id)
        adjustLikeCount(for: row.id, delta: wasLiked ? -1 : 1)
        do {
            if wasLiked {
                try await service.unlike(visitRecordName: row.id)
                if filter == .favorites {
                    removeRow(recordName: row.id)
                }
            } else {
                try await service.like(visitRecordName: row.id)
            }
        } catch {
            setLiked(wasLiked, for: row.id)
            adjustLikeCount(for: row.id, delta: wasLiked ? 1 : -1)
            logger.error("Community feed like failed for \(row.id, privacy: .public): \(String(describing: error), privacy: .public)")
        }
    }

    func deleteVisit(_ row: CommunityVisitRow) async {
        guard filter == .mine else { return }
        do {
            try await service.deleteVisit(recordName: row.id)
            removeRow(recordName: row.id)
        } catch {
            logger.error("Community feed delete failed for \(row.id, privacy: .public): \(String(describing: error), privacy: .public)")
        }
    }

    func report(_ row: CommunityVisitRow) async {
        moderationMessage = nil
        do {
            try await service.reportVisit(
                CommunityReportDraft(
                    visitRecordName: row.id,
                    reportedAuthorUserRecordID: row.authorUserRecordID,
                    reason: "Reported from community feed"
                )
            )
            moderationMessage = "Report sent. Road Beans will review it within 24 hours."
        } catch {
            logger.error("Community report failed for \(row.id, privacy: .public): \(String(describing: error), privacy: .public)")
            moderationMessage = "Road Beans could not send this report."
        }
    }

    func blockAuthor(_ row: CommunityVisitRow) {
        CommunityModerationStore.block(authorUserRecordID: row.authorUserRecordID)
        blockedAuthorIDs = CommunityModerationStore.blockedAuthorIDs
        removeAuthor(row.authorUserRecordID)
        moderationMessage = "Blocked \(row.authorDisplayName)."
    }

    private func loadPage(
        cursor: String?,
        limit: Int,
        authorIDsToInclude: Set<String>?,
        authorIDsToExclude: Set<String>,
        label: String
    ) async throws -> CommunityFeedPage {
        do {
            return try await service.fetchFeedPage(
                cursor: cursor,
                limit: limit,
                authorIDsToInclude: authorIDsToInclude,
                authorIDsToExclude: authorIDsToExclude
            )
        } catch {
            logger.error("Community feed \(label, privacy: .public) query failed: \(String(describing: error), privacy: .public)")
            throw error
        }
    }

    private func sorted(_ rows: [CommunityVisitRow]) -> [CommunityVisitRow] {
        switch sort {
        case .newest:
            rows.sorted { $0.publishedAt > $1.publishedAt }
        case .rating:
            rows.sorted {
                if $0.beanRating == $1.beanRating {
                    return $0.publishedAt > $1.publishedAt
                }
                return $0.beanRating > $1.beanRating
            }
        case .likes:
            rows.sorted {
                if $0.likeCount == $1.likeCount {
                    return $0.publishedAt > $1.publishedAt
                }
                return $0.likeCount > $1.likeCount
            }
        }
    }

    private func liveRows(_ rows: [CommunityVisitRow]) -> [CommunityVisitRow] {
        rows.filter { !$0.id.hasPrefix("_schema_") }
    }

    private func visibleRows(_ rows: [CommunityVisitRow]) -> [CommunityVisitRow] {
        liveRows(rows).filter { row in
            !blockedAuthorIDs.contains(row.authorUserRecordID)
                && !CommunityContentFilter.containsBlockedContent([
                    row.authorDisplayName,
                    row.placeName,
                    row.drinkSummary,
                    row.tagSummary
                ])
        }
    }

    private func refreshReviewContextSummaries() {
        let rows = favoritesRows + everyoneRows
        let visibleIDs = Set(rows.map(\.id))
        reviewContextSummaries = reviewContextSummaries.filter { visibleIDs.contains($0.key) }

        for row in rows {
            guard let fallback = CommunityReviewContextSummary.fallbackSummary(for: row) else { continue }
            reviewContextSummaries[row.id] = fallback
        }

        Task { [contextSummaryProvider] in
            for row in rows {
                guard let synthesized = await contextSummaryProvider.synthesizedSummary(for: row) else { continue }
                await MainActor.run {
                    guard favoritesRows.contains(where: { $0.id == row.id })
                        || everyoneRows.contains(where: { $0.id == row.id }) else { return }
                    reviewContextSummaries[row.id] = synthesized
                }
            }
        }
    }

    private func hydrateLikedStateForVisibleRows() async {
        let rows = favoritesRows + everyoneRows
        let ids = Set(rows.map(\.id))
        do {
            let likedIDs = try await service.likedVisitIDsByCurrentUser(in: ids)
            for id in ids {
                setLiked(likedIDs.contains(id), for: id)
            }
        } catch {
            logger.error("Community feed liked state hydrate failed: \(String(describing: error), privacy: .public)")
        }
    }

    private func setLiked(_ liked: Bool, for recordName: String) {
        if liked {
            likedVisitIDs.insert(recordName)
        } else {
            likedVisitIDs.remove(recordName)
        }
    }

    private func adjustLikeCount(for recordName: String, delta: Int) {
        updateRows { rows in
            guard let index = rows.firstIndex(where: { $0.id == recordName }) else { return }
            rows[index].likeCount = max(0, rows[index].likeCount + delta)
        }
    }

    private func removeRow(recordName: String) {
        updateRows { rows in
            rows.removeAll { $0.id == recordName }
        }
        likedVisitIDs.remove(recordName)
    }

    private func removeAuthor(_ authorUserRecordID: String) {
        updateRows { rows in
            rows.removeAll { $0.authorUserRecordID == authorUserRecordID }
        }
    }

    private func updateRows(_ update: (inout [CommunityVisitRow]) -> Void) {
        update(&favoritesRows)
        update(&everyoneRows)
        cache[filter] = CachedFeed(favorites: favoritesRows, everyone: everyoneRows, nextCursor: nextCursor)
        Task { await persistCacheToDisk() }
    }
}
