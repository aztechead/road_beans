import SwiftUI

// MARK: - Stub protocol forward declarations
// Replace each stub with its real protocol as the corresponding task lands.
#if STUB_REPOSITORY_PROTOCOLS_NOT_YET_DEFINED
protocol PlaceRepository: Sendable {}
protocol VisitRepository: Sendable {}
protocol TagRepository: Sendable {}
protocol PhotoRepository: Sendable {}
protocol TombstoneRepository: Sendable {}
protocol LocationSearchService: Sendable {}
protocol LocationPermissionService: Sendable {}
protocol PhotoProcessingService: Sendable {}
protocol RemoteSyncCoordinator: Sendable {}
#endif

// MARK: - Environment Keys

private struct PlaceRepositoryKey: EnvironmentKey {
    static var defaultValue: any PlaceRepository { fatalError("PlaceRepository must be injected") }
}

private struct VisitRepositoryKey: EnvironmentKey {
    static var defaultValue: any VisitRepository { fatalError("VisitRepository must be injected") }
}

private struct TagRepositoryKey: EnvironmentKey {
    static var defaultValue: any TagRepository { fatalError("TagRepository must be injected") }
}

private struct PhotoRepositoryKey: EnvironmentKey {
    static var defaultValue: any PhotoRepository { fatalError("PhotoRepository must be injected") }
}

private struct TombstoneRepositoryKey: EnvironmentKey {
    static var defaultValue: any TombstoneRepository { fatalError("TombstoneRepository must be injected") }
}

private struct LocationSearchServiceKey: EnvironmentKey {
    static var defaultValue: any LocationSearchService { fatalError("LocationSearchService must be injected") }
}

private struct LocationPermissionServiceKey: EnvironmentKey {
    static var defaultValue: any LocationPermissionService { fatalError("LocationPermissionService must be injected") }
}

private struct PhotoProcessingServiceKey: EnvironmentKey {
    static var defaultValue: any PhotoProcessingService { fatalError("PhotoProcessingService must be injected") }
}

private struct ICloudAvailabilityServiceKey: EnvironmentKey {
    static var defaultValue: any iCloudAvailabilityServiceProtocol = FakeICloudAvailabilityService()
}

private struct RemoteSyncCoordinatorKey: EnvironmentKey {
    static var defaultValue: any RemoteSyncCoordinator { fatalError("RemoteSyncCoordinator must be injected") }
}

private struct PersistenceControllerKey: EnvironmentKey {
    static var defaultValue: PersistenceController { fatalError("PersistenceController must be injected") }
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

    var persistenceController: PersistenceController {
        get { self[PersistenceControllerKey.self] }
        set { self[PersistenceControllerKey.self] = newValue }
    }
}
