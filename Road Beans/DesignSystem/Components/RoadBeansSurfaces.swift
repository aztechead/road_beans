import SwiftUI

struct RoadBeansSurfaceModifier: ViewModifier {
    enum Level {
        case base
        case elevated
        case inset
    }

    let level: Level
    var tint: Color?
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: RoadBeansRadius.lg, style: .continuous)

        content
            .background(background, in: shape)
            .overlay(shape.strokeBorder(borderColor, lineWidth: 1))
    }

    private var background: some ShapeStyle {
        if reduceTransparency {
            return AnyShapeStyle((tint ?? Color(UIColor.secondarySystemBackground)).opacity(0.96))
        }

        switch level {
        case .base:
            return AnyShapeStyle(Color(UIColor.secondarySystemBackground).opacity(0.86))
        case .elevated:
            return AnyShapeStyle(.thinMaterial)
        case .inset:
            return AnyShapeStyle((tint ?? Color.surface(.sunken)).opacity(0.32))
        }
    }

    private var borderColor: Color {
        switch level {
        case .base:
            Color.primary.opacity(0.08)
        case .elevated:
            (tint ?? .white).opacity(0.20)
        case .inset:
            (tint ?? .accent(.default)).opacity(0.18)
        }
    }

}

struct RoadBeansCard<Content: View>: View {
    var tint: Color?
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(RoadBeansSpacing.lg)
            .roadBeansSurface(.elevated, tint: tint)
    }
}

extension View {
    func roadBeansSurface(
        _ level: RoadBeansSurfaceModifier.Level = .base,
        tint: Color? = nil
    ) -> some View {
        modifier(RoadBeansSurfaceModifier(level: level, tint: tint))
    }

    func surface(_ token: RoadBeansColor.Surface, radius: CGFloat? = nil) -> some View {
        Group {
            if let radius {
                background(Color.surface(token), in: RoundedRectangle(cornerRadius: radius, style: .continuous))
                    .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            } else {
                background(Color.surface(token))
            }
        }
    }
}

#Preview {
    RoadBeansCard {
        Text("Road Beans")
            .roadBeansStyle(.headline)
    }
    .padding()
}
