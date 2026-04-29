import SwiftUI

struct TasteProfileChips: View {
    let profile: TasteProfile?

    var body: some View {
        if let profile {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(TasteAxis.allCases, id: \.self) { axis in
                        HStack(spacing: RoadBeansSpacing.xxs) {
                            Icon(.taste(axis), size: 12)
                            Text(label(for: axis, profile: profile))
                        }
                        .roadBeansStyle(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.surface(.raised), in: Capsule())
                        .overlay {
                            Capsule().stroke(Color.divider(.hairline), lineWidth: 1)
                        }
                    }
                }
            }
            .accessibilityLabel("Taste profile")
        }
    }

    private func label(for axis: TasteAxis, profile: TasteProfile) -> String {
        axis.compactLabel(for: profile.value(for: axis))
    }
}
