import CoreLocation
import Foundation

#if DEBUG
enum AppStoreScreenshotMode {
    static let environmentKey = "ROAD_BEANS_APP_STORE_SCREENSHOTS"

    static var isEnabled: Bool {
        ProcessInfo.processInfo.environment[environmentKey] == "1"
    }

    static func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: OnboardingState.storageKey)
    }

    static func makePlaceRepository() -> ScreenshotPlaceRepository {
        let repository = ScreenshotPlaceRepository()
        repository.stored = RoadBeansSeedData.places
        repository.details = RoadBeansSeedData.placeDetails
        return repository
    }

    static func makeVisitRepository() -> ScreenshotVisitRepository {
        let repository = ScreenshotVisitRepository()
        repository.recents = RoadBeansSeedData.recentVisits
        repository.details = RoadBeansSeedData.visitDetails
        return repository
    }

    static func makeCommunityService() -> InMemoryCommunityService {
        InMemoryCommunityService(
            currentUserRecordID: "screenshot-user",
            members: communityMembers,
            visits: communityRows
        )
    }

    private static var communityMembers: [CommunityMemberSnapshot] {
        [
            CommunityMemberSnapshot(
                userRecordID: "screenshot-user",
                displayName: "Meld Mini",
                tasteProfile: tasteProfile(roast: 0.28, flavor: 0.72, notes: 0.58, body: 0.66),
                joinedAt: RoadBeansSeedData.baseDate.addingTimeInterval(-60 * 60 * 24 * 14)
            ),
            CommunityMemberSnapshot(
                userRecordID: "mara",
                displayName: "Mara",
                tasteProfile: tasteProfile(roast: 0.62, flavor: 0.48, notes: 0.54, body: 0.36),
                joinedAt: RoadBeansSeedData.baseDate.addingTimeInterval(-60 * 60 * 24 * 42)
            ),
            CommunityMemberSnapshot(
                userRecordID: "jo",
                displayName: "Jo",
                tasteProfile: tasteProfile(roast: 0.18, flavor: 0.82, notes: 0.42, body: 0.76),
                joinedAt: RoadBeansSeedData.baseDate.addingTimeInterval(-60 * 60 * 24 * 31)
            )
        ]
    }

    private static var communityRows: [CommunityVisitRow] {
        [
            CommunityVisitRow(
                id: "community-loves-drip",
                authorUserRecordID: "mara",
                authorDisplayName: "Mara",
                authorTasteProfile: communityMembers[1].tasteProfile,
                placeName: "Loves Travel Stop",
                placeKindRawValue: PlaceKind.truckStop.rawValue,
                placeMapKitIdentifier: nil,
                placeLatitude: 35.219,
                placeLongitude: -112.482,
                visitDate: RoadBeansSeedData.baseDate,
                beanRating: 4.2,
                drinkSummary: "House Drip (Drip)",
                tagSummary: "smooth, roadtrip",
                publishedAt: RoadBeansSeedData.baseDate.addingTimeInterval(60 * 8),
                likeCount: 12,
                commentCount: 3
            ),
            CommunityVisitRow(
                id: "community-diner-latte",
                authorUserRecordID: "jo",
                authorDisplayName: "Jo",
                authorTasteProfile: communityMembers[2].tasteProfile,
                placeName: "Sunrise Diner Coffee",
                placeKindRawValue: PlaceKind.coffeeShop.rawValue,
                placeMapKitIdentifier: nil,
                placeLatitude: 35.191,
                placeLongitude: -112.401,
                visitDate: RoadBeansSeedData.baseDate.addingTimeInterval(-7_200),
                beanRating: 3.7,
                drinkSummary: "Road Latte (Latte)",
                tagSummary: "breakfast, mellow",
                publishedAt: RoadBeansSeedData.baseDate.addingTimeInterval(60 * 3),
                likeCount: 7,
                commentCount: 1
            )
        ]
    }

    private static func tasteProfile(roast: Double, flavor: Double, notes: Double, body: Double) -> TasteProfile {
        TasteProfile(
            axes: [
                TasteAxis.roast.rawValue: roast,
                TasteAxis.flavor.rawValue: flavor,
                TasteAxis.notes.rawValue: notes,
                TasteAxis.body.rawValue: body
            ]
        )
    }
}

final class ScreenshotPlaceRepository: PlaceRepository, @unchecked Sendable {
    var stored: [PlaceSummary] = []
    var details: [UUID: PlaceDetail] = [:]

    func findOrCreate(reference: PlaceReference) async throws -> UUID {
        switch reference {
        case .existing(let id):
            id
        case .newMapKit(let draft):
            stored.first { $0.name == draft.name }?.id ?? UUID()
        case .newCustom(let draft):
            stored.first { $0.name == draft.name }?.id ?? UUID()
        }
    }

    func update(_ command: UpdatePlaceCommand) async throws {}

    func delete(_ command: DeletePlaceCommand) async throws {}

    func summaries() async throws -> [PlaceSummary] {
        stored
    }

    func summariesNear(coordinate: CLLocationCoordinate2D, radiusMeters: Double) async throws -> [PlaceSummary] {
        stored
    }

    func detail(id: UUID) async throws -> PlaceDetail? {
        details[id]
    }
}

final class ScreenshotVisitRepository: VisitRepository, @unchecked Sendable {
    var recents: [RecentVisitRow] = []
    var details: [UUID: VisitDetail] = [:]

    func save(_ command: CreateVisitCommand) async throws -> UUID {
        UUID()
    }

    func update(_ command: UpdateVisitCommand) async throws {}

    func delete(_ command: DeleteVisitCommand) async throws {}

    func recentRows(limit: Int) async throws -> [RecentVisitRow] {
        Array(recents.prefix(limit))
    }

    func detail(id: UUID) async throws -> VisitDetail? {
        details[id]
    }

    func communityDraft(for visitID: UUID) async throws -> CommunityVisitDraft? {
        guard let detail = details[visitID] else { return nil }
        let ratingTotal = detail.drinks.reduce(0) { $0 + $1.rating }
        return CommunityVisitDraft(
            localVisitID: detail.id,
            placeName: detail.placeName,
            placeKindRawValue: detail.placeKind.rawValue,
            placeMapKitIdentifier: nil,
            placeLatitude: nil,
            placeLongitude: nil,
            visitDate: detail.date,
            beanRating: detail.drinks.isEmpty ? 0 : ratingTotal / Double(detail.drinks.count),
            drinkSummary: detail.drinks.map { "\($0.name) (\($0.category.displayName))" }.joined(separator: ", "),
            tagSummary: detail.tagNames.joined(separator: ", ")
        )
    }
}
#endif
