import Foundation

enum PlaceReference: Hashable, Sendable {
    case existing(id: UUID)
    case newMapKit(MapKitPlaceDraft)
    case newCustom(CustomPlaceDraft)
}

struct MapKitPlaceDraft: Hashable, Sendable {
    let name: String
    let kind: PlaceKind
    let mapKitIdentifier: String?
    let mapKitName: String?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let phoneNumber: String?
    let websiteURL: URL?
    let streetNumber: String?
    let streetName: String?
    let city: String?
    let region: String?
    let postalCode: String?
    let country: String?
}

struct CustomPlaceDraft: Hashable, Sendable {
    let name: String
    let kind: PlaceKind
    let address: String?
}
