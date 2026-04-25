import Foundation

struct PlaceDTO: Codable, Hashable, Sendable {
    let id: UUID
    let remoteID: String?
    let lastModifiedAt: Date
    let name: String
    let kind: String
    let source: String
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
    let createdAt: Date
}
