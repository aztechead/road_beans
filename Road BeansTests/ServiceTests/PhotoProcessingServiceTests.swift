import ImageIO
import Testing
import UIKit
@testable import Road_Beans

@Suite("PhotoProcessingService")
struct PhotoProcessingServiceTests {
    func makeImage(width: Int, height: Int) -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
        let image = renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
        return image.pngData()!
    }

    @Test func smallImagePreserved() async throws {
        let service = DefaultPhotoProcessingService()
        let raw = makeImage(width: 800, height: 600)

        let output = try await service.process(raw)

        #expect(output.widthPx == 800)
        #expect(output.heightPx == 600)
        #expect(!output.imageData.isEmpty)
        #expect(!output.thumbnailData.isEmpty)
        #expect(imagePixelSize(output.thumbnailData).width <= 256)
        #expect(imagePixelSize(output.thumbnailData).height <= 256)
    }

    @Test func oversizedImageDownscaledToMaxLongEdge() async throws {
        let service = DefaultPhotoProcessingService()
        let raw = makeImage(width: 4096, height: 3072)

        let output = try await service.process(raw)

        #expect(output.widthPx == 2048)
        #expect(output.heightPx == 1536)
        #expect(max(imagePixelSize(output.imageData).width, imagePixelSize(output.imageData).height) <= 2048)
        #expect(max(imagePixelSize(output.thumbnailData).width, imagePixelSize(output.thumbnailData).height) <= 256)
    }

    @Test func invalidBytesThrow() async {
        let service = DefaultPhotoProcessingService()

        await #expect(throws: PhotoProcessingError.self) {
            _ = try await service.process(Data([0x00, 0x01, 0x02]))
        }
    }

    private func imagePixelSize(_ data: Data) -> (width: Int, height: Int) {
        guard
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
            let width = properties[kCGImagePropertyPixelWidth] as? Int,
            let height = properties[kCGImagePropertyPixelHeight] as? Int
        else {
            return (0, 0)
        }
        return (width, height)
    }
}
