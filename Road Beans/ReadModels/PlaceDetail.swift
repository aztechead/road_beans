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
    let coordinate: CLLocationCoordinate2D?
    let averageRating: Double?
    let visits: [VisitRow]

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: PlaceDetail, rhs: PlaceDetail) -> Bool {
        lhs.id == rhs.id
    }
}
