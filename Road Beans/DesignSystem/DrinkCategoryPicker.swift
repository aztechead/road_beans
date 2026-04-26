import SwiftUI

struct DrinkCategoryPicker: View {
    @Binding var selection: DrinkCategory

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DrinkCategory.allCases, id: \.self) { category in
                    Button {
                        selection = category
                    } label: {
                        Label(category.displayName, systemImage: category.sfSymbol)
                            .font(.roadBeansCaption)
                            .padding(.horizontal, RoadBeansTheme.Spacing.sm)
                            .padding(.vertical, RoadBeansTheme.Spacing.xs)
                            .background(
                                Capsule()
                                    .fill(selection == category
                                          ? Color.beanRoast
                                          : Color.secondary.opacity(0.15))
                            )
                            .foregroundStyle(selection == category ? Color.white : Color.primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(category.displayName), drink category")
                    .accessibilityHint("Double tap to select")
                    .accessibilityAddTraits(selection == category ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, RoadBeansTheme.Spacing.xs)
        }
    }
}

#Preview {
    @Previewable @State var selection = DrinkCategory.latte
    DrinkCategoryPicker(selection: $selection)
        .padding()
}
