import Foundation
import ImageIO
import UniformTypeIdentifiers
import UIKit

enum PhotoProcessingError: Error {
    case invalidImage
    case encodingFailed
}

struct ProcessedPhoto: Sendable {
    let imageData: Data
    let thumbnailData: Data
    let widthPx: Int
    let heightPx: Int
}

protocol PhotoProcessingService: Sendable {
    nonisolated func process(_ raw: Data) async throws -> ProcessedPhoto
}

final class DefaultPhotoProcessingService: PhotoProcessingService, @unchecked Sendable {
    private nonisolated static let mainMaxEdge: CGFloat = 2048
    private nonisolated static let thumbnailMaxEdge: CGFloat = 256

    nonisolated init() {}

    nonisolated func process(_ raw: Data) async throws -> ProcessedPhoto {
        try await Task.detached(priority: .userInitiated) {
            guard let image = UIImage(data: raw) else {
                throw PhotoProcessingError.invalidImage
            }

            let resized = Self.resize(image, maxEdge: Self.mainMaxEdge)
            let thumbnail = Self.resize(image, maxEdge: Self.thumbnailMaxEdge)

            guard let imageData = Self.encodeHEIC(resized) ?? resized.jpegData(compressionQuality: 0.85) else {
                throw PhotoProcessingError.encodingFailed
            }
            guard let thumbnailData = thumbnail.jpegData(compressionQuality: 0.7) else {
                throw PhotoProcessingError.encodingFailed
            }

            return ProcessedPhoto(
                imageData: imageData,
                thumbnailData: thumbnailData,
                widthPx: Int(resized.size.width * resized.scale),
                heightPx: Int(resized.size.height * resized.scale)
            )
        }.value
    }

    private nonisolated static func resize(_ image: UIImage, maxEdge: CGFloat) -> UIImage {
        let width = image.size.width
        let height = image.size.height
        let longestEdge = max(width, height)
        guard longestEdge > maxEdge else { return image }

        let scale = maxEdge / longestEdge
        let newSize = CGSize(width: floor(width * scale), height: floor(height * scale))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private nonisolated static func encodeHEIC(_ image: UIImage) -> Data? {
        guard let cgImage = image.cgImage else { return nil }

        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.heic.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }

        let options = [kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary
        CGImageDestinationAddImage(destination, cgImage, options)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }
}
