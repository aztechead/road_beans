import CoreLocation
import SwiftUI

struct PlaceDetailView: View {
    let placeID: UUID
    @Environment(\.placeRepository) private var placeRepository
    @Environment(\.visitRepository) private var visitRepository
    @State private var viewModel: PlaceDetailViewModel?
    @State private var expandedVisits: Set<UUID> = []
    @State private var isEditing = false

    var body: some View {
        Group {
            if let viewModel {
                switch viewModel.state {
                case .idle, .loading:
                    ProgressView("Loading stop...")
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
                ProgressView("Loading stop...")
            }
        }
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
            viewModel = PlaceDetailViewModel(placeRepo: placeRepository, visitRepo: visitRepository)
        }
        await viewModel?.load(id: placeID)
    }

    private var missingPlaceState: some View {
        ContentUnavailableView(
            "Stop not found",
            systemImage: "mappin.slash",
            description: Text("This stop may have been deleted.")
        )
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
        .padding()
    }

    private func content(_ detail: PlaceDetail) -> some View {
        List {
            Section {
                header(detail)
                averageBlock(detail)
            }

            visitsList(detail)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .roadBeansScreenBackground()
        .navigationDestination(for: VisitRoute.self) { route in
            VisitDetailView(visitID: route.id)
        }
    }

    private func header(_ detail: PlaceDetail) -> some View {
        VStack(alignment: .leading, spacing: RoadBeansTheme.Spacing.sm) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: detail.kind.sfSymbol)
                    .font(.largeTitle)
                    .foregroundStyle(detail.kind.accentColor)

                VStack(alignment: .leading, spacing: 6) {
                    Text(detail.name)
                        .font(.roadBeansHeadline)

                    PlaceKindStyle.badge(for: detail.kind)
                }
            }

            if let address = detail.address {
                Text(address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
        .glassCard(tint: detail.kind.accentColor)
    }

    @ViewBuilder
    private func averageBlock(_ detail: PlaceDetail) -> some View {
        if let averageRating = detail.averageRating {
            VStack(alignment: .leading, spacing: 8) {
                Text("Average rating")
                    .font(.roadBeansBody)
                    .foregroundStyle(.secondary)
                BeanRating(value: averageRating, pixelSize: 4)
            }
            .glassCard()
        } else {
            Text("No ratings yet")
                .font(.roadBeansBody)
                .foregroundStyle(.secondary)
                .glassCard()
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

    private func visitCard(_ visit: VisitRow) -> some View {
        VStack(alignment: .leading, spacing: RoadBeansTheme.Spacing.sm) {
            Button {
                toggleVisitExpansion(visit.id)
            } label: {
                HStack {
                    Text(visit.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.roadBeansBody)
                        .foregroundStyle(.primary)

                    Spacer()

                    if let averageRating = visit.averageRating {
                        BeanRating(value: averageRating, pixelSize: 2)
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
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .glassCard()
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
