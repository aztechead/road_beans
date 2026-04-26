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
        return response.mapItems.map(Self.draft(from:))
    }

    static func draft(from item: MKMapItem) -> MapKitPlaceDraft {
        let location = item.location

        return MapKitPlaceDraft(
            name: nonBlank(item.name) ?? "Place",
            kind: inferKind(from: item.pointOfInterestCategory),
            mapKitIdentifier: item.identifier?.rawValue,
            mapKitName: nonBlank(item.name),
            address: displayAddress(for: item),
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            phoneNumber: item.phoneNumber,
            websiteURL: item.url,
            streetNumber: nil,
            streetName: nil,
            city: item.addressRepresentations?.cityName,
            region: nil,
            postalCode: nil,
            country: item.addressRepresentations?.regionName
        )
    }

    private static func displayAddress(for item: MKMapItem) -> String? {
        nonBlank(item.address?.shortAddress)
            ?? nonBlank(item.address?.fullAddress)
            ?? nonBlank(item.addressRepresentations?.fullAddress(includingRegion: false, singleLine: true))
    }

    private static func nonBlank(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
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
    private let error: Error?

    init(canned: [MapKitPlaceDraft], error: Error? = nil) {
        self.canned = canned
        self.error = error
    }

    func search(query: String, near: CLLocationCoordinate2D?) async throws -> [MapKitPlaceDraft] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw LocationSearchError.empty }
        if let error { throw error }
        return canned
    }
}
