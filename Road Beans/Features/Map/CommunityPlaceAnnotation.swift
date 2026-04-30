import CoreLocation
import Foundation

struct CommunityPlaceAnnotation: Identifiable, Sendable {
    let id: String
    let name: String
    let kind: PlaceKind
    let coordinate: CLLocationCoordinate2D
    let averageRating: Double
    let reviewCount: Int
    let reviews: [CommunityVisitRow]

    static func group(from rows: [CommunityVisitRow]) -> [CommunityPlaceAnnotation] {
        var groups: [String: [CommunityVisitRow]] = [:]
        for row in rows {
            guard let lat = row.placeLatitude, let lon = row.placeLongitude else { continue }
            let key = groupKey(for: row, latitude: lat, longitude: lon)
            groups[key, default: []].append(row)
        }
        return groups.compactMap { key, rows in
            guard let first = rows.first,
                  let lat = first.placeLatitude,
                  let lon = first.placeLongitude else { return nil }
            let kind = PlaceKind(rawValue: first.placeKindRawValue) ?? .other
            let average = rows.map(\.beanRating).reduce(0, +) / Double(rows.count)
            return CommunityPlaceAnnotation(
                id: first.placeMapKitIdentifier ?? key,
                name: first.placeName,
                kind: kind,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                averageRating: average,
                reviewCount: rows.count,
                reviews: rows.sorted { $0.visitDate > $1.visitDate }
            )
        }
    }

    private static func groupKey(for row: CommunityVisitRow, latitude: Double, longitude: Double) -> String {
        if let identifier = row.placeMapKitIdentifier, !identifier.isEmpty {
            return "mapkit:\(identifier)"
        }

        let normalizedName = row.placeName
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let roundedLatitude = (latitude * 1_000).rounded() / 1_000
        let roundedLongitude = (longitude * 1_000).rounded() / 1_000
        return "place:\(normalizedName):\(roundedLatitude):\(roundedLongitude)"
    }
}

extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: latitude, longitude: longitude)
            .distance(from: CLLocation(latitude: other.latitude, longitude: other.longitude))
    }
}
