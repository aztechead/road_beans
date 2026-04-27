import CoreLocation
import Foundation

struct CommunityPlaceAnnotation: Identifiable, Sendable {
    let id: String
    let name: String
    let kind: PlaceKind
    let coordinate: CLLocationCoordinate2D
    let averageRating: Double

    static func group(from rows: [CommunityVisitRow]) -> [CommunityPlaceAnnotation] {
        var groups: [String: [CommunityVisitRow]] = [:]
        for row in rows {
            guard let lat = row.placeLatitude, let lon = row.placeLongitude else { continue }
            let key = row.placeMapKitIdentifier ?? "\(lat),\(lon)"
            groups[key, default: []].append(row)
        }
        return groups.compactMap { key, rows in
            guard let first = rows.first,
                  let lat = first.placeLatitude,
                  let lon = first.placeLongitude else { return nil }
            let kind = PlaceKind(rawValue: first.placeKindRawValue) ?? .other
            let average = rows.map(\.beanRating).reduce(0, +) / Double(rows.count)
            return CommunityPlaceAnnotation(
                id: key,
                name: first.placeName,
                kind: kind,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                averageRating: average
            )
        }
    }
}

extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: latitude, longitude: longitude)
            .distance(from: CLLocation(latitude: other.latitude, longitude: other.longitude))
    }
}
