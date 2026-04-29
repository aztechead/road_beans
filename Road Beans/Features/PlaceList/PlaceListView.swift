import SwiftUI

struct PlaceListView: View {
    var onAddVisit: () -> Void = {}

    @Environment(\.placeRepository) private var placeRepository
    @Environment(\.visitRepository) private var visitRepository
    @Environment(\.locationPermissionService) private var locationPermissionService
    @Environment(\.currentLocationProvider) private var currentLocationProvider
    @Environment(\.recommendationProfileService) private var recommendationProfileService
    @Environment(\.nearbyRecommendationCandidateService) private var nearbyRecommendationCandidateService
    @Environment(\.recommendationEnrichmentService) private var recommendationEnrichmentService
    @Environment(\.recommendationRankingService) private var recommendationRankingService
    @State private var viewModel: PlaceListViewModel?
    @State private var recommendationViewModel: RecommendationDeckViewModel?
    @State private var navigationPath: [UUID] = []
    @State private var showingAppleIntelligenceInfo = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if let viewModel {
                    content(viewModel)
                } else {
                    RoadBeansLoadingState(title: "Loading stops...")
                }
            }
            .navigationTitle("Stops")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingAppleIntelligenceInfo = true
                    } label: {
                        Label("How AI is used", systemImage: "sparkles")
                    }
                    .accessibilityLabel("How Apple Intelligence is used")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onAddVisit()
                    } label: {
                        Label("Add Visit", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAppleIntelligenceInfo) {
                AppleIntelligenceInfoView(onReset: {
                    if let recommendationViewModel {
                        await recommendationViewModel.reset()
                    }
                })
            }
        }
        .background(Color.surface(.canvas).ignoresSafeArea())
        .task {
            guard viewModel == nil else { return }
            let model = PlaceListViewModel(places: placeRepository, visits: visitRepository)
            let recommendations = RecommendationDeckViewModel(
                visits: visitRepository,
                locationPermission: locationPermissionService,
                currentLocation: currentLocationProvider,
                profileService: recommendationProfileService,
                candidateService: nearbyRecommendationCandidateService,
                enrichmentService: recommendationEnrichmentService,
                rankingService: recommendationRankingService
            )
            viewModel = model
            recommendationViewModel = recommendations
            await model.reload()
            await recommendations.reload()
        }
        .onReceive(NotificationCenter.default.publisher(for: .roadBeansVisitSaved)) { _ in
            Task {
                await viewModel?.reload()
                await recommendationViewModel?.reload()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .roadBeansVisitDeleted)) { _ in
            Task {
                await viewModel?.reload()
                await recommendationViewModel?.reload()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .roadBeansPlaceUpdated)) { _ in
            Task {
                await viewModel?.reload()
                await recommendationViewModel?.reload()
            }
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
                    RoadBeansLoadingState(title: "Loading stops...")
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
                            if viewModel.mode == .byPlace, let recommendationViewModel {
                                RecommendationDeckView(viewModel: recommendationViewModel)
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 6, trailing: 16))
                            }

                            switch viewModel.mode {
                            case .byPlace:
                                ForEach(viewModel.filteredPlaces) { place in
                                    Button {
                                        navigationPath.append(place.id)
                                    } label: {
                                        RoadBeansCard(tint: place.kind.accentColor) {
                                            placeRow(place)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            Task { await deletePlace(place.id, using: viewModel) }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            case .recentVisits:
                                ForEach(viewModel.filteredVisits, id: \.visit.id) { row in
                                    RoadBeansCard(tint: row.placeKind.accentColor) {
                                        visitRow(row)
                                    }
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            Task { await deleteVisit(row.visit.id, using: viewModel) }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
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
        .background(Color.surface(.canvas).ignoresSafeArea())
    }

    private func deleteVisit(_ id: UUID, using viewModel: PlaceListViewModel) async {
        try? await viewModel.deleteVisit(id: id)
        NotificationCenter.default.post(name: .roadBeansVisitDeleted, object: nil)
    }

    private func deletePlace(_ id: UUID, using viewModel: PlaceListViewModel) async {
        try? await viewModel.deletePlace(id: id)
        NotificationCenter.default.post(name: .roadBeansPlaceDeleted, object: nil)
    }

    private func searchField(text: Binding<String>) -> some View {
        RoadBeansClearableTextField(
            "Search stops, drinks, tags",
            text: text,
            systemImage: "magnifyingglass",
            autocapitalization: .never,
            autocorrectionDisabled: true
        )
        .roadBeansStyle(.bodyM)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .roadBeansSurface(.inset, tint: .surface(.sunken))
        .clipShape(Capsule())
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
        RoadBeansChip(title: title, systemImage: systemImage)
    }

    private func placeRow(_ place: PlaceSummary) -> some View {
        HStack(spacing: 12) {
            Icon(.place(place.kind), size: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .roadBeansStyle(.titleM)

                if let address = place.address {
                    Text(address)
                        .roadBeansStyle(.bodyS)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .layoutPriority(1)

            Spacer()

            if let averageRating = place.averageRating {
                BeanRatingView(value: .constant(averageRating), size: 16, editable: false)
                    .layoutPriority(1)
            }

            Image(systemName: "chevron.forward")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private func visitRow(_ row: RecentVisitRow) -> some View {
        HStack(spacing: 12) {
            Icon(.place(row.placeKind), size: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(row.placeName)
                    .roadBeansStyle(.titleM)

                Text(row.visit.date.formatted(date: .abbreviated, time: .shortened))
                    .roadBeansStyle(.bodyS)
                    .foregroundStyle(.secondary)
            }
            .layoutPriority(1)

            Spacer()

            if let averageRating = row.visit.averageRating {
                BeanRatingView(value: .constant(averageRating), size: 16, editable: false)
                    .layoutPriority(1)
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
