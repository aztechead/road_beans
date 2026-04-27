import CoreLocation
import Foundation

struct PlaceDetail: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let kind: PlaceKind
    let source: PlaceSource
    let address: String?
    let streetNumber: String?
    let streetName: String?
    let city: String?
    let region: String?
    let postalCode: String?
    let country: String?
    let phoneNumber: String?
    let websiteURL: URL?
    let mapKitIdentifier: String?
    let latitude: Double?
    let longitude: Double?
    let coordinate: CLLocationCoordinate2D?
    let averageRating: Double?
    let visits: [VisitRow]

    init(
        id: UUID,
        name: String,
        kind: PlaceKind,
        source: PlaceSource,
        address: String?,
        streetNumber: String?,
        streetName: String?,
        city: String?,
        region: String?,
        postalCode: String?,
        country: String?,
        phoneNumber: String?,
        websiteURL: URL?,
        mapKitIdentifier: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        coordinate: CLLocationCoordinate2D?,
        averageRating: Double?,
        visits: [VisitRow]
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.source = source
        self.address = address
        self.streetNumber = streetNumber
        self.streetName = streetName
        self.city = city
        self.region = region
        self.postalCode = postalCode
        self.country = country
        self.phoneNumber = phoneNumber
        self.websiteURL = websiteURL
        self.mapKitIdentifier = mapKitIdentifier
        self.latitude = latitude
        self.longitude = longitude
        self.coordinate = coordinate
        self.averageRating = averageRating
        self.visits = visits
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: PlaceDetail, rhs: PlaceDetail) -> Bool {
        lhs.id == rhs.id
    }
}
