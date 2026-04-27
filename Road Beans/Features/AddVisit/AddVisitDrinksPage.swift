import SwiftUI

struct AddVisitDrinksPage: View {
    @Bindable var model: AddVisitFlowModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RoadBeansSpacing.lg) {
                ForEach(model.drinks.indices, id: \.self) { index in
                    DrinkDraftRow(
                        drink: $model.drinks[index],
                        title: "Drink \(index + 1)",
                        canDelete: model.drinks.count > 1,
                        onDelete: {
                            model.drinks.remove(at: index)
                        },
                        suggestions: { prefix in
                            (try? await model.tagsRepo.suggestions(prefix: prefix, limit: 5)) ?? []
                        }
                    )
                }

                RoadBeansButton(title: "Add Drink", systemImage: "plus", variant: .secondary) {
                    model.drinks.append(DrinkDraft(name: "", category: .drip, rating: 3.0, tags: []))
                }
            }
            .padding(RoadBeansSpacing.lg)
        }
        .background(Color.surface(.canvas))
    }
}

private struct DrinkDraftRow: View {
    @Binding var drink: DrinkDraft
    let title: String
    let canDelete: Bool
    let onDelete: () -> Void
    let suggestions: (String) async -> [TagSuggestion]

    var body: some View {
        VStack(alignment: .leading, spacing: RoadBeansSpacing.md) {
            HStack {
                Text(title)
                    .roadBeansStyle(.title3)

                Spacer()

                if canDelete {
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.state(.danger))
                }
            }

            DrinkCategoryChips(selection: $drink.category)

            TextField("Drink name", text: $drink.name)
                .padding(RoadBeansSpacing.md)
                .surface(.sunken, radius: RoadBeansRadius.md)

            TagTokenField(tags: $drink.tags, suggestions: suggestions)
                .padding(RoadBeansSpacing.md)
                .surface(.sunken, radius: RoadBeansRadius.md)

            BeanRatingView(value: $drink.rating, size: 24)
                .frame(maxWidth: .infinity)
                .padding(.top, RoadBeansSpacing.sm)
        }
        .padding(RoadBeansSpacing.lg)
        .roadBeansSurface(.base, tint: Color.accent(.default))
    }
}

private struct DrinkCategoryChips: View {
    @Binding var selection: DrinkCategory

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RoadBeansSpacing.sm) {
                ForEach(DrinkCategory.allCases, id: \.self) { category in
                    Button {
                        selection = category
                    } label: {
                        HStack(spacing: RoadBeansSpacing.xs) {
                            Icon(.drink(category), size: 16, active: selection == category)
                            Text(category.displayName)
                        }
                        .roadBeansStyle(.labelM)
                        .padding(.horizontal, RoadBeansSpacing.md)
                        .padding(.vertical, 6)
                        .background(selection == category ? Color.accent(.default) : Color.clear, in: Capsule())
                        .foregroundStyle(selection == category ? Color.accent(.on) : Color.ink(.secondary))
                        .overlay {
                            if selection != category {
                                Capsule().stroke(Color.divider(.strong), lineWidth: 1)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selection == category ? [.isSelected] : [])
                }
            }
        }
    }
}
