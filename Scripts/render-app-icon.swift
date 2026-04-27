import AppKit
import Foundation

let sourceURL = URL(fileURLWithPath: "Scripts/road_beans_icon_source.png")
let outputURL = URL(fileURLWithPath: "Road Beans/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
let sourceCropSize = CGSize(width: 1074, height: 1074)
let outputSize = CGSize(width: 1024, height: 1024)

guard let source = NSImage(contentsOf: sourceURL) else {
    fatalError("Could not load icon source at \(sourceURL.path)")
}

let output = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(outputSize.width),
    pixelsHigh: Int(outputSize.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!
output.size = outputSize

let sourceSize = source.size
let sourceRect = CGRect(
    x: (sourceSize.width - sourceCropSize.width) / 2,
    y: (sourceSize.height - sourceCropSize.height) / 2,
    width: sourceCropSize.width,
    height: sourceCropSize.height
)

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: output)
source.draw(
    in: CGRect(origin: .zero, size: outputSize),
    from: sourceRect,
    operation: .copy,
    fraction: 1
)
NSGraphicsContext.restoreGraphicsState()

guard let data = output.representation(using: .png, properties: [:]) else {
    throw CocoaError(.fileWriteUnknown)
}

try data.write(to: outputURL)
