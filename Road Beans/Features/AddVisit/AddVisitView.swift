import SwiftUI

struct AddVisitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.visitRepository) private var visits
    @Environment(\.tagRepository) private var tags
    @Environment(\.locationSearchService) private var search
    @Environment(\.photoProcessingService) private var photoProcessor

    @State private var model: AddVisitFlowModel?

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    TabView(selection: Bindable(model).currentPage) {
                        AddVisitPlacePage(model: model)
                            .tag(0)
                        AddVisitVisitPage(model: model)
                            .tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                } else {
                    ProgressView()
                }
            }
                .navigationTitle("New Visit")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
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
}

#Preview {
    AddVisitView()
}
