import SwiftUI

struct CommunityFeedView: View {
    @Bindable var viewModel: CommunityFeedViewModel
    let onJoinTapped: () -> Void
    @State private var selectedVisit: SelectedCommunityVisit?

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                ProgressView("Loading community...")
            case .loading:
                ProgressView("Loading community...")
            case .empty:
                refreshableStatusView
            case .failed(let message):
                refreshableStatusView(message: message)
            case .loaded:
                feedList
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.hydrateFromDisk()
            await viewModel.refresh()
        }
        .navigationDestination(item: $selectedVisit) { visit in
            CommunityVisitDetailView(recordName: visit.id)
        }
    }

    private var refreshableStatusView: some View {
        refreshableStatusView(message: nil)
    }

    private func refreshableStatusView(message: String?) -> some View {
        ScrollView {
            VStack {
                if let message {
                    ContentUnavailableView(
                        "Could not load community",
                        systemImage: "exclamationmark.triangle",
                        description: Text(message)
                    )
                } else if viewModel.currentMember == nil {
                    ContentUnavailableView {
                        Label("Community", systemImage: "person.3")
                    } description: {
                        Text("Join to see visits from other Road Beans members.")
                    } actions: {
                        Button("Join the Community", action: onJoinTapped)
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    ContentUnavailableView(
                        "No community activity yet",
                        systemImage: "cup.and.saucer",
                        description: Text("No visits from other members are available.")
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 420)
        }
    }

    private var feedList: some View {
        List {
            filterControls

            if !viewModel.favoritesRows.isEmpty {
                Section("Favorites") {
                    rows(viewModel.favoritesRows)
                }
            }

            Section(sectionTitle) {
                if viewModel.everyoneRows.isEmpty && viewModel.favoritesRows.isEmpty {
                    if viewModel.isRefreshing {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding(.vertical, 24)
                    } else {
                        ContentUnavailableView(
                            "No matching visits",
                            systemImage: "line.3.horizontal.decrease.circle",
                            description: Text("Pull to refresh or change the feed filters.")
                        )
                    }
                } else {
                    rows(viewModel.everyoneRows)
                }

                if viewModel.nextCursor != nil {
                    Button("Load More") {
                        Task { await viewModel.loadNextPage() }
                    }
                }
            }
        }
    }

    private var filterControls: some View {
        Section {
            Picker("Filter", selection: Binding(
                get: { viewModel.filter },
                set: { newValue in
                    guard newValue != viewModel.filter else { return }
                    viewModel.selectFilter(newValue)
                    Task { await viewModel.refresh() }
                }
            )) {
                ForEach(CommunityFeedFilter.allCases) { filter in
                    Text(filter.label).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            Picker("Sort", selection: $viewModel.sort) {
                ForEach(CommunityFeedSort.allCases) { sort in
                    Text(sort.label).tag(sort)
                }
            }
            .onChange(of: viewModel.sort) { _, _ in
                Task { await viewModel.refresh() }
            }
        }
    }

    private var sectionTitle: String {
        switch viewModel.filter {
        case .all: "Everyone"
        case .favorites: "Favorites"
        case .mine: "Mine"
        }
    }

    private func rows(_ rows: [CommunityVisitRow]) -> some View {
        ForEach(rows) { row in
            CommunityVisitRowView(
                row: row,
                isFavorite: viewModel.isFavorite(row),
                isLiked: viewModel.isLiked(row)
            ) {
                selectedVisit = SelectedCommunityVisit(id: row.id)
            } onLikeTapped: {
                Task { await viewModel.toggleLike(row) }
            } onCommentTapped: {
                selectedVisit = SelectedCommunityVisit(id: row.id)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                if viewModel.filter == .mine {
                    Button(role: .destructive) {
                        Task { await viewModel.deleteVisit(row) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
}

private struct SelectedCommunityVisit: Identifiable, Hashable {
    let id: String
}
