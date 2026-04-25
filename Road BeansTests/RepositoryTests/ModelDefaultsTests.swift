import CoreLocation
import Foundation
import SwiftData
import Testing
@testable import Road_Beans

@Suite("Model defaults")
@MainActor
struct ModelDefaultsTests {
    func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: AppSchema.all,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test func placeDefaults() throws {
        let context = try makeContext()
        let place = Place()
        context.insert(place)
        #expect(place.kind == .other)
        #expect(place.source == .custom)
        #expect(place.syncState == .pendingUpload)
        #expect(place.remoteID == nil)
        #expect(place.visits.isEmpty)
    }

    @Test func visitDefaults() throws {
        let context = try makeContext()
        let visit = Visit()
        context.insert(visit)
        #expect(visit.drinks.isEmpty)
        #expect(visit.tags.isEmpty)
        #expect(visit.photos.isEmpty)
        #expect(visit.syncState == .pendingUpload)
    }

    @Test func drinkDefaults() throws {
        let context = try makeContext()
        let drink = Drink()
        context.insert(drink)
        #expect(drink.category == .other)
        #expect(drink.rating == 3.0)
        #expect(drink.tags.isEmpty)
    }

    @Test func tagDefaults() throws {
        let context = try makeContext()
        let tag = Tag()
        context.insert(tag)
        #expect(tag.name == "")
        #expect(tag.usageCount == 0)
    }

    @Test func visitPhotoDefaults() throws {
        let context = try makeContext()
        let photo = VisitPhoto()
        context.insert(photo)
        #expect(photo.imageData.isEmpty)
        #expect(photo.thumbnailData.isEmpty)
        #expect(photo.widthPx == 0)
        #expect(photo.heightPx == 0)
    }

    @Test func tombstoneDefaults() throws {
        let context = try makeContext()
        let tombstone = Tombstone(entityKind: "visit", entityID: UUID())
        context.insert(tombstone)
        #expect(tombstone.syncState == .pendingUpload)
        #expect(tombstone.remoteID == nil)
    }

    @Test func placeCoordinateDerivesFromLatLng() {
        let place = Place()
        place.latitude = 34.5
        place.longitude = -112.5
        #expect(place.coordinate?.latitude == 34.5)
        #expect(place.coordinate?.longitude == -112.5)

        let placeWithoutCoordinate = Place()
        #expect(placeWithoutCoordinate.coordinate == nil)
    }
}
