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
                    ProgressView()
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
    }

    private func content(_ viewModel: PlaceListViewModel) -> some View {
        @Bindable var viewModel = viewModel

        return VStack(spacing: 0) {
            Picker("List mode", selection: $viewModel.mode) {
                ForEach(PlaceListMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)

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
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $viewModel.searchText, prompt: "Search stops, drinks, tags")
            .navigationDestination(for: UUID.self) { placeID in
                PlaceDetailView(placeID: placeID)
            }
            .refreshable {
                await viewModel.reload()
            }
        }
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
}
