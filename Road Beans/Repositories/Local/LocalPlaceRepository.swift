import CoreLocation
import Foundation
import SwiftData

@MainActor
final class LocalPlaceRepository: PlaceRepository {
    private let context: ModelContext
    private let sync: any RemoteSyncCoordinator
    private let tombstones: any TombstoneRepository

    init(context: ModelContext, sync: any RemoteSyncCoordinator, tombstones: any TombstoneRepository) {
        self.context = context
        self.sync = sync
        self.tombstones = tombstones
    }

    func findOrCreate(reference: PlaceReference) async throws -> UUID {
        switch reference {
        case .existing(let id):
            return id

        case .newMapKit(let draft):
            if let existing = try existingMapKitPlace(for: draft) {
                return existing.id
            }

            let place = Self.makePlace(from: draft)
            context.insert(place)
            try context.save()
            await sync.markDirty(.place, id: place.id)
            return place.id

        case .newCustom(let draft):
            let place = Place()
            place.name = draft.name
            place.kind = draft.kind
            place.source = .custom
            place.address = draft.address
            context.insert(place)
            try context.save()
            await sync.markDirty(.place, id: place.id)
            return place.id
        }
    }

    func update(_ command: UpdatePlaceCommand) async throws {
        let id = command.id
        let predicate = #Predicate<Place> { $0.id == id }
        var descriptor = FetchDescriptor<Place>(predicate: predicate)
        descriptor.fetchLimit = 1

        guard let place = try context.fetch(descriptor).first else {
            throw VisitRepositoryError.notFound
        }

        place.name = command.name
        place.kind = command.kind
        place.address = command.address
        place.lastModifiedAt = Date.now
        try context.save()
        await sync.markDirty(.place, id: place.id)
    }

    func delete(_ command: DeletePlaceCommand) async throws {
        guard let place = try fetchPlace(id: command.id) else { return }
        let id = place.id
        let remoteID = place.remoteID

        context.delete(place)
        try context.save()
        try await tombstones.insertTombstone(entityKind: .place, entityID: id, remoteID: remoteID)
    }

    func summaries() async throws -> [PlaceSummary] {
        let descriptor = FetchDescriptor<Place>(
            sortBy: [SortDescriptor(\.lastModifiedAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map(Self.toSummary(_:))
    }

    func summariesNear(coordinate: CLLocationCoordinate2D, radiusMeters: Double) async throws -> [PlaceSummary] {
        let places = try context.fetch(FetchDescriptor<Place>())
        return places.compactMap { place in
            guard let latitude = place.latitude, let longitude = place.longitude else { return nil }
            let distance = Self.distanceMeters(coordinate.latitude, coordinate.longitude, latitude, longitude)
            return distance <= radiusMeters ? Self.toSummary(place) : nil
        }
    }

    func detail(id: UUID) async throws -> PlaceDetail? {
        guard let place = try fetchPlace(id: id) else { return nil }

        let visits = place.visits
            .sorted { $0.date > $1.date }
            .map(Self.toVisitRow(_:))
        let drinks = place.visits.flatMap(\.drinks)

        return PlaceDetail(
            id: place.id,
            name: place.name,
            kind: place.kind,
            source: place.source,
            address: place.address,
            streetNumber: place.streetNumber,
            streetName: place.streetName,
            city: place.city,
            region: place.region,
            postalCode: place.postalCode,
            country: place.country,
            phoneNumber: place.phoneNumber,
            websiteURL: place.websiteURL,
            mapKitIdentifier: place.mapKitIdentifier,
            latitude: place.latitude,
            longitude: place.longitude,
            coordinate: place.coordinate,
            averageRating: Self.averageRating(for: drinks),
            visits: visits
        )
    }

    private func existingMapKitPlace(for draft: MapKitPlaceDraft) throws -> Place? {
        if let identifier = draft.mapKitIdentifier {
            let predicate = #Predicate<Place> { $0.mapKitIdentifier == identifier }
            var descriptor = FetchDescriptor<Place>(predicate: predicate)
            descriptor.fetchLimit = 1
            return try context.fetch(descriptor).first
        }

        guard let latitude = draft.latitude, let longitude = draft.longitude else { return nil }

        let normalizedName = draft.name.lowercased()
        let candidates = try context.fetch(FetchDescriptor<Place>())
        return candidates.first { place in
            guard
                place.name.lowercased() == normalizedName,
                let placeLatitude = place.latitude,
                let placeLongitude = place.longitude
            else {
                return false
            }

            return Self.distanceMeters(latitude, longitude, placeLatitude, placeLongitude) < 50
        }
    }

    private func fetchPlace(id: UUID) throws -> Place? {
        let predicate = #Predicate<Place> { $0.id == id }
        var descriptor = FetchDescriptor<Place>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private static func makePlace(from draft: MapKitPlaceDraft) -> Place {
        let place = Place()
        place.name = draft.name
        place.kind = draft.kind
        place.source = .mapKit
        place.mapKitIdentifier = draft.mapKitIdentifier
        place.mapKitName = draft.mapKitName
        place.address = draft.address
        place.latitude = draft.latitude
        place.longitude = draft.longitude
        place.phoneNumber = draft.phoneNumber
        place.websiteURL = draft.websiteURL
        place.streetNumber = draft.streetNumber
        place.streetName = draft.streetName
        place.city = draft.city
        place.region = draft.region
        place.postalCode = draft.postalCode
        place.country = draft.country
        return place
    }

    private static func toSummary(_ place: Place) -> PlaceSummary {
        let drinks = place.visits.flatMap(\.drinks)
        return PlaceSummary(
            id: place.id,
            name: place.name,
            kind: place.kind,
            address: place.address,
            coordinate: place.coordinate,
            averageRating: averageRating(for: drinks),
            visitCount: place.visits.count
        )
    }

    private static func toVisitRow(_ visit: Visit) -> VisitRow {
        VisitRow(
            id: visit.id,
            date: visit.date,
            drinkCount: visit.drinks.count,
            tagNames: visit.tags.map(\.name),
            photoCount: visit.photos.count,
            averageRating: averageRating(for: visit.drinks)
        )
    }

    private static func averageRating(for drinks: [Drink]) -> Double? {
        guard !drinks.isEmpty else { return nil }
        return drinks.map(\.rating).reduce(0, +) / Double(drinks.count)
    }

    static func distanceMeters(_ lat1: Double, _ lng1: Double, _ lat2: Double, _ lng2: Double) -> Double {
        let location1 = CLLocation(latitude: lat1, longitude: lng1)
        let location2 = CLLocation(latitude: lat2, longitude: lng2)
        return location1.distance(from: location2)
    }
}
