import SwiftUI

struct PlaceListView: View {
    @Environment(\.placeRepository) private var placeRepository
    @Environment(\.visitRepository) private var visitRepository
    @State private var viewModel: PlaceListViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    content(viewModel)
                } else {
                    ProgressView("Loading stops...")
                }
            }
            .navigationTitle("Stops")
        }
        .task {
            guard viewModel == nil else { return }
            let model = PlaceListViewModel(places: placeRepository, visits: visitRepository)
            viewModel = model
            await model.reload()
        }
        .onReceive(NotificationCenter.default.publisher(for: .roadBeansVisitSaved)) { _ in
            Task { await viewModel?.reload() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .roadBeansVisitDeleted)) { _ in
            Task { await viewModel?.reload() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .roadBeansPlaceUpdated)) { _ in
            Task { await viewModel?.reload() }
        }
    }

    private func content(_ viewModel: PlaceListViewModel) -> some View {
        @Bindable var viewModel = viewModel

        return VStack(spacing: 0) {
            searchField(text: $viewModel.searchText)
                .padding(.horizontal)
                .padding(.top, 8)

            Picker("List mode", selection: $viewModel.mode) {
                ForEach(PlaceListMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 10)

            filterBar(viewModel)
                .padding(.horizontal)
                .padding(.vertical, 8)

            Group {
                switch viewModel.state {
                case .loading, .idle:
                    ProgressView("Loading stops...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .failed(let message):
                    unavailableState(
                        title: "Could not load stops",
                        systemImage: "exclamationmark.triangle",
                        message: message,
                        retry: { await viewModel.reload() }
                    )
                case .empty:
                    unavailableState(
                        title: "No stops yet",
                        systemImage: "cup.and.saucer",
                        message: "Add your first stop to start building your road coffee log.",
                        retry: nil
                    )
                case .loaded:
                    if viewModel.isShowingEmptyResults {
                        unavailableState(
                            title: "No matches",
                            systemImage: "magnifyingglass",
                            message: "Try a different stop, drink, or tag.",
                            retry: nil
                        )
                    } else {
                        List {
                            switch viewModel.mode {
                            case .byPlace:
                                ForEach(viewModel.filteredPlaces) { place in
                                    NavigationLink(value: place.id) {
                                        placeRow(place)
                                    }
                                }
                            case .recentVisits:
                                ForEach(viewModel.filteredVisits, id: \.visit.id) { row in
                                    visitRow(row)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                Task { await deleteVisit(row.visit.id, using: viewModel) }
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                        .refreshable {
                            await viewModel.reload()
                        }
                    }
                }
            }
            .navigationDestination(for: UUID.self) { placeID in
                PlaceDetailView(placeID: placeID)
            }
        }
        .roadBeansScreenBackground()
    }

    private func deleteVisit(_ id: UUID, using viewModel: PlaceListViewModel) async {
        try? await viewModel.deleteVisit(id: id)
        NotificationCenter.default.post(name: .roadBeansVisitDeleted, object: nil)
    }

    private func searchField(text: Binding<String>) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search stops, drinks, tags", text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !text.wrappedValue.isEmpty {
                Button {
                    text.wrappedValue = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .font(.roadBeansBody)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.secondary.opacity(0.14), in: Capsule())
    }

    private func filterBar(_ viewModel: PlaceListViewModel) -> some View {
        @Bindable var viewModel = viewModel

        return VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Menu {
                        Button("Any Kind") {
                            viewModel.selectedKind = nil
                        }

                        Divider()

                        ForEach(PlaceKind.allCases, id: \.self) { kind in
                            Button(kind.displayName) {
                                viewModel.selectedKind = kind
                            }
                        }
                    } label: {
                        filterChip(
                            title: viewModel.selectedKind?.displayName ?? "Any Kind",
                            systemImage: viewModel.selectedKind?.sfSymbol ?? "line.3.horizontal.decrease.circle"
                        )
                    }

                    Menu {
                        ForEach(PlaceRatingFilter.allCases) { filter in
                            Button(filter.rawValue) {
                                viewModel.ratingFilter = filter
                            }
                        }
                    } label: {
                        filterChip(title: viewModel.ratingFilter.rawValue, systemImage: "star.fill")
                    }

                    Menu {
                        Toggle("Use Date Range", isOn: $viewModel.isDateFilterEnabled)

                        DatePicker("From", selection: $viewModel.startDate, displayedComponents: .date)
                            .disabled(!viewModel.isDateFilterEnabled)

                        DatePicker("To", selection: $viewModel.endDate, displayedComponents: .date)
                            .disabled(!viewModel.isDateFilterEnabled)
                    } label: {
                        filterChip(
                            title: viewModel.isDateFilterEnabled ? "Date Range" : "Any Date",
                            systemImage: "calendar"
                        )
                    }

                    if !viewModel.availableTags.isEmpty {
                        Menu {
                            ForEach(viewModel.availableTags, id: \.self) { tag in
                                Button {
                                    viewModel.toggleTag(tag)
                                } label: {
                                    Label(
                                        tag,
                                        systemImage: viewModel.selectedTags.contains(tag) ? "checkmark.circle.fill" : "circle"
                                    )
                                }
                            }
                        } label: {
                            filterChip(
                                title: viewModel.selectedTags.isEmpty ? "Any Tag" : "\(viewModel.selectedTags.count) Tag\(viewModel.selectedTags.count == 1 ? "" : "s")",
                                systemImage: "tag.fill"
                            )
                        }
                    }

                    if viewModel.activeFilterCount > 0 {
                        Button("Clear") {
                            viewModel.clearFilters()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func filterChip(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.roadBeansCaption)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.secondary.opacity(0.14), in: Capsule())
    }

    private func placeRow(_ place: PlaceSummary) -> some View {
        HStack(spacing: 12) {
            Image(systemName: place.kind.sfSymbol)
                .foregroundStyle(place.kind.accentColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(.roadBeansHeadline)

                if let address = place.address {
                    Text(address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let averageRating = place.averageRating {
                BeanRating(value: averageRating, pixelSize: 2)
            }
        }
        .padding(.vertical, 6)
    }

    private func visitRow(_ row: RecentVisitRow) -> some View {
        HStack(spacing: 12) {
            Image(systemName: row.placeKind.sfSymbol)
                .foregroundStyle(row.placeKind.accentColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(row.placeName)
                    .font(.roadBeansHeadline)

                Text(row.visit.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let averageRating = row.visit.averageRating {
                BeanRating(value: averageRating, pixelSize: 2)
            }
        }
        .padding(.vertical, 6)
    }

    private func unavailableState(
        title: String,
        systemImage: String,
        message: String,
        retry: (() async -> Void)?
    ) -> some View {
        VStack(spacing: 16) {
            ContentUnavailableView(
                title,
                systemImage: systemImage,
                description: Text(message)
            )

            if let retry {
                Button("Try Again") {
                    Task { await retry() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
