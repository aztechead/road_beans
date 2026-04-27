import SwiftUI

struct TasteProfileChips: View {
    let profile: TasteProfile?

    var body: some View {
        if let profile {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(TasteAxis.allCases, id: \.self) { axis in
                        Text(label(for: axis, profile: profile))
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.thinMaterial, in: Capsule())
                    }
                }
            }
            .accessibilityLabel("Taste profile")
        }
    }

    private func label(for axis: TasteAxis, profile: TasteProfile) -> String {
        profile.value(for: axis) >= 0.5 ? axis.compactHighLabel : axis.compactLowLabel
    }
}
