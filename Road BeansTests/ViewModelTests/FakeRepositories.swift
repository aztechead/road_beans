import CoreLocation
import Foundation
@testable import Road_Beans

final class FakePlaceRepository: PlaceRepository, @unchecked Sendable {
    var stored: [PlaceSummary] = []
    var details: [UUID: PlaceDetail] = [:]
    var createdReferences: [PlaceReference] = []
    var createdID = UUID()
    var summariesNearCalls: [(coordinate: CLLocationCoordinate2D, radiusMeters: Double)] = []
    var updates: [UpdatePlaceCommand] = []
    var deletedIDs: [UUID] = []
    var summariesError: Error?
    var detailError: Error?

    func findOrCreate(reference: PlaceReference) async throws -> UUID {
        createdReferences.append(reference)
        return createdID
    }

    func update(_ command: UpdatePlaceCommand) async throws {
        updates.append(command)
    }

    func delete(_ command: DeletePlaceCommand) async throws {
        deletedIDs.append(command.id)
    }

    func summaries() async throws -> [PlaceSummary] {
        if let summariesError { throw summariesError }
        return stored
    }

    func summariesNear(coordinate: CLLocationCoordinate2D, radiusMeters: Double) async throws -> [PlaceSummary] {
        if let summariesError { throw summariesError }
        summariesNearCalls.append((coordinate, radiusMeters))
        return stored
    }

    func detail(id: UUID) async throws -> PlaceDetail? {
        if let detailError { throw detailError }
        return details[id]
    }
}

final class FakeVisitRepository: VisitRepository, @unchecked Sendable {
    var recents: [RecentVisitRow] = []
    var details: [UUID: VisitDetail] = [:]
    var saved: [CreateVisitCommand] = []
    var updated: [UpdateVisitCommand] = []
    var deletedIDs: [UUID] = []
    var recentsError: Error?
    var detailError: Error?

    func save(_ command: CreateVisitCommand) async throws -> UUID {
        saved.append(command)
        return UUID()
    }

    func update(_ command: UpdateVisitCommand) async throws {
        updated.append(command)
    }

    func delete(_ command: DeleteVisitCommand) async throws {
        deletedIDs.append(command.id)
    }

    func recentRows(limit: Int) async throws -> [RecentVisitRow] {
        if let recentsError { throw recentsError }
        return Array(recents.prefix(limit))
    }

    func detail(id: UUID) async throws -> VisitDetail? {
        if let detailError { throw detailError }
        return details[id]
    }

    func communityDraft(for visitID: UUID) async throws -> CommunityVisitDraft? {
        guard let detail = try await detail(id: visitID) else { return nil }
        return CommunityVisitDraft(
            localVisitID: detail.id,
            placeName: detail.placeName,
            placeKindRawValue: detail.placeKind.rawValue,
            placeMapKitIdentifier: nil,
            placeLatitude: nil,
            placeLongitude: nil,
            visitDate: detail.date,
            beanRating: detail.drinks.isEmpty ? 0 : detail.drinks.reduce(0) { $0 + $1.rating } / Double(detail.drinks.count),
            drinkSummary: detail.drinks.map { "\($0.name) (\($0.category.displayName))" }.joined(separator: ", "),
            tagSummary: detail.tagNames.joined(separator: ", ")
        )
    }
}

final class FakeTagRepository: TagRepository, @unchecked Sendable {
    var byName: [String: UUID] = [:]
    var suggestionsList: [TagSuggestion] = []

    func findOrCreate(name: String) async throws -> UUID {
        let normalized = LocalTagRepository.normalize(name)
        if let existing = byName[normalized] {
            return existing
        }

        let id = UUID()
        byName[normalized] = id
        return id
    }

    func suggestions(prefix: String, limit: Int) async throws -> [TagSuggestion] {
        let normalized = prefix.lowercased()
        return suggestionsList.filter { $0.name.hasPrefix(normalized) }.prefix(limit).map { $0 }
    }

    func all() async throws -> [TagSuggestion] {
        suggestionsList
    }
}

final class FakePhotoRepository: PhotoRepository, @unchecked Sendable {
    func insertProcessed(_ processed: ProcessedPhoto, caption: String?, into visitID: UUID) async throws -> UUID {
        UUID()
    }

    func remove(_ photoID: UUID) async throws {}
}

final class FakeTombstoneRepository: TombstoneRepository, @unchecked Sendable {
    var inserted: [TombstoneDTO] = []

    func insertTombstone(entityKind: SyncEntityKind, entityID: UUID, remoteID: String?) async throws {
        inserted.append(
            TombstoneDTO(
                id: UUID(),
                entityKind: entityKind.rawValue,
                entityID: entityID,
                remoteID: remoteID,
                deletedAt: .now
            )
        )
    }

    func all() async throws -> [TombstoneDTO] {
        inserted
    }
}
