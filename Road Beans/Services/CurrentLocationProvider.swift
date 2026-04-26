import CoreLocation
import Foundation

enum CurrentLocationError: Error, Equatable {
    case unavailable
}

protocol CurrentLocationProvider: Sendable {
    func currentCoordinate() async throws -> CLLocationCoordinate2D
}

final class SystemCurrentLocationProvider: NSObject, CurrentLocationProvider, CLLocationManagerDelegate, @unchecked Sendable {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocationCoordinate2D, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func currentCoordinate() async throws -> CLLocationCoordinate2D {
        if let location = manager.location {
            return location.coordinate
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else {
            resume(with: .failure(CurrentLocationError.unavailable))
            return
        }

        resume(with: .success(coordinate))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        resume(with: .failure(error))
    }

    private func resume(with result: Result<CLLocationCoordinate2D, Error>) {
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
    var coordinate: CLLocationCoordinate2D?

    func currentCoordinate() async throws -> CLLocationCoordinate2D {
        guard let coordinate else { throw CurrentLocationError.unavailable }
        return coordinate
    }
}
