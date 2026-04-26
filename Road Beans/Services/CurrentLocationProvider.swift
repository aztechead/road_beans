import CoreLocation
import Foundation

enum CurrentLocationError: Error, Equatable {
    case unavailable
}

struct CurrentLocationSnapshot: Equatable, Sendable {
    static let maximumAge: TimeInterval = 10 * 60
    static let maximumHorizontalAccuracy: CLLocationAccuracy = 5_000

    let coordinate: CLLocationCoordinate2D
    let horizontalAccuracy: CLLocationAccuracy
    let timestamp: Date

    var isUsableFallback: Bool {
        timestamp.timeIntervalSinceNow >= -Self.maximumAge
            && horizontalAccuracy >= 0
            && horizontalAccuracy <= Self.maximumHorizontalAccuracy
    }

    static func == (lhs: CurrentLocationSnapshot, rhs: CurrentLocationSnapshot) -> Bool {
        lhs.coordinate.latitude == rhs.coordinate.latitude
            && lhs.coordinate.longitude == rhs.coordinate.longitude
            && lhs.horizontalAccuracy == rhs.horizontalAccuracy
            && lhs.timestamp == rhs.timestamp
    }
}

protocol CurrentLocationProvider: Sendable {
    func currentLocation() async throws -> CurrentLocationSnapshot
}

extension CurrentLocationProvider {
    func currentCoordinate() async throws -> CLLocationCoordinate2D {
        try await currentLocation().coordinate
    }
}

final class SystemCurrentLocationProvider: NSObject, CurrentLocationProvider, CLLocationManagerDelegate, @unchecked Sendable {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CurrentLocationSnapshot, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func currentLocation() async throws -> CurrentLocationSnapshot {
        if let fallback = manager.location?.snapshot, fallback.isUsableFallback {
            return fallback
        }

        do {
            return try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                manager.requestLocation()
            }
        } catch {
            if let fallback = manager.location?.snapshot, fallback.isUsableFallback {
                return fallback
            }
            throw error
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let snapshot = locations.last?.snapshot else {
            resume(with: .failure(CurrentLocationError.unavailable))
            return
        }

        resume(with: .success(snapshot))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        resume(with: .failure(error))
    }

    private func resume(with result: Result<CurrentLocationSnapshot, Error>) {
        guard let continuation else { return }
        self.continuation = nil

        switch result {
        case .success(let coordinate):
            continuation.resume(returning: coordinate)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }
}

struct FakeCurrentLocationProvider: CurrentLocationProvider {
    var snapshot: CurrentLocationSnapshot?

    init(coordinate: CLLocationCoordinate2D?) {
        snapshot = coordinate.map {
            CurrentLocationSnapshot(
                coordinate: $0,
                horizontalAccuracy: 25,
                timestamp: .now
            )
        }
    }

    init(snapshot: CurrentLocationSnapshot?) {
        self.snapshot = snapshot
    }

    func currentLocation() async throws -> CurrentLocationSnapshot {
        guard let snapshot else { throw CurrentLocationError.unavailable }
        return snapshot
    }
}

private extension CLLocation {
    var snapshot: CurrentLocationSnapshot {
        CurrentLocationSnapshot(
            coordinate: coordinate,
            horizontalAccuracy: horizontalAccuracy,
            timestamp: timestamp
        )
    }
}
