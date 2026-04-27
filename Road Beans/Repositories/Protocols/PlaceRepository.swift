import CoreLocation
import Foundation

protocol PlaceRepository: Sendable {
    func findOrCreate(reference: PlaceReference) async throws -> UUID
    func update(_ command: UpdatePlaceCommand) async throws
    func delete(_ command: DeletePlaceCommand) async throws
    func summaries() async throws -> [PlaceSummary]
    func summariesNear(coordinate: CLLocationCoordinate2D, radiusMeters: Double) async throws -> [PlaceSummary]
    func detail(id: UUID) async throws -> PlaceDetail?
}
