import SwiftData
import Testing
import UIKit
@testable import Road_Beans

@Suite("DataExportService")
@MainActor
struct DataExportServiceTests {
    @Test func exportIncludesVersionedJsonAndCoreEntities() async throws {
        let stack = try makeStack()
        _ = try await stack.visits.save(
            CreateVisitCommand(
                placeRef: .newCustom(.init(name: "Backup Stop", kind: .coffeeShop, address: "Route 66")),
                date: RoadBeansSeedData.baseDate,
                drinks: [DrinkDraft(name: "Latte", category: .latte, rating: 4.2, tags: ["milk"])],
                tags: ["roadtrip"],
                photos: [PhotoDraft(rawImageData: makeImageData(), caption: "Cup")]
            )
        )

        let envelope = try await stack.export.exportEnvelope()

        #expect(envelope.schemaVersion == 1)
        #expect(envelope.places.map(\.name) == ["Backup Stop"])
        #expect(envelope.visits.first?.tagNames == ["roadtrip"])
        #expect(envelope.drinks.first?.name == "Latte")
        #expect(envelope.drinks.first?.tagNames == ["milk"])
        #expect(envelope.tags.map(\.name).sorted() == ["milk", "roadtrip"])
        #expect(envelope.photoMetadata.first?.caption == "Cup")

        let data = try RoadBeansExportEncoder.make().encode(envelope)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(RoadBeansExportEnvelope.self, from: data)
        #expect(decoded.schemaVersion == envelope.schemaVersion)
        #expect(decoded.places.map(\.name) == ["Backup Stop"])
        #expect(decoded.visits.first?.tagNames == ["roadtrip"])
        #expect(decoded.drinks.first?.name == "Latte")
        #expect(decoded.tags.map(\.name).sorted() == ["milk", "roadtrip"])
        #expect(decoded.photoMetadata.first?.caption == "Cup")
    }

    @Test func writeExportFileCreatesJsonFile() async throws {
        let stack = try makeStack()

        let url = try await stack.export.writeExportFile()

        #expect(url.lastPathComponent.hasPrefix("road-beans-export-"))
        #expect(url.pathExtension == "json")
        #expect(FileManager.default.fileExists(atPath: url.path))
    }

    private func makeStack() throws -> (
        visits: LocalVisitRepository,
        export: LocalDataExportService
    ) {
        let container = try ModelContainer(
            for: AppSchema.all,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let sync = LocalOnlyRemoteSync()
        let places = LocalPlaceRepository(context: context, sync: sync)
        let tags = LocalTagRepository(context: context, sync: sync)
        let photos = LocalPhotoRepository(context: context, sync: sync)
        let tombstones = LocalTombstoneRepository(context: context, sync: sync)
        let visits = LocalVisitRepository(
            context: context,
            sync: sync,
            places: places,
            tags: tags,
            photos: photos,
            tombstones: tombstones
        )
        return (visits, LocalDataExportService(context: context))
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
