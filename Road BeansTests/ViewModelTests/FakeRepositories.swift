import CoreLocation
import Foundation
@testable import Road_Beans

final class FakePlaceRepository: PlaceRepository, @unchecked Sendable {
    var stored: [PlaceSummary] = []
    var details: [UUID: PlaceDetail] = [:]

    func findOrCreate(reference: PlaceReference) async throws -> UUID {
        UUID()
    }

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

final class FakeVisitRepository: VisitRepository, @unchecked Sendable {
    var recents: [RecentVisitRow] = []
    var saved: [CreateVisitCommand] = []
    var deletedIDs: [UUID] = []

    func save(_ command: CreateVisitCommand) async throws -> UUID {
        saved.append(command)
        return UUID()
    }

    func update(_ command: UpdateVisitCommand) async throws {}

    func delete(_ command: DeleteVisitCommand) async throws {
        deletedIDs.append(command.id)
    }

    func recentRows(limit: Int) async throws -> [RecentVisitRow] {
        Array(recents.prefix(limit))
    }

    func detail(id: UUID) async throws -> VisitDetail? {
        nil
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
