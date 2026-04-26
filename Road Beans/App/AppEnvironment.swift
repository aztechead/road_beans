import CoreLocation
import Foundation
import SwiftUI

private enum MissingEnvironmentDependencyError: Error {
    case missing(String)
}

// MARK: - Environment Keys

private struct PlaceRepositoryKey: EnvironmentKey {
    static let defaultValue: any PlaceRepository = MissingPlaceRepository()
}

private struct VisitRepositoryKey: EnvironmentKey {
    static let defaultValue: any VisitRepository = MissingVisitRepository()
}

private struct TagRepositoryKey: EnvironmentKey {
    static let defaultValue: any TagRepository = MissingTagRepository()
}

private struct PhotoRepositoryKey: EnvironmentKey {
    static let defaultValue: any PhotoRepository = MissingPhotoRepository()
}

private struct TombstoneRepositoryKey: EnvironmentKey {
    static let defaultValue: any TombstoneRepository = MissingTombstoneRepository()
}

private struct LocationSearchServiceKey: EnvironmentKey {
    static let defaultValue: any LocationSearchService = MissingLocationSearchService()
}

private struct LocationPermissionServiceKey: EnvironmentKey {
    static let defaultValue: any LocationPermissionService = MissingLocationPermissionService()
}

private struct CurrentLocationProviderKey: EnvironmentKey {
    static let defaultValue: any CurrentLocationProvider = MissingCurrentLocationProvider()
}

private struct PhotoProcessingServiceKey: EnvironmentKey {
    static let defaultValue: any PhotoProcessingService = MissingPhotoProcessingService()
}

private struct ICloudAvailabilityServiceKey: EnvironmentKey {
    static var defaultValue: any iCloudAvailabilityServiceProtocol = FakeICloudAvailabilityService()
}

private struct RemoteSyncCoordinatorKey: EnvironmentKey {
    static let defaultValue: any RemoteSyncCoordinator = NoopRemoteSyncCoordinator()
}

extension EnvironmentValues {
    var placeRepository: any PlaceRepository {
        get { self[PlaceRepositoryKey.self] }
        set { self[PlaceRepositoryKey.self] = newValue }
    }

    var visitRepository: any VisitRepository {
        get { self[VisitRepositoryKey.self] }
        set { self[VisitRepositoryKey.self] = newValue }
    }

    var tagRepository: any TagRepository {
        get { self[TagRepositoryKey.self] }
        set { self[TagRepositoryKey.self] = newValue }
    }

    var photoRepository: any PhotoRepository {
        get { self[PhotoRepositoryKey.self] }
        set { self[PhotoRepositoryKey.self] = newValue }
    }

    var tombstoneRepository: any TombstoneRepository {
        get { self[TombstoneRepositoryKey.self] }
        set { self[TombstoneRepositoryKey.self] = newValue }
    }

    var locationSearchService: any LocationSearchService {
        get { self[LocationSearchServiceKey.self] }
        set { self[LocationSearchServiceKey.self] = newValue }
    }

    var locationPermissionService: any LocationPermissionService {
        get { self[LocationPermissionServiceKey.self] }
        set { self[LocationPermissionServiceKey.self] = newValue }
    }

    var currentLocationProvider: any CurrentLocationProvider {
        get { self[CurrentLocationProviderKey.self] }
        set { self[CurrentLocationProviderKey.self] = newValue }
    }

    var photoProcessingService: any PhotoProcessingService {
        get { self[PhotoProcessingServiceKey.self] }
        set { self[PhotoProcessingServiceKey.self] = newValue }
    }

    var iCloudAvailability: any iCloudAvailabilityServiceProtocol {
        get { self[ICloudAvailabilityServiceKey.self] }
        set { self[ICloudAvailabilityServiceKey.self] = newValue }
    }

    var remoteSyncCoordinator: any RemoteSyncCoordinator {
        get { self[RemoteSyncCoordinatorKey.self] }
        set { self[RemoteSyncCoordinatorKey.self] = newValue }
    }
}

private struct MissingPlaceRepository: PlaceRepository {
    func findOrCreate(reference: PlaceReference) async throws -> UUID {
        throw MissingEnvironmentDependencyError.missing("PlaceRepository")
    }

    func summaries() async throws -> [PlaceSummary] {
        throw MissingEnvironmentDependencyError.missing("PlaceRepository")
    }

    func summariesNear(coordinate: CLLocationCoordinate2D, radiusMeters: Double) async throws -> [PlaceSummary] {
        throw MissingEnvironmentDependencyError.missing("PlaceRepository")
    }

    func detail(id: UUID) async throws -> PlaceDetail? {
        throw MissingEnvironmentDependencyError.missing("PlaceRepository")
    }
}

private struct MissingVisitRepository: VisitRepository {
    func save(_ command: CreateVisitCommand) async throws -> UUID {
        throw MissingEnvironmentDependencyError.missing("VisitRepository")
    }

    func update(_ command: UpdateVisitCommand) async throws {
        throw MissingEnvironmentDependencyError.missing("VisitRepository")
    }

    func delete(_ command: DeleteVisitCommand) async throws {
        throw MissingEnvironmentDependencyError.missing("VisitRepository")
    }

    func recentRows(limit: Int) async throws -> [RecentVisitRow] {
        throw MissingEnvironmentDependencyError.missing("VisitRepository")
    }

    func detail(id: UUID) async throws -> VisitDetail? {
        throw MissingEnvironmentDependencyError.missing("VisitRepository")
    }
}

private struct MissingTagRepository: TagRepository {
    func findOrCreate(name: String) async throws -> UUID {
        throw MissingEnvironmentDependencyError.missing("TagRepository")
    }

    func suggestions(prefix: String, limit: Int) async throws -> [TagSuggestion] {
        throw MissingEnvironmentDependencyError.missing("TagRepository")
    }

    func all() async throws -> [TagSuggestion] {
        throw MissingEnvironmentDependencyError.missing("TagRepository")
    }
}

private struct MissingPhotoRepository: PhotoRepository {
    func insertProcessed(_ processed: ProcessedPhoto, caption: String?, into visitID: UUID) async throws -> UUID {
        throw MissingEnvironmentDependencyError.missing("PhotoRepository")
    }

    func remove(_ photoID: UUID) async throws {
        throw MissingEnvironmentDependencyError.missing("PhotoRepository")
    }
}

private struct MissingTombstoneRepository: TombstoneRepository {
    func insertTombstone(entityKind: SyncEntityKind, entityID: UUID, remoteID: String?) async throws {
        throw MissingEnvironmentDependencyError.missing("TombstoneRepository")
    }

    func all() async throws -> [TombstoneDTO] {
        throw MissingEnvironmentDependencyError.missing("TombstoneRepository")
    }
}

private struct MissingLocationSearchService: LocationSearchService {
    func search(query: String, near: CLLocationCoordinate2D?) async throws -> [MapKitPlaceDraft] {
        throw MissingEnvironmentDependencyError.missing("LocationSearchService")
    }
}

private final class MissingLocationPermissionService: LocationPermissionService, @unchecked Sendable {
    var status: LocationAuthorization {
        get async { .denied }
    }

    var statusChanges: AsyncStream<LocationAuthorization> {
        AsyncStream { $0.finish() }
    }

    func requestWhenInUse() async {}
}

private struct MissingCurrentLocationProvider: CurrentLocationProvider {
    func currentCoordinate() async throws -> CLLocationCoordinate2D {
        throw MissingEnvironmentDependencyError.missing("CurrentLocationProvider")
    }
}

private struct MissingPhotoProcessingService: PhotoProcessingService {
    nonisolated func process(_ raw: Data) async throws -> ProcessedPhoto {
        throw MissingEnvironmentDependencyError.missing("PhotoProcessingService")
    }
}

private actor NoopRemoteSyncCoordinator: RemoteSyncCoordinator {
    func markDirty(_ kind: SyncEntityKind, id: UUID) async {}
}
