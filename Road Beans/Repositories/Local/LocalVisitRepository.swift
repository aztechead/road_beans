import Foundation
import SwiftData

@MainActor
final class LocalVisitRepository: VisitRepository {
    private let context: ModelContext
    private let sync: any RemoteSyncCoordinator
    private let places: any PlaceRepository
    private let tags: any TagRepository
    private let photos: any PhotoRepository
    private let tombstones: any TombstoneRepository
    private let photoProcessor: any PhotoProcessingService

    init(
        context: ModelContext,
        sync: any RemoteSyncCoordinator,
        places: any PlaceRepository,
        tags: any TagRepository,
        photos: any PhotoRepository,
        tombstones: any TombstoneRepository,
        photoProcessor: any PhotoProcessingService = DefaultPhotoProcessingService()
    ) {
        self.context = context
        self.sync = sync
        self.places = places
        self.tags = tags
        self.photos = photos
        self.tombstones = tombstones
        self.photoProcessor = photoProcessor
    }

    func save(_ command: CreateVisitCommand) async throws -> UUID {
        guard !command.drinks.isEmpty else { throw VisitValidationError.missingDrinks }

        let placeID = try await places.findOrCreate(reference: command.placeRef)
        let place = try fetchPlace(id: placeID)

        let visit = Visit()
        visit.date = command.date
        visit._place = place
        visit.lastModifiedAt = Date.now
        context.insert(visit)

        for draft in command.drinks {
            try await insertDrink(from: draft, into: visit)
        }

        try await replaceVisitTags(command.tags, on: visit)
        try context.save()

        for photo in command.photos {
            let processed = try await photoProcessor.process(photo.rawImageData)
            _ = try await photos.insertProcessed(processed, caption: photo.caption, into: visit.id)
        }

        await sync.markDirty(.visit, id: visit.id)
        await sync.markDirty(.place, id: place.id)
        return visit.id
    }

    func update(_ command: UpdateVisitCommand) async throws {
        let visit = try fetchVisit(id: command.id)

        if let date = command.date {
            visit.date = date
        }

        if let drinkDrafts = command.drinks {
            for drink in visit.drinks {
                context.delete(drink)
            }
            for draft in drinkDrafts {
                try await insertDrink(from: draft, into: visit)
            }
        }

        if let tagNames = command.tags {
            try await replaceVisitTags(tagNames, on: visit)
        }

        if let removals = command.photoRemovals {
            for photoID in removals {
                try await photos.remove(photoID)
            }
        }

        visit.lastModifiedAt = Date.now
        try context.save()

        if let additions = command.photoAdditions {
            for photo in additions {
                let processed = try await photoProcessor.process(photo.rawImageData)
                _ = try await photos.insertProcessed(processed, caption: photo.caption, into: visit.id)
            }
        }

        await sync.markDirty(.visit, id: visit.id)
    }

    func delete(_ command: DeleteVisitCommand) async throws {
        guard let visit = try fetchVisitIfExists(id: command.id) else { return }
        let id = visit.id
        let remoteID = visit.remoteID

        context.delete(visit)
        try context.save()
        try await tombstones.insertTombstone(entityKind: .visit, entityID: id, remoteID: remoteID)
    }

    func recentRows(limit: Int) async throws -> [RecentVisitRow] {
        var descriptor = FetchDescriptor<Visit>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor).map { visit in
            RecentVisitRow(
                visit: Self.toVisitRow(visit),
                placeName: visit.place?.name ?? "Unknown",
                placeKind: visit.place?.kind ?? .other,
                drinkNames: visit.drinks.map(\.name)
            )
        }
    }

    func detail(id: UUID) async throws -> VisitDetail? {
        guard let visit = try fetchVisitIfExists(id: id) else { return nil }
        let drinks = visit.drinks.map { drink in
            DrinkRow(
                id: drink.id,
                name: drink.name,
                category: drink.category,
                rating: drink.rating,
                tagNames: drink.tags.map(\.name)
            )
        }
        let photoRefs = visit.photos.map { photo in
            PhotoReference(
                id: photo.id,
                thumbnailData: photo.thumbnailData,
                widthPx: photo.widthPx,
                heightPx: photo.heightPx,
                caption: photo.caption
            )
        }

        return VisitDetail(
            id: visit.id,
            date: visit.date,
            placeID: visit.place?.id ?? UUID(),
            placeName: visit.place?.name ?? "Unknown",
            placeKind: visit.place?.kind ?? .other,
            drinks: drinks,
            tagNames: visit.tags.map(\.name),
            photos: photoRefs
        )
    }

    static func clampAndRound(_ raw: Double) -> Double {
        let clamped = min(max(raw, 0), 5)
        return (clamped * 10).rounded() / 10
    }

    private func insertDrink(from draft: DrinkDraft, into visit: Visit) async throws {
        let drink = Drink()
        drink.name = draft.name
        drink.category = draft.category
        drink.rating = Self.clampAndRound(draft.rating)
        drink._visit = visit
        drink.lastModifiedAt = Date.now
        context.insert(drink)

        var drinkTags: [Tag] = []
        for tagName in draft.tags {
            let tagID = try await tags.findOrCreate(name: tagName)
            drinkTags.append(try fetchTag(id: tagID))
        }
        drink._tags = drinkTags
        await sync.markDirty(.drink, id: drink.id)
    }

    private func replaceVisitTags(_ tagNames: [String], on visit: Visit) async throws {
        var visitTags: [Tag] = []
        for tagName in tagNames {
            let tagID = try await tags.findOrCreate(name: tagName)
            visitTags.append(try fetchTag(id: tagID))
        }
        visit._tags = visitTags
    }

    private func fetchPlace(id: UUID) throws -> Place {
        let predicate = #Predicate<Place> { $0.id == id }
        var descriptor = FetchDescriptor<Place>(predicate: predicate)
        descriptor.fetchLimit = 1
        guard let place = try context.fetch(descriptor).first else {
            throw VisitRepositoryError.notFound
        }
        return place
    }

    private func fetchTag(id: UUID) throws -> Tag {
        let predicate = #Predicate<Tag> { $0.id == id }
        var descriptor = FetchDescriptor<Tag>(predicate: predicate)
        descriptor.fetchLimit = 1
        guard let tag = try context.fetch(descriptor).first else {
            throw VisitRepositoryError.notFound
        }
        return tag
    }

    private func fetchVisit(id: UUID) throws -> Visit {
        guard let visit = try fetchVisitIfExists(id: id) else {
            throw VisitRepositoryError.notFound
        }
        return visit
    }

    private func fetchVisitIfExists(id: UUID) throws -> Visit? {
        let predicate = #Predicate<Visit> { $0.id == id }
        var descriptor = FetchDescriptor<Visit>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
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
}
