import SwiftUI

struct BeanPixelArt: View {
    let value: Double
    var basePixelSize: CGFloat = 3
    var minScale: CGFloat = 0.5
    var maxScale: CGFloat = 1.15
    var anchor: UnitPoint = .center

    private static let gridSize = 16

    var body: some View {
        Canvas(opaque: false, colorMode: .linear, rendersAsynchronously: false) { context, _ in
            drawBean(in: context)
        }
        .frame(
            width: basePixelSize * CGFloat(Self.gridSize),
            height: basePixelSize * CGFloat(Self.gridSize)
        )
        .scaleEffect(currentScale, anchor: anchor)
        .accessibilityHidden(true)
    }

    private var clampedValue: Double {
        min(max(value, 0), 5)
    }

    private var currentScale: CGFloat {
        let progress = CGFloat(clampedValue / 5.0)
        return minScale + (maxScale - minScale) * progress
    }

    private func drawBean(in context: GraphicsContext) {
        let bodyColor = Color(red: 0.45, green: 0.27, blue: 0.15)
        let highlightColor = Color(red: 0.62, green: 0.40, blue: 0.24)
        let seamColor = Color(red: 0.22, green: 0.12, blue: 0.06)

        var bodyMask: [[Bool]] = Array(
            repeating: Array(repeating: false, count: Self.gridSize),
            count: Self.gridSize
        )

        for y in 0..<Self.gridSize {
            for x in 0..<Self.gridSize {
                let nx = (Double(x) + 0.5 - 8.0) / 6.5
                let ny = (Double(y) + 0.5 - 8.0) / 7.0
                if nx * nx + ny * ny <= 1.0 {
                    bodyMask[y][x] = true
                    fillPixel(x: x, y: y, color: bodyColor, in: context)
                }
            }
        }

        let highlightPixels: [(Int, Int)] = [(5, 2), (4, 3), (3, 4), (2, 5), (2, 6)]
        for (x, y) in highlightPixels where bodyMask[y][x] {
            fillPixel(x: x, y: y, color: highlightColor, in: context)
        }

        for y in 1...14 {
            let t = Double(y - 7) / 7.0
            let seamX = 7.5 + sin(t * .pi) * 1.5
            let xPixel = Int(seamX.rounded())
            guard (0..<Self.gridSize).contains(xPixel) else { continue }
            if bodyMask[y][xPixel] {
                fillPixel(x: xPixel, y: y, color: seamColor, in: context)
            }
        }
    }

    private func fillPixel(x: Int, y: Int, color: Color, in context: GraphicsContext) {
        let rect = CGRect(
            x: CGFloat(x) * basePixelSize,
            y: CGFloat(y) * basePixelSize,
            width: basePixelSize,
            height: basePixelSize
        )
        context.fill(Path(rect), with: .color(color))
    }
}

#Preview {
    HStack(spacing: 12) {
        ForEach(0...5, id: \.self) { value in
            VStack {
                BeanPixelArt(value: Double(value))
                Text("\(value)")
            }
        }
    }
    .padding()
}
