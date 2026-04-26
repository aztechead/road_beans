import CoreLocation
import Foundation

enum LocationAuthorization: Sendable, Equatable {
    case notDetermined
    case denied
    case restricted
    case authorized
}

protocol LocationPermissionService: AnyObject, Sendable {
    var status: LocationAuthorization { get async }
    func requestWhenInUse() async
    var statusChanges: AsyncStream<LocationAuthorization> { get }
}

final class SystemLocationPermissionService: NSObject, LocationPermissionService, CLLocationManagerDelegate, @unchecked Sendable {
    private let manager = CLLocationManager()
    private var continuation: AsyncStream<LocationAuthorization>.Continuation?
    let statusChanges: AsyncStream<LocationAuthorization>

    override init() {
        var continuation: AsyncStream<LocationAuthorization>.Continuation!
        self.statusChanges = AsyncStream { continuation = $0 }
        self.continuation = continuation
        super.init()
        manager.delegate = self
    }

    var status: LocationAuthorization {
        get async { Self.map(manager.authorizationStatus) }
    }

    func requestWhenInUse() async {
        manager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        continuation?.yield(Self.map(manager.authorizationStatus))
    }

    static func map(_ status: CLAuthorizationStatus) -> LocationAuthorization {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .authorizedAlways, .authorizedWhenInUse:
            return .authorized
        @unknown default:
            return .notDetermined
        }
    }
}

final class FakeLocationPermissionService: LocationPermissionService, @unchecked Sendable {
    private let lock = NSLock()
    private var current: LocationAuthorization
    private var continuations: [UUID: AsyncStream<LocationAuthorization>.Continuation] = [:]

    init(initial: LocationAuthorization) {
        current = initial
    }

    var status: LocationAuthorization {
        get async {
            lock.withLock { current }
        }
    }

    var statusChanges: AsyncStream<LocationAuthorization> {
        AsyncStream { continuation in
            let id = UUID()
            lock.withLock {
                continuations[id] = continuation
            }
            continuation.onTermination = { [weak self] _ in
                self?.lock.withLock {
                    self?.continuations[id] = nil
                }
            }
        }
    }

    func requestWhenInUse() async {
        simulateChange(.authorized)
    }

    func simulateChange(_ status: LocationAuthorization) {
        let targets = lock.withLock {
            current = status
            return Array(continuations.values)
        }
        for continuation in targets {
            continuation.yield(status)
        }
    }
}
