import SwiftData
import Testing
import UIKit
@testable import Road_Beans

@Suite("LocalVisitRepository")
@MainActor
struct LocalVisitRepositoryTests {
    func makeStack() throws -> (
        LocalVisitRepository,
        LocalPlaceRepository,
        LocalTagRepository,
        LocalPhotoRepository,
        LocalTombstoneRepository,
        LocalOnlyRemoteSync,
        ModelContext
    ) {
        let container = try ModelContainer(
            for: AppSchema.all,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let sync = LocalOnlyRemoteSync()
        let tombstones = LocalTombstoneRepository(context: context, sync: sync)
        let places = LocalPlaceRepository(context: context, sync: sync, tombstones: tombstones)
        let tags = LocalTagRepository(context: context, sync: sync)
        let photos = LocalPhotoRepository(context: context, sync: sync)
        let visits = LocalVisitRepository(
            context: context,
            sync: sync,
            places: places,
            tags: tags,
            photos: photos,
            tombstones: tombstones
        )
        return (visits, places, tags, photos, tombstones, sync, context)
    }

    @Test func emptyDrinksRejected() async throws {
        let (visits, _, _, _, _, _, _) = try makeStack()
        let command = CreateVisitCommand(
            placeRef: .newCustom(.init(name: "X", kind: .other, address: nil)),
            date: Date.now,
            drinks: [],
            tags: [],
            photos: []
        )

        await #expect(throws: VisitValidationError.self) {
            _ = try await visits.save(command)
        }
    }

    @Test func ratingClampedAndRounded() async throws {
        let (visits, _, _, _, _, _, context) = try makeStack()
        let command = CreateVisitCommand(
            placeRef: .newCustom(.init(name: "X", kind: .other, address: nil)),
            date: Date.now,
            drinks: [
                DrinkDraft(name: "A", category: .drip, rating: 5.7, tags: []),
                DrinkDraft(name: "B", category: .drip, rating: -3, tags: []),
                DrinkDraft(name: "C", category: .drip, rating: 3.47, tags: []),
            ],
            tags: [],
            photos: []
        )

        let visitID = try await visits.save(command)
        let visit = try #require(try fetchVisit(id: visitID, context: context))
        let ratings = visit.drinks.map(\.rating).sorted()

        #expect(ratings.contains(0))
        #expect(ratings.contains(5))
        #expect(ratings.contains { abs($0 - 3.5) < 0.0001 })
    }

    @Test func saveMarksAllExpectedEntities() async throws {
        let (visits, _, _, _, _, sync, _) = try makeStack()
        let command = CreateVisitCommand(
            placeRef: .newCustom(.init(name: "X", kind: .other, address: nil)),
            date: Date.now,
            drinks: [DrinkDraft(name: "D", category: .drip, rating: 4, tags: ["smooth"])],
            tags: ["roadtrip"],
            photos: [PhotoDraft(rawImageData: makeImageData(), caption: "Cup")]
        )

        _ = try await visits.save(command)

        let kinds = Set(await sync.recordedCalls.map(\.kind))
        #expect(kinds.contains(.place))
        #expect(kinds.contains(.visit))
        #expect(kinds.contains(.drink))
        #expect(kinds.contains(.tag))
        #expect(kinds.contains(.visitPhoto))
    }

    @Test func updateReplacesDrinksTagsAndAddsRemovesPhotos() async throws {
        let (visits, _, _, _, _, _, context) = try makeStack()
        let id = try await visits.save(
            CreateVisitCommand(
                placeRef: .newCustom(.init(name: "X", kind: .other, address: nil)),
                date: Date.now,
                drinks: [DrinkDraft(name: "D", category: .drip, rating: 4, tags: [])],
                tags: [],
                photos: [PhotoDraft(rawImageData: makeImageData(), caption: "Old")]
            )
        )
        let oldPhotoID = try #require(try fetchVisit(id: id, context: context)?.photos.first?.id)

        try await visits.update(
            UpdateVisitCommand(
                id: id,
                date: nil,
                tags: ["updated"],
                drinks: [DrinkDraft(name: "Latte", category: .espresso, rating: 4.24, tags: ["milk"])],
                photoAdditions: [PhotoDraft(rawImageData: makeImageData(), caption: "New")],
                photoRemovals: [oldPhotoID]
            )
        )

        let detail = try #require(try await visits.detail(id: id))
        #expect(detail.drinks.map(\.name) == ["Latte"])
        #expect(detail.drinks.first?.rating == 4.2)
        #expect(detail.tagNames == ["updated"])
        #expect(detail.photos.count == 1)
        #expect(detail.photos.first?.caption == "New")
    }

    @Test func deleteWritesTombstone() async throws {
        let (visits, _, _, _, tombstones, _, _) = try makeStack()
        let command = CreateVisitCommand(
            placeRef: .newCustom(.init(name: "X", kind: .other, address: nil)),
            date: Date.now,
            drinks: [DrinkDraft(name: "D", category: .drip, rating: 4, tags: [])],
            tags: [],
            photos: []
        )

        let id = try await visits.save(command)
        try await visits.delete(.init(id: id))

        let all = try await tombstones.all()
        #expect(all.contains { $0.entityKind == "visit" && $0.entityID == id })
    }

    @Test func recentRowsAndDetailExposeReadModels() async throws {
        let (visits, _, _, _, _, _, _) = try makeStack()
        let id = try await visits.save(
            CreateVisitCommand(
                placeRef: .newCustom(.init(name: "Read Model", kind: .coffeeShop, address: nil)),
                date: Date.now,
                drinks: [DrinkDraft(name: "D", category: .drip, rating: 4, tags: [])],
                tags: ["stop"],
                photos: []
            )
        )

        let rows = try await visits.recentRows(limit: 10)
        let detail = try #require(try await visits.detail(id: id))

        #expect(rows.first?.visit.id == id)
        #expect(rows.first?.placeName == "Read Model")
        #expect(rows.first?.placeKind == .coffeeShop)
        #expect(detail.placeName == "Read Model")
        #expect(detail.drinks.count == 1)
    }

    private func fetchVisit(id: UUID, context: ModelContext) throws -> Visit? {
        let predicate = #Predicate<Visit> { $0.id == id }
        var descriptor = FetchDescriptor<Visit>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func makeImageData() -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 16, height: 16), format: format)
        return renderer.image { context in
            UIColor.brown.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 16, height: 16))
        }.pngData()!
    }
}
