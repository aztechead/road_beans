import Foundation

enum PhotoRepositoryError: Error, Equatable {
    case visitNotFound
}

protocol PhotoRepository: Sendable {
    func insertProcessed(_ processed: ProcessedPhoto, caption: String?, into visitID: UUID) async throws -> UUID
    func remove(_ photoID: UUID) async throws
}
