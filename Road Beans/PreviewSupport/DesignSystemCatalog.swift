import SwiftUI

struct DesignSystemCatalog: View {
    @State private var rating = 3.5

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RoadBeansSpacing.xl) {
                RoadBeansSection("Typography") {
                    TypographyCatalog()
                        .frame(height: 320)
                }

                RoadBeansSection("Bean rating") {
                    VStack(alignment: .leading, spacing: RoadBeansSpacing.md) {
                        BeanRatingView(value: $rating, size: 24)
                        BeanRatingView(value: .constant(rating), size: 16, editable: false)
                    }
                }

                RoadBeansSection("Icons") {
                    VStack(alignment: .leading, spacing: RoadBeansSpacing.md) {
                        iconRow(DrinkCategory.allCases.map { .drink($0) })
                        iconRow(PlaceKind.allCases.map { .place($0) })
                        iconRow(TasteAxis.allCases.map { .taste($0) })
                    }
                }

                RoadBeansSection("Components") {
                    VStack(alignment: .leading, spacing: RoadBeansSpacing.md) {
                        RoadBeansButton(title: "Add a visit", systemImage: "plus") {}
                        RoadBeansChip(title: "Selected", systemImage: "checkmark", isSelected: true)
                        RoadBeansCard {
                            Text("Card surface")
                                .roadBeansStyle(.bodyM)
                        }
                    }
                }
            }
            .padding(RoadBeansSpacing.xl)
        }
        .background(Color.surface(.canvas))
    }

    private func iconRow(_ icons: [Icon.Kind]) -> some View {
        HStack(spacing: RoadBeansSpacing.lg) {
            ForEach(Array(icons.enumerated()), id: \.offset) { _, kind in
                Icon(kind, size: 24)
            }
        }
    }
}

#Preview {
    DesignSystemCatalog()
}
