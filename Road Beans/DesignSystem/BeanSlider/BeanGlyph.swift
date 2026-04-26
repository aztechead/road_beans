import SwiftUI

struct BeanGlyph: View {
    let beanCount: Int
    var pixelSize: CGFloat = 4

    static func beanCount(for value: Double) -> Int {
        min(max(Int(value.rounded(.down)), 0), 5)
    }

    var body: some View {
        Canvas(opaque: false, colorMode: .linear, rendersAsynchronously: false) { context, _ in
            drawCup(in: context)
            drawBeans(in: context)
        }
        .frame(width: pixelSize * 16, height: pixelSize * 16)
        .accessibilityHidden(true)
    }

    private var clampedBeanCount: Int {
        min(max(beanCount, 0), 5)
    }

    private func drawCup(in context: GraphicsContext) {
        let cupColor = Color.brown

        for x in 2...13 {
            for y in 5...13 where x == 2 || x == 13 || y == 5 || y == 13 {
                fillPixel(x: x, y: y, color: cupColor, in: context)
            }
        }

        for y in 7...10 {
            fillPixel(x: 14, y: y, color: cupColor, in: context)
        }
    }

    private func drawBeans(in context: GraphicsContext) {
        let slots = [(4, 8), (7, 7), (10, 8), (5, 11), (10, 11)]
        let beanColor = Color(red: 0.30, green: 0.18, blue: 0.10)

        for index in 0..<clampedBeanCount {
            let (centerX, centerY) = slots[index]
            for dx in 0...1 {
                for dy in 0...1 {
                    fillPixel(x: centerX + dx, y: centerY + dy, color: beanColor, in: context)
                }
            }
        }
    }

    private func fillPixel(x: Int, y: Int, color: Color, in context: GraphicsContext) {
        let rect = CGRect(
            x: CGFloat(x) * pixelSize,
            y: CGFloat(y) * pixelSize,
            width: pixelSize,
            height: pixelSize
        )
        context.fill(Path(rect), with: .color(color))
    }
}

#Preview {
    HStack(spacing: 12) {
        ForEach(0...5, id: \.self) { count in
            BeanGlyph(beanCount: count)
        }
    }
    .padding()
}
