import CoreLocation
import Foundation
import MapKit

enum LocationSearchError: Error, Equatable {
    case empty
    case noResults
}

protocol LocationSearchService: Sendable {
    func search(query: String, near: CLLocationCoordinate2D?) async throws -> [MapKitPlaceDraft]
}

final class SystemLocationSearchService: LocationSearchService, @unchecked Sendable {
    func search(query: String, near: CLLocationCoordinate2D?) async throws -> [MapKitPlaceDraft] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw LocationSearchError.empty }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        if let near {
            request.region = MKCoordinateRegion(
                center: near,
                latitudinalMeters: 50_000,
                longitudinalMeters: 50_000
            )
        }

        let response = try await MKLocalSearch(request: request).start()
        return response.mapItems.map(Self.toDraft(_:))
    }

    private static func toDraft(_ item: MKMapItem) -> MapKitPlaceDraft {
        let placemark = item.placemark
        let addressParts = [placemark.thoroughfare, placemark.locality, placemark.administrativeArea]
            .compactMap { $0 }
        let address = addressParts.isEmpty ? nil : addressParts.joined(separator: ", ")

        return MapKitPlaceDraft(
            name: item.name ?? placemark.name ?? "Place",
            kind: inferKind(from: item.pointOfInterestCategory),
            mapKitIdentifier: item.identifier?.rawValue,
            mapKitName: item.name,
            address: address,
            latitude: placemark.coordinate.latitude,
            longitude: placemark.coordinate.longitude,
            phoneNumber: item.phoneNumber,
            websiteURL: item.url,
            streetNumber: placemark.subThoroughfare,
            streetName: placemark.thoroughfare,
            city: placemark.locality,
            region: placemark.administrativeArea,
            postalCode: placemark.postalCode,
            country: placemark.country
        )
    }

    private static func inferKind(from category: MKPointOfInterestCategory?) -> PlaceKind {
        switch category {
        case .some(.gasStation), .some(.evCharger):
            return .gasStation
        case .some(.cafe), .some(.bakery):
            return .coffeeShop
        case .some(.restaurant), .some(.foodMarket):
            return .fastFood
        default:
            return .other
        }
    }
}

final class FakeLocationSearchService: LocationSearchService, @unchecked Sendable {
    private let canned: [MapKitPlaceDraft]

    init(canned: [MapKitPlaceDraft]) {
        self.canned = canned
    }

    func search(query: String, near: CLLocationCoordinate2D?) async throws -> [MapKitPlaceDraft] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw LocationSearchError.empty }
        return canned
    }
}
