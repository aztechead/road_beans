import SwiftUI

struct AddVisitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.visitRepository) private var visits
    @Environment(\.tagRepository) private var tags
    @Environment(\.locationSearchService) private var search
    @Environment(\.photoProcessingService) private var photoProcessor

    @State private var model: AddVisitFlowModel?
    @State private var isSaving = false
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    page(model: model)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(navigationTitle)
            .toolbar {
                if let model {
                    ToolbarItem(placement: .cancellationAction) {
                        if model.currentPage == 0 {
                            Button("Cancel") {
                                dismiss()
                            }
                            .disabled(isSaving)
                        } else {
                            Button("Back") {
                                model.currentPage -= 1
                            }
                            .disabled(isSaving)
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        if model.currentPage < 2 {
                            Button("Next") {
                                model.currentPage += 1
                            }
                            .disabled(isNextDisabled(model))
                        } else {
                            Button(isSaving ? "Saving..." : "Save") {
                                Task {
                                    await performSave(model)
                                }
                            }
                            .disabled(isSaving || model.placeRef == nil || model.drinks.isEmpty)
                        }
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if let saveError {
                    Text(saveError)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding()
                }
            }
        }
        .task {
            if model == nil {
                model = AddVisitFlowModel(
                    visits: visits,
                    tags: tags,
                    search: search,
                    photoProcessor: photoProcessor
                )
            }
        }
    }

    @ViewBuilder
    private func page(model: AddVisitFlowModel) -> some View {
        TabView(selection: Bindable(model).currentPage) {
            AddVisitPlacePage(model: model)
                .tag(0)
            AddVisitVisitPage(model: model)
                .tag(1)
            AddVisitDrinksPage(model: model)
                .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private var navigationTitle: String {
        switch model?.currentPage ?? 0 {
        case 0: "Place"
        case 1: "Visit"
        case 2: "Drinks"
        default: "New Visit"
        }
    }

    private func isNextDisabled(_ model: AddVisitFlowModel) -> Bool {
        isSaving || (model.currentPage == 0 && model.placeRef == nil)
    }

    private func performSave(_ model: AddVisitFlowModel) async {
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        do {
            let toast = try await model.save()
            NotificationCenter.default.post(
                name: .roadBeansVisitSaved,
                object: nil,
                userInfo: ["text": toast]
            )
            dismiss()
        } catch {
            saveError = "Could not save this visit."
        }
    }
}

#Preview {
    AddVisitView()
}
