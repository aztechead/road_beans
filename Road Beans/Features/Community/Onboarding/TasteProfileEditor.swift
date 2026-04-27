import SwiftUI

struct TasteProfileEditor: View {
    @Binding var profile: TasteProfile
    var isReadOnly = false

    var body: some View {
        VStack(alignment: .leading, spacing: RoadBeansSpacing.md) {
            ForEach(TasteAxis.allCases, id: \.self) { axis in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(axis.lowLabel)
                        Spacer()
                        Text(axis.highLabel)
                    }
                    .font(.caption)
                    .foregroundStyle(.ink(.secondary))

                    Slider(
                        value: Binding(
                            get: { profile.value(for: axis) },
                            set: { profile.set($0, for: axis) }
                        ),
                        in: 0...1
                    )
                    .disabled(isReadOnly)
                    .accessibilityLabel("\(axis.rawValue.capitalized) preference")
                }
            }
        }
    }
}
