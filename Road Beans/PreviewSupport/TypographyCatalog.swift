import SwiftUI

struct TypographyCatalog: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RoadBeansSpacing.lg) {
                ForEach(RoadBeansFont.Style.allCases, id: \.self) { style in
                    HStack(alignment: .firstTextBaseline, spacing: RoadBeansSpacing.lg) {
                        Text(String(describing: style))
                            .roadBeansStyle(.eyebrow)
                            .foregroundStyle(.ink(.tertiary))
                            .frame(width: 140, alignment: .leading)

                        Text("The quick brown fox jumps 12,345")
                            .roadBeansStyle(style)
                            .foregroundStyle(.ink(.primary))
                    }
                }
            }
            .padding(RoadBeansSpacing.xl)
        }
        .background(Color.surface(.canvas))
    }
}

#Preview {
    TypographyCatalog()
}

#Preview {
    TypographyCatalog()
        .preferredColorScheme(.dark)
}
