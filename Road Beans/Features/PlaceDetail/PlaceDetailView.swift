import CoreLocation
import SwiftUI

struct PlaceDetailView: View {
    let placeID: UUID
    @Environment(\.placeRepository) private var placeRepository
    @Environment(\.visitRepository) private var visitRepository
    @Environment(\.communityService) private var community
    @State private var viewModel: PlaceDetailViewModel?
    @State private var expandedVisits: Set<UUID> = []
    @State private var isEditing = false

    var body: some View {
        Group {
            if let viewModel {
                switch viewModel.state {
                case .idle, .loading:
                    RoadBeansLoadingState(title: "Loading stop...")
                case .loaded:
                    if let detail = viewModel.detail {
                        content(detail)
                    } else {
                        missingPlaceState
                    }
                case .empty:
                    missingPlaceState
                case .failed(let message):
                    failedState(message)
                }
            } else {
                RoadBeansLoadingState(title: "Loading stop...")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surface(.canvas).ignoresSafeArea())
        .navigationTitle("Place")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel?.detail != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        isEditing = true
                    }
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            if let detail = viewModel?.detail {
                EditPlaceView(detail: detail) { command in
                    try await viewModel?.update(command)
                }
            }
        }
        .task {
            await ensureLoaded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .roadBeansVisitSaved)) { _ in
            Task { await ensureLoaded() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .roadBeansVisitDeleted)) { _ in
            Task { await ensureLoaded() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .roadBeansPlaceUpdated)) { _ in
            Task { await ensureLoaded() }
        }
    }

    private func ensureLoaded() async {
        if viewModel == nil {
            viewModel = PlaceDetailViewModel(placeRepo: placeRepository, visitRepo: visitRepository, community: community)
        }
        await viewModel?.load(id: placeID)
    }

    private var missingPlaceState: some View {
        ContentUnavailableView(
            "Stop not found",
            systemImage: "mappin.slash",
            description: Text("This stop may have been deleted.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surface(.canvas).ignoresSafeArea())
        .padding()
    }

    private func failedState(_ message: String) -> some View {
        VStack(spacing: 16) {
            ContentUnavailableView(
                "Could not load stop",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )

            Button("Try Again") {
                Task { await ensureLoaded() }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surface(.canvas).ignoresSafeArea())
        .padding()
    }

    private func content(_ detail: PlaceDetail) -> some View {
        List {
            Section {
                header(detail)
                averageBlock(detail)
            }

            visitsList(detail)

            communityVisitsList()
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.surface(.canvas).ignoresSafeArea())
        .navigationDestination(for: VisitRoute.self) { route in
            VisitDetailView(visitID: route.id)
        }
    }

    private func header(_ detail: PlaceDetail) -> some View {
        RoadBeansCard(tint: detail.kind.accentColor) {
            VStack(alignment: .leading, spacing: RoadBeansSpacing.sm) {
            HStack(alignment: .top, spacing: 12) {
                Icon(.place(detail.kind), size: 32)

                VStack(alignment: .leading, spacing: 6) {
                    Text(detail.name)
                        .roadBeansStyle(.titleL)

                    RoadBeansChip(title: detail.kind.displayName, state: .default)
                }
            }

            if let address = detail.address {
                Text(address)
                    .roadBeansStyle(.bodyS)
                    .foregroundStyle(.ink(.secondary))
            }

            if let coordinate = detail.coordinate {
                Button {
                    openInMaps(name: detail.name, coordinate: coordinate)
                } label: {
                    Label("Open in Maps", systemImage: "map.fill")
                }
                .buttonStyle(.bordered)
            }
            }
        }
    }

    @ViewBuilder
    private func averageBlock(_ detail: PlaceDetail) -> some View {
        if let averageRating = detail.averageRating {
            RoadBeansCard {
                VStack(alignment: .leading, spacing: RoadBeansSpacing.sm) {
                Text("Average rating")
                    .roadBeansStyle(.bodyM)
                    .foregroundStyle(.ink(.secondary))
                BeanRatingView(value: .constant(averageRating), size: 24, editable: false)
                }
            }
        } else {
            RoadBeansCard {
                Text("No ratings yet")
                    .roadBeansStyle(.bodyM)
                    .foregroundStyle(.ink(.secondary))
            }
        }
    }

    private func visitsList(_ detail: PlaceDetail) -> some View {
        Section("Visits") {
            ForEach(detail.visits) { visit in
                visitCard(visit)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            Task { await deleteVisit(visit.id) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private func communityVisitsList() -> some View {
        if let rows = viewModel?.communityRows, !rows.isEmpty {
            Section("Community Visits") {
                ForEach(rows) { row in
                    NavigationLink {
                        CommunityVisitDetailView(recordName: row.id)
                    } label: {
                        CommunityVisitRowView(row: row, isFavorite: false)
                    }
                }
            }
        }
    }

    private func visitCard(_ visit: VisitRow) -> some View {
        RoadBeansCard {
            VStack(alignment: .leading, spacing: RoadBeansSpacing.sm) {
            Button {
                toggleVisitExpansion(visit.id)
            } label: {
                HStack {
                    Text(visit.date.formatted(date: .abbreviated, time: .shortened))
                        .roadBeansStyle(.bodyM)
                        .foregroundStyle(.ink(.primary))

                    Spacer()

                    if let averageRating = visit.averageRating {
                        BeanRatingView(value: .constant(averageRating), size: 16, editable: false)
                    }

                    Image(systemName: expandedVisits.contains(visit.id) ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if expandedVisits.contains(visit.id) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(visit.drinkCount) drink\(visit.drinkCount == 1 ? "" : "s")")
                    Text("\(visit.photoCount) photo\(visit.photoCount == 1 ? "" : "s")")

                    if !visit.tagNames.isEmpty {
                        Text(visit.tagNames.joined(separator: ", "))
                            .foregroundStyle(.secondary)
                    }

                    NavigationLink(value: VisitRoute(id: visit.id)) {
                        Label("View visit", systemImage: "arrow.right")
                    }
                }
                .roadBeansStyle(.bodyS)
                .foregroundStyle(.ink(.secondary))
            }
            }
        }
        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
        .listRowBackground(Color.clear)
    }

    private func toggleVisitExpansion(_ id: UUID) {
        if expandedVisits.contains(id) {
            expandedVisits.remove(id)
        } else {
            expandedVisits.insert(id)
        }
    }

    private func deleteVisit(_ id: UUID) async {
        try? await viewModel?.deleteVisit(id: id, placeID: placeID)
        expandedVisits.remove(id)
        NotificationCenter.default.post(name: .roadBeansVisitDeleted, object: nil)
    }

    private func openInMaps(name: String, coordinate: CLLocationCoordinate2D) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "maps.apple.com"
        components.queryItems = [
            URLQueryItem(name: "ll", value: "\(coordinate.latitude),\(coordinate.longitude)"),
            URLQueryItem(name: "q", value: name)
        ]

        if let url = components.url {
            UIApplication.shared.open(url)
        }
    }
}

private struct VisitRoute: Hashable {
    let id: UUID
}
