import SwiftUI

enum PlaceKindStyle {
    static func badge(for kind: PlaceKind) -> some View {
        HStack(spacing: 6) {
            Image(systemName: kind.sfSymbol)
            Text(kind.displayName)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(kind.accentColor.opacity(0.18), in: Capsule())
        .foregroundStyle(kind.accentColor)
        .accessibilityElement(children: .combine)
    }
}
