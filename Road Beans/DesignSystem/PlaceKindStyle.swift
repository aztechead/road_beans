import SwiftUI

enum PlaceKindStyle {
    static func badge(for kind: PlaceKind) -> some View {
        HStack(spacing: 6) {
            Image(systemName: kind.sfSymbol)
            Text(kind.displayName)
        }
        .font(.roadBeansCaption)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(kind.accentColor.opacity(0.18), in: Capsule())
        .foregroundStyle(kind.accentColor)
        .accessibilityElement(children: .combine)
    }

    static func mapMarker(for kind: PlaceKind, rating: Double?) -> some View {
        VStack(spacing: 3) {
            ZStack {
                Circle()
                    .fill(kind.accentColor.gradient)
                    .frame(width: 38, height: 38)

                Image(systemName: kind.sfSymbol)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }

            if let rating {
                Text(String(format: "%.1f", rating))
                    .font(.system(size: 10, weight: .bold, design: .rounded).monospacedDigit())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.thinMaterial, in: Capsule())
                    .foregroundStyle(.primary)
            }
        }
        .padding(4)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(kind.accentColor.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: RoadBeansTheme.Shadow.marker, radius: 8, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(kind.displayName) stop")
        .accessibilityValue(rating.map { BeanSliderModel.accessibilityValueText($0) } ?? "No rating")
    }
}
