import CoreLocation
import SwiftData
import Testing
@testable import Road_Beans

@Suite("LocalPlaceRepository")
@MainActor
struct LocalPlaceRepositoryTests {
    func makeRepo() throws -> (LocalPlaceRepository, ModelContext, LocalOnlyRemoteSync, LocalTombstoneRepository) {
        let container = try ModelContainer(
            for: AppSchema.all,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let sync = LocalOnlyRemoteSync()
        let tombstones = LocalTombstoneRepository(context: context, sync: sync)
        return (LocalPlaceRepository(context: context, sync: sync, tombstones: tombstones), context, sync, tombstones)
    }

    @Test func existingReferenceReturnsIDWithoutDirtyMark() async throws {
        let (repo, _, sync, _) = try makeRepo()
        let id = UUID()

        let returned = try await repo.findOrCreate(reference: .existing(id: id))

        #expect(returned == id)
        #expect(await sync.recordedCalls.isEmpty)
    }

    @Test func mapKitIdentifierMatchReuses() async throws {
        let (repo, _, sync, _) = try makeRepo()
        let draft = mapKitDraft(name: "Love's", mapKitIdentifier: "mk-1")

        let id1 = try await repo.findOrCreate(reference: .newMapKit(draft))
        let id2 = try await repo.findOrCreate(reference: .newMapKit(draft))

        #expect(id1 == id2)
        #expect(await sync.recordedCalls == [.init(kind: .place, id: id1)])
    }

    @Test func nilIdentifierMatchesByNameAnd49MeterProximity() async throws {
        let (repo, _, _, _) = try makeRepo()
        let base = mapKitDraft(name: "QT", mapKitIdentifier: nil, latitude: 0, longitude: 0)
        let nearby = mapKitDraft(name: "qt", mapKitIdentifier: nil, latitude: 0, longitude: longitudeOffset(forMetersAtEquator: 49))

        let id1 = try await repo.findOrCreate(reference: .newMapKit(base))
        let id2 = try await repo.findOrCreate(reference: .newMapKit(nearby))

        #expect(id1 == id2)
    }

    @Test func nilIdentifierBeyond51MetersInserts() async throws {
        let (repo, _, _, _) = try makeRepo()
        let base = mapKitDraft(name: "QT", mapKitIdentifier: nil, latitude: 0, longitude: 0)
        let beyond = mapKitDraft(name: "QT", mapKitIdentifier: nil, latitude: 0, longitude: longitudeOffset(forMetersAtEquator: 51))

        let id1 = try await repo.findOrCreate(reference: .newMapKit(base))
        let id2 = try await repo.findOrCreate(reference: .newMapKit(beyond))

        #expect(id1 != id2)
    }

    @Test func nilIdentifierDifferentNameDoesNotMerge() async throws {
        let (repo, _, _, _) = try makeRepo()
        let base = mapKitDraft(name: "QT", mapKitIdentifier: nil, latitude: 0, longitude: 0)
        let nearbyDifferentName = mapKitDraft(name: "Love's", mapKitIdentifier: nil, latitude: 0, longitude: longitudeOffset(forMetersAtEquator: 20))

        let id1 = try await repo.findOrCreate(reference: .newMapKit(base))
        let id2 = try await repo.findOrCreate(reference: .newMapKit(nearbyDifferentName))

        #expect(id1 != id2)
    }

    @Test func customNeverMerges() async throws {
        let (repo, _, sync, _) = try makeRepo()
        let draft = CustomPlaceDraft(name: "My Stop", kind: .other, address: nil)

        let id1 = try await repo.findOrCreate(reference: .newCustom(draft))
        let id2 = try await repo.findOrCreate(reference: .newCustom(draft))

        #expect(id1 != id2)
        #expect(await sync.recordedCalls.count == 2)
    }

    @Test func summariesAndDetailComputeAverageRatings() async throws {
        let (repo, context, _, _) = try makeRepo()
        let id = try await repo.findOrCreate(
            reference: .newMapKit(mapKitDraft(name: "Coffee Stop", mapKitIdentifier: "mk-rating"))
        )
        let place = try #require(try fetchPlace(id: id, context: context))
        addVisit(to: place, ratings: [5, 3], context: context)
        addVisit(to: place, ratings: [4], context: context)
        try context.save()

        let summary = try #require(try await repo.summaries().first { $0.id == id })
        let detail = try #require(try await repo.detail(id: id))

        #expect(summary.averageRating == 4)
        #expect(summary.visitCount == 2)
        #expect(detail.averageRating == 4)
        #expect(detail.visits.map(\.drinkCount).sorted() == [1, 2])
    }

    @Test func summariesNearFiltersByRadius() async throws {
        let (repo, _, _, _) = try makeRepo()
        let nearID = try await repo.findOrCreate(
            reference: .newMapKit(mapKitDraft(name: "Near", mapKitIdentifier: "near", latitude: 0, longitude: 0))
        )
        let farID = try await repo.findOrCreate(
            reference: .newMapKit(mapKitDraft(name: "Far", mapKitIdentifier: "far", latitude: 0, longitude: longitudeOffset(forMetersAtEquator: 100)))
        )

        let summaries = try await repo.summariesNear(
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            radiusMeters: 60
        )

        #expect(summaries.map(\.id).contains(nearID))
        #expect(!summaries.map(\.id).contains(farID))
    }

    @Test func updateChangesEditableFieldsAndMarksDirty() async throws {
        let (repo, _, sync, _) = try makeRepo()
        let id = try await repo.findOrCreate(
            reference: .newCustom(CustomPlaceDraft(name: "Old", kind: .truckStop, address: nil))
        )

        try await repo.update(
            UpdatePlaceCommand(
                id: id,
                name: "New",
                kind: .coffeeShop,
                address: "1 Main"
            )
        )

        let detail = try #require(try await repo.detail(id: id))
        #expect(detail.name == "New")
        #expect(detail.kind == .coffeeShop)
        #expect(detail.address == "1 Main")
        #expect(await sync.recordedCalls.contains(.init(kind: .place, id: id)))
    }

    @Test func deleteRemovesPlaceAndWritesTombstone() async throws {
        let (repo, _, _, tombstones) = try makeRepo()
        let id = try await repo.findOrCreate(
            reference: .newCustom(CustomPlaceDraft(name: "Delete Me", kind: .truckStop, address: nil))
        )

        try await repo.delete(DeletePlaceCommand(id: id))

        #expect(try await repo.detail(id: id) == nil)
        let tombstone = try #require(try await tombstones.all().first)
        #expect(tombstone.entityKind == SyncEntityKind.place.rawValue)
        #expect(tombstone.entityID == id)
    }

    private func mapKitDraft(
        name: String,
        mapKitIdentifier: String?,
        latitude: Double? = 34,
        longitude: Double? = -112
    ) -> MapKitPlaceDraft {
        MapKitPlaceDraft(
            name: name,
            kind: .truckStop,
            mapKitIdentifier: mapKitIdentifier,
            mapKitName: name,
            address: nil,
            latitude: latitude,
            longitude: longitude,
            phoneNumber: nil,
            websiteURL: nil,
            streetNumber: nil,
            streetName: nil,
            city: nil,
            region: nil,
            postalCode: nil,
            country: nil
        )
    }

    private func longitudeOffset(forMetersAtEquator meters: Double) -> Double {
        meters / 111_319.9
    }

    private func fetchPlace(id: UUID, context: ModelContext) throws -> Place? {
        let predicate = #Predicate<Place> { $0.id == id }
        var descriptor = FetchDescriptor<Place>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func addVisit(to place: Place, ratings: [Double], context: ModelContext) {
        let visit = Visit()
        visit._place = place
        context.insert(visit)

        for rating in ratings {
            let drink = Drink()
            drink.name = "Coffee"
            drink.rating = rating
            drink._visit = visit
            context.insert(drink)
        }
    }
}
