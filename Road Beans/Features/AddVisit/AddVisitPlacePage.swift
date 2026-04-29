import SwiftUI

struct AddVisitPlacePage: View {
    @Bindable var model: AddVisitFlowModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RoadBeansSpacing.lg) {
                RoadBeansSection("Find a Stop") {
                    searchField
                }

                if model.searchState == .loading {
                    loadingSearchState
                } else if let message = model.searchState.errorMessage {
                    failedSearchState(message)
                } else if model.searchResults.isEmpty && !model.searchText.isEmpty {
                    emptySearchState
                } else {
                    searchResultsList
                }

            }
            .padding(RoadBeansSpacing.lg)
        }
        .background(Color.surface(.canvas))
    }

    private var searchField: some View {
        RoadBeansClearableTextField(
            "Search stops, cafes, truck stops",
            text: $model.searchText,
            systemImage: "magnifyingglass",
            autocapitalization: .words
        )
        .padding(RoadBeansSpacing.md)
        .surface(.sunken, radius: RoadBeansRadius.md)
        .onChange(of: model.searchText) {
            model.search()
        }
    }

    private var loadingSearchState: some View {
        RoadBeansCard {
            HStack(spacing: RoadBeansSpacing.md) {
                ProgressView()
                Text("Searching places...")
                    .roadBeansStyle(.bodyM)
                    .foregroundStyle(.ink(.secondary))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var emptySearchState: some View {
        RoadBeansEmptyState(title: "No matches", message: "Search Apple Maps for the real stop before logging a visit.", systemImage: "mappin.and.ellipse") {
            RoadBeansButton(title: "Search Again", systemImage: "arrow.clockwise", variant: .secondary) {
                model.search()
            }
        }
        .frame(minHeight: 300)
    }

    private func failedSearchState(_ message: String) -> some View {
        RoadBeansEmptyState(title: "Search failed", message: message, systemImage: "exclamationmark.triangle") {
            RoadBeansButton(title: "Try Again", systemImage: "arrow.clockwise", variant: .secondary) {
                model.search()
            }
        }
        .frame(minHeight: 300)
    }

    private var searchResultsList: some View {
        VStack(spacing: RoadBeansSpacing.sm) {
            ForEach(model.searchResults, id: \.self) { draft in
                Button {
                    model.selectMapKit(draft)
                } label: {
                    HStack(spacing: RoadBeansSpacing.md) {
                        Icon(.place(draft.kind), size: 20)
                            .frame(width: 32, height: 32)
                            .background(draft.kind.accentColor.opacity(0.12), in: Circle())

                        VStack(alignment: .leading, spacing: RoadBeansSpacing.xxs) {
                            Text(draft.name)
                                .roadBeansStyle(.headline)
                                .foregroundStyle(.ink(.primary))

                            if let address = draft.address, !address.isEmpty {
                                Text(address)
                                    .roadBeansStyle(.caption)
                                    .foregroundStyle(.ink(.secondary))
                                    .lineLimit(2)
                            }
                        }

                        Spacer(minLength: RoadBeansSpacing.md)

                        Image(systemName: model.placeRef == .newMapKit(draft) ? "checkmark.circle.fill" : "chevron.right")
                            .foregroundStyle(model.placeRef == .newMapKit(draft) ? Color.accent(.default) : Color.ink(.tertiary))
                    }
                    .padding(RoadBeansSpacing.md)
                    .roadBeansSurface(.base, tint: draft.kind.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
