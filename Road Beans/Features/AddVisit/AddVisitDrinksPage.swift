import SwiftUI

struct AddVisitDrinksPage: View {
    @Bindable var model: AddVisitFlowModel

    var body: some View {
        List {
            ForEach(model.drinks.indices, id: \.self) { index in
                Section {
                    DrinkDraftRow(
                        drink: $model.drinks[index],
                        suggestions: { prefix in
                            (try? await model.tagsRepo.suggestions(prefix: prefix, limit: 5)) ?? []
                        }
                    )
                }
            }
            .onDelete { offsets in
                model.drinks.remove(atOffsets: offsets)
            }

            Section {
                Button {
                    model.drinks.append(DrinkDraft(name: "", category: .drip, rating: 3.0, tags: []))
                } label: {
                    Label("Add drink", systemImage: "plus")
                }
            }
        }
    }
}

private struct DrinkDraftRow: View {
    @Binding var drink: DrinkDraft
    let suggestions: (String) async -> [TagSuggestion]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            DrinkCategoryPicker(selection: $drink.category)

            TextField("Drink name", text: $drink.name)
                .textFieldStyle(.roundedBorder)

            TagTokenField(tags: $drink.tags, suggestions: suggestions)

            BeanSlider(value: $drink.rating)
                .padding(.top, 24)
        }
        .padding(.vertical, 8)
    }
}
