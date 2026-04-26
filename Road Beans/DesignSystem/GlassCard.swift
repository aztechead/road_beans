import SwiftUI

private struct GlassCardModifier: ViewModifier {
    let tint: Color?
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: RoadBeansTheme.Radius.card, style: .continuous)

        if reduceTransparency {
            content
                .padding(RoadBeansTheme.Spacing.md)
                .background((tint ?? Color(UIColor.secondarySystemBackground)).opacity(0.95), in: shape)
        } else {
            content
                .padding(RoadBeansTheme.Spacing.md)
                .background(.thinMaterial, in: shape)
                .overlay(
                    shape.strokeBorder((tint ?? .white).opacity(0.18), lineWidth: 0.5)
                )
                .shadow(color: RoadBeansTheme.Shadow.card, radius: 14, y: 6)
        }
    }
}

extension View {
    /// Centralized card backdrop so feature views do not hand-roll glass/material behavior.
    func glassCard(tint: Color? = nil) -> some View {
        modifier(GlassCardModifier(tint: tint))
    }
}
