import CoreLocation
import Foundation
import SwiftData

@Model
final class Place {
    var id: UUID = UUID()
    var name: String = ""
    var kind: PlaceKind = PlaceKind.other
    var source: PlaceSource = PlaceSource.custom
    var address: String?
    var mapKitName: String?
    var mapKitIdentifier: String?
    var latitude: Double?
    var longitude: Double?
    var phoneNumber: String?
    var websiteURL: URL?
    var streetNumber: String?
    var streetName: String?
    var city: String?
    var region: String?
    var postalCode: String?
    var country: String?
    var createdAt: Date = Date.now
    var lastModifiedAt: Date = Date.now

    var remoteID: String?
    var syncState: SyncState = SyncState.pendingUpload
    var authorIdentifier: String?

    @Relationship(deleteRule: .cascade, inverse: \Visit._place)
    var _visits: [Visit]? = []

    init() {}
}

extension Place {
    var visits: [Visit] {
        _visits ?? []
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
