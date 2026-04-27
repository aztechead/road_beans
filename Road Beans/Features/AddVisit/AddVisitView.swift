import SwiftUI

struct AddVisitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.visitRepository) private var visits
    @Environment(\.tagRepository) private var tags
    @Environment(\.locationSearchService) private var search
    @Environment(\.currentLocationProvider) private var currentLocationProvider
    @Environment(\.photoProcessingService) private var photoProcessor

    @State private var model: AddVisitFlowModel?
    @State private var isSaving = false
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    VStack(spacing: 0) {
                        AddVisitStepHeader(model: model)
                        progressHeader(model)
                        page(model: model)
                    }
                } else {
                    RoadBeansLoadingState(title: "Preparing visit...")
                }
            }
            .navigationTitle(navigationTitle)
            .background(Color.surface(.canvas).ignoresSafeArea())
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
                        .roadBeansStyle(.caption)
                        .foregroundStyle(Color.state(.danger))
                        .padding(RoadBeansSpacing.md)
                        .surface(.raised, radius: RoadBeansRadius.md)
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
                    currentLocation: currentLocationProvider,
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

    private func progressHeader(_ model: AddVisitFlowModel) -> some View {
        HStack(spacing: RoadBeansSpacing.sm) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(index <= model.currentPage ? Color.accent(.default) : Color.divider(.hairline))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, RoadBeansSpacing.lg)
        .padding(.top, RoadBeansSpacing.sm)
        .padding(.bottom, RoadBeansSpacing.md)
        .background(Color.surface(.canvas))
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

private struct AddVisitStepHeader: View {
    let model: AddVisitFlowModel

    var body: some View {
        HStack(spacing: RoadBeansSpacing.md) {
            ZStack {
                TopoShape(seed: TopoSeeds.publishOverlay + UInt64(model.currentPage), ringCount: 4, amplitude: 0.12, frequency: 4)
                    .stroke(Color.accent(.default).opacity(0.22), lineWidth: 1)
                    .frame(width: 68, height: 68)

                headerIcon
                    .frame(width: 34, height: 34)
                    .foregroundStyle(Color.accent(.default))
            }

            VStack(alignment: .leading, spacing: RoadBeansSpacing.xxs) {
                Text(title)
                    .roadBeansStyle(.titleM)
                    .foregroundStyle(.ink(.primary))

                Text(subtitle)
                    .roadBeansStyle(.bodyS)
                    .foregroundStyle(.ink(.secondary))
                    .lineLimit(2)
            }

            Spacer(minLength: RoadBeansSpacing.md)
        }
        .padding(.horizontal, RoadBeansSpacing.lg)
        .padding(.top, RoadBeansSpacing.md)
        .padding(.bottom, RoadBeansSpacing.xs)
        .background(Color.surface(.canvas))
    }

    @ViewBuilder private var headerIcon: some View {
        switch model.currentPage {
        case 0:
            Image(systemName: "mappin.and.ellipse")
        case 1:
            Image(systemName: "calendar.badge.clock")
        default:
            BeanMark(state: .full, size: 32)
        }
    }

    private var title: String {
        switch model.currentPage {
        case 0: "Choose the stop"
        case 1: selectedPlaceName ?? "Log the visit"
        default: model.drinks.isEmpty ? "Add a drink" : "\(model.drinks.count) drink\(model.drinks.count == 1 ? "" : "s")"
        }
    }

    private var subtitle: String {
        switch model.currentPage {
        case 0:
            return "Search nearby places or add your own road stop."
        case 1:
            let photoText = model.photos.isEmpty ? "No photos yet" : "\(model.photos.count) photo\(model.photos.count == 1 ? "" : "s")"
            return "\(model.date.formatted(date: .abbreviated, time: .omitted)) - \(photoText)"
        default:
            let namedDrinks = model.drinks.map(\.name).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            return namedDrinks.isEmpty ? "Name each drink, tag it, and rate it." : namedDrinks.joined(separator: ", ")
        }
    }

    private var selectedPlaceName: String? {
        switch model.placeRef {
        case .newMapKit(let draft):
            draft.name
        case .newCustom(let draft):
            draft.name
        case .existing, .none:
            nil
        }
    }
}

#Preview {
    AddVisitView()
}
