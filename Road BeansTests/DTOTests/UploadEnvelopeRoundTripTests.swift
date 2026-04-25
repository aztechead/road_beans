import Foundation
import Testing
@testable import Road_Beans

@Suite("UploadEnvelope round-trip")
struct UploadEnvelopeRoundTripTests {
    @Test func envelopeRoundTripsLosslessly() throws {
        let placeID = UUID()
        let visitID = UUID()
        let drinkID = UUID()
        let tagID = UUID()
        let photoID = UUID()
        let tombstoneEntityID = UUID()
        let date = Date(timeIntervalSince1970: 1_750_000_000)

        let envelope = UploadEnvelope(
            schemaVersion: 1,
            exportedAt: date,
            authorIdentifier: nil,
            places: [.init(
                id: placeID,
                remoteID: nil,
                lastModifiedAt: date,
                name: "Loves",
                kind: PlaceKind.truckStop.rawValue,
                source: PlaceSource.mapKit.rawValue,
                mapKitIdentifier: "mk-123",
                mapKitName: "Love's Travel Stop",
                address: "I-17 Exit 262, Cordes Junction, AZ",
                latitude: 34.32,
                longitude: -112.12,
                phoneNumber: "555-1212",
                websiteURL: URL(string: "https://loves.com"),
                streetNumber: "1",
                streetName: "Frontage Rd",
                city: "Cordes Junction",
                region: "AZ",
                postalCode: "86333",
                country: "USA",
                createdAt: date
            )],
            visits: [.init(
                id: visitID,
                remoteID: nil,
                placeID: placeID,
                date: date,
                lastModifiedAt: date,
                createdAt: date
            )],
            drinks: [.init(
                id: drinkID,
                remoteID: nil,
                visitID: visitID,
                name: "CFHB",
                category: DrinkCategory.drip.rawValue,
                rating: 4.2,
                lastModifiedAt: date,
                createdAt: date
            )],
            tags: [.init(
                id: tagID,
                remoteID: nil,
                name: "smooth",
                lastModifiedAt: date,
                createdAt: date
            )],
            visitPhotos: [.init(
                id: photoID,
                remoteID: nil,
                visitID: visitID,
                caption: "morning",
                widthPx: 2048,
                heightPx: 1536,
                assetReference: "blob://\(photoID)",
                lastModifiedAt: date,
                createdAt: date
            )],
            visitTagAssignments: [.init(tagID: tagID, entityID: visitID)],
            drinkTagAssignments: [.init(tagID: tagID, entityID: drinkID)],
            tombstones: [.init(
                id: UUID(),
                entityKind: "drink",
                entityID: tombstoneEntityID,
                remoteID: nil,
                deletedAt: date
            )]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(envelope)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(UploadEnvelope.self, from: data)

        #expect(decoded == envelope)

        let visit = try #require(decoded.visits.first)
        #expect(decoded.places.contains { $0.id == visit.placeID })

        let drink = try #require(decoded.drinks.first)
        #expect(decoded.visits.contains { $0.id == drink.visitID })
    }
}
