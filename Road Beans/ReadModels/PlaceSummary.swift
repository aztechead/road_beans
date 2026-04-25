import CoreLocation
import Foundation

struct PlaceSummary: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let kind: PlaceKind
    let address: String?
    let coordinate: CLLocationCoordinate2D?
    let averageRating: Double?
    let visitCount: Int

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: PlaceSummary, rhs: PlaceSummary) -> Bool {
        lhs.id == rhs.id
    }
}
