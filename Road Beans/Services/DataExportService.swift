import Foundation
import SwiftData

struct RoadBeansExportEnvelope: Codable, Equatable, Sendable {
    let schemaVersion: Int
    let exportedAt: Date
    let places: [ExportedPlace]
    let visits: [ExportedVisit]
    let drinks: [ExportedDrink]
    let tags: [ExportedTag]
    let photoMetadata: [ExportedPhotoMetadata]
}

struct ExportedPlace: Codable, Equatable, Sendable {
    let id: UUID
    let name: String
    let kind: PlaceKind
    let source: PlaceSource
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let createdAt: Date
    let lastModifiedAt: Date
}

struct ExportedVisit: Codable, Equatable, Sendable {
    let id: UUID
    let placeID: UUID?
    let date: Date
    let tagNames: [String]
    let createdAt: Date
    let lastModifiedAt: Date
}

struct ExportedDrink: Codable, Equatable, Sendable {
    let id: UUID
    let visitID: UUID?
    let name: String
    let category: DrinkCategory
    let rating: Double
    let tagNames: [String]
    let createdAt: Date
    let lastModifiedAt: Date
}

struct ExportedTag: Codable, Equatable, Sendable {
    let id: UUID
    let name: String
    let usageCount: Int
    let createdAt: Date
    let lastModifiedAt: Date
}

struct ExportedPhotoMetadata: Codable, Equatable, Sendable {
    let id: UUID
    let visitID: UUID?
    let caption: String?
    let widthPx: Int
    let heightPx: Int
    let createdAt: Date
    let lastModifiedAt: Date
}

protocol DataExportService: Sendable {
    func exportEnvelope() async throws -> RoadBeansExportEnvelope
    func writeExportFile() async throws -> URL
}

@MainActor
final class LocalDataExportService: DataExportService {
    private let context: ModelContext
    private let encoder: JSONEncoder

    init(context: ModelContext, encoder: JSONEncoder? = nil) {
        self.context = context
        self.encoder = encoder ?? RoadBeansExportEncoder.make()
    }

    func exportEnvelope() async throws -> RoadBeansExportEnvelope {
        let places = try context.fetch(FetchDescriptor<Place>(sortBy: [SortDescriptor(\.name)]))
        let visits = try context.fetch(FetchDescriptor<Visit>(sortBy: [SortDescriptor(\.date, order: .reverse)]))
        let drinks = try context.fetch(FetchDescriptor<Drink>(sortBy: [SortDescriptor(\.name)]))
        let tags = try context.fetch(FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name)]))
        let photos = try context.fetch(FetchDescriptor<VisitPhoto>(sortBy: [SortDescriptor(\.createdAt)]))

        return RoadBeansExportEnvelope(
            schemaVersion: 1,
            exportedAt: .now,
            places: places.map(Self.exportPlace(_:)),
            visits: visits.map(Self.exportVisit(_:)),
            drinks: drinks.map(Self.exportDrink(_:)),
            tags: tags.map(Self.exportTag(_:)),
            photoMetadata: photos.map(Self.exportPhoto(_:))
        )
    }

    func writeExportFile() async throws -> URL {
        let envelope = try await exportEnvelope()
        let data = try encoder.encode(envelope)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("road-beans-export-\(Self.fileDateFormatter.string(from: envelope.exportedAt)).json")
        try data.write(to: url, options: [.atomic])
        return url
    }

    private static func exportPlace(_ place: Place) -> ExportedPlace {
        ExportedPlace(
            id: place.id,
            name: place.name,
            kind: place.kind,
            source: place.source,
            address: place.address,
            latitude: place.latitude,
            longitude: place.longitude,
            createdAt: place.createdAt,
            lastModifiedAt: place.lastModifiedAt
        )
    }

    private static func exportVisit(_ visit: Visit) -> ExportedVisit {
        ExportedVisit(
            id: visit.id,
            placeID: visit.place?.id,
            date: visit.date,
            tagNames: visit.tags.map(\.name).sorted(),
            createdAt: visit.createdAt,
            lastModifiedAt: visit.lastModifiedAt
        )
    }

    private static func exportDrink(_ drink: Drink) -> ExportedDrink {
        ExportedDrink(
            id: drink.id,
            visitID: drink.visit?.id,
            name: drink.name,
            category: drink.category,
            rating: drink.rating,
            tagNames: drink.tags.map(\.name).sorted(),
            createdAt: drink.createdAt,
            lastModifiedAt: drink.lastModifiedAt
        )
    }

    private static func exportTag(_ tag: Tag) -> ExportedTag {
        ExportedTag(
            id: tag.id,
            name: tag.name,
            usageCount: tag.usageCount,
            createdAt: tag.createdAt,
            lastModifiedAt: tag.lastModifiedAt
        )
    }

    private static func exportPhoto(_ photo: VisitPhoto) -> ExportedPhotoMetadata {
        ExportedPhotoMetadata(
            id: photo.id,
            visitID: photo.visit?.id,
            caption: photo.caption,
            widthPx: photo.widthPx,
            heightPx: photo.heightPx,
            createdAt: photo.createdAt,
            lastModifiedAt: photo.lastModifiedAt
        )
    }

    private static let fileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}

enum RoadBeansExportEncoder {
    static func make() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
