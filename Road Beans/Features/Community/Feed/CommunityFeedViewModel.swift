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
    case comments

    var id: String { rawValue }

    var label: String {
        switch self {
        case .newest: "Newest"
        case .rating: "Rating"
        case .likes: "Likes"
        case .comments: "Comments"
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

    private struct CachedFeed {
        var favorites: [CommunityVisitRow]
        var everyone: [CommunityVisitRow]
        var nextCursor: String?
    }

    private var cache: [CommunityFeedFilter: CachedFeed] = [:]
    private var hasHydrated = false
    private let service: any CommunityService
    private let favorites: any FavoriteMemberRepository
    private let diskCache: CommunityFeedDiskCache
    private let logger = Logger(subsystem: "brainmeld.Road-Beans", category: "CommunityFeed")

    init(
        service: any CommunityService,
        favorites: any FavoriteMemberRepository,
        diskCache: CommunityFeedDiskCache = CommunityFeedDiskCache()
    ) {
        self.service = service
        self.favorites = favorites
        self.diskCache = diskCache
    }

    func hydrateFromDisk() async {
        guard !hasHydrated else { return }
        hasHydrated = true
        let entries = await diskCache.load()
        for (key, entry) in entries {
            guard let filter = CommunityFeedFilter(rawValue: key) else { continue }
            cache[filter] = CachedFeed(
                favorites: entry.favorites,
                everyone: entry.everyone,
                nextCursor: entry.nextCursor
            )
        }
        if let cached = cache[filter] {
            favoritesRows = cached.favorites
            everyoneRows = cached.everyone
            nextCursor = cached.nextCursor
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
            favoritesRows = cached.favorites
            everyoneRows = cached.everyone
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
                favoritesRows = []
                everyoneRows = []
                nextCursor = nil
                state = .empty
                return
            }

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
                favoritesRows = sorted(favoritePage.rows)
                everyoneRows = sorted(everyonePage.rows)
                nextCursor = sort == .newest ? everyonePage.nextCursor : nil
                cache[.all] = CachedFeed(favorites: favoritesRows, everyone: everyoneRows, nextCursor: nextCursor)
                await persistCacheToDisk()
            case .favorites:
                let favoritePage = try await loadPage(
                    cursor: nil,
                    limit: 50,
                    authorIDsToInclude: favoriteIDs.isEmpty ? [] : favoriteIDs,
                    authorIDsToExclude: excludeSelf,
                    label: "favorites"
                )
                favoritesRows = []
                everyoneRows = sorted(favoritePage.rows)
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
                everyoneRows = sorted(minePage.rows)
                nextCursor = sort == .newest ? minePage.nextCursor : nil
                cache[.mine] = CachedFeed(favorites: [], everyone: everyoneRows, nextCursor: nextCursor)
                await persistCacheToDisk()
            }
            state = .loaded
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
            everyoneRows.append(contentsOf: sorted(page.rows))
            self.nextCursor = page.nextCursor
        } catch {
            state = .failed("Road Beans could not load more community visits.")
        }
    }

    func isFavorite(_ row: CommunityVisitRow) -> Bool {
        (try? favorites.contains(memberUserRecordID: row.authorUserRecordID)) ?? false
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
        case .comments:
            rows.sorted {
                if $0.commentCount == $1.commentCount {
                    return $0.publishedAt > $1.publishedAt
                }
                return $0.commentCount > $1.commentCount
            }
        }
    }
}
