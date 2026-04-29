import MapKit
import SwiftUI
import UIKit

private enum MapSheetItem: Identifiable {
    case personal(PlaceSummary)
    case community(CommunityPlaceAnnotation)

    var id: String {
        switch self {
        case .personal(let place): place.id.uuidString
        case .community(let annotation): annotation.id
        }
    }
}

struct MapTabView: View {
    @Environment(\.placeRepository) private var placeRepository
    @Environment(\.locationPermissionService) private var permissionService
    @Environment(\.currentLocationProvider) private var currentLocationProvider
    @Environment(\.communityService) private var communityService
    @Environment(\.communityMemberCache) private var communityMemberCache
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: MapTabViewModel?
    @State private var selectedMapItem: MapSheetItem?
    @State private var mapPosition: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    content(viewModel)
                } else {
                    RoadBeansLoadingState(title: "Loading map...")
                }
            }
            .navigationTitle("Map")
        }
        .background(Color.surface(.canvas).ignoresSafeArea())
        .task {
            guard viewModel == nil else { return }
            let model = MapTabViewModel(
                places: placeRepository,
                permission: permissionService,
                currentLocation: currentLocationProvider,
                community: communityService,
                memberCache: communityMemberCache
            )
            viewModel = model
            await model.refreshPermissionStatus()
            await model.checkCommunityMembership()
            await model.reload(allowingNearMe: false)
        }
        .onReceive(NotificationCenter.default.publisher(for: .roadBeansVisitSaved)) { _ in
            Task {
                await viewModel?.reload(allowingNearMe: viewModel?.nearMeOn ?? false)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .roadBeansVisitDeleted)) { _ in
            Task {
                await viewModel?.reload(allowingNearMe: viewModel?.nearMeOn ?? false)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .roadBeansPlaceUpdated)) { _ in
            Task {
                await viewModel?.reload(allowingNearMe: viewModel?.nearMeOn ?? false)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .roadBeansPlaceDeleted)) { _ in
            Task {
                selectedMapItem = nil
                await viewModel?.reload(allowingNearMe: viewModel?.nearMeOn ?? false)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task {
                guard let viewModel, viewModel.communityReviewsOn else { return }
                await viewModel.reloadCommunityAnnotations(enabled: true)
                guard viewModel.communityReviewsOn else { return }
                await MainActor.run {
                    fitCommunityContent(viewModel)
                }
            }
        }
    }

    private func content(_ viewModel: MapTabViewModel) -> some View {
        @Bindable var viewModel = viewModel

        return VStack(spacing: 0) {
            Toggle("Stops near me", isOn: $viewModel.nearMeOn)
                .padding()
                .onChange(of: viewModel.nearMeOn) { _, isOn in
                    Task {
                        if isOn {
                            await viewModel.requestPermissionIfNeeded()
                        }
                        await viewModel.reload(allowingNearMe: isOn)
                    }
                }

            if viewModel.isCommunityMember {
                if viewModel.communityLoadState == .loading {
                    HStack {
                        Text("Community reviews")
                        Spacer()
                        ProgressView()
                    }
                    .padding()
                } else {
                    Toggle("Community reviews", isOn: $viewModel.communityReviewsOn)
                        .padding()
                        .onChange(of: viewModel.communityReviewsOn) { _, isOn in
                            Task {
                                await viewModel.reloadCommunityAnnotations(enabled: isOn)
                                guard isOn, viewModel.communityReviewsOn else { return }
                                await MainActor.run {
                                    fitCommunityContent(viewModel)
                                }
                            }
                        }
                }
            }

            if viewModel.isLoadingCurrentLocation {
                loadingLocationState
            } else if viewModel.nearMeOn && (viewModel.permissionStatus == .denied || viewModel.permissionStatus == .restricted) {
                deniedRationale
            } else if viewModel.currentLocationUnavailable {
                currentLocationUnavailableState(viewModel)
            } else if viewModel.state == .empty && !viewModel.hasVisibleMapContent {
                ContentUnavailableView(
                    "No stops on the map yet",
                    systemImage: "map",
                    description: Text("Add your first stop to see it here.")
                )
                .padding()
            } else {
                Map(position: $mapPosition) {
                    if viewModel.currentLocation != nil {
                        UserAnnotation()
                    }

                    ForEach(viewModel.places) { place in
                        if let coordinate = place.coordinate {
                            Annotation(place.name, coordinate: coordinate) {
                                Button {
                                    selectedMapItem = .personal(place)
                                } label: {
                                    MapMarkerView(kind: place.kind, rating: place.averageRating)
                                }
                                .buttonStyle(.plain)
                            }
                            .tint(place.kind.accentColor)
                        }
                    }

                    if viewModel.communityReviewsOn {
                        ForEach(viewModel.communityAnnotations) { annotation in
                            Annotation(annotation.name, coordinate: annotation.coordinate) {
                                Button {
                                    selectedMapItem = .community(annotation)
                                } label: {
                                    CommunityMapMarkerView(kind: annotation.kind, rating: annotation.averageRating)
                                }
                                .buttonStyle(.plain)
                            }
                            .tint(annotation.kind.accentColor)
                        }
                    }
                }
                .onChange(of: viewModel.mapCenter) { _, center in
                    guard let center else {
                        mapPosition = .automatic
                        return
                    }

                    mapPosition = .region(
                        MKCoordinateRegion(
                            center: center.coordinate,
                            latitudinalMeters: 50_000,
                            longitudinalMeters: 50_000
                        )
                    )
                }
            }
        }
        .background(Color.surface(.canvas).ignoresSafeArea())
        .sheet(item: $selectedMapItem) { item in
            switch item {
            case .personal(let place):
                placeSheet(place)
            case .community(let annotation):
                communityPlaceSheet(annotation)
            }
        }
    }

    private var deniedRationale: some View {
        VStack(spacing: 12) {
            Text("Location is off.")
                .roadBeansStyle(.titleL)

            Text("Open Settings to enable nearby stops.")
                .roadBeansStyle(.bodyM)
                .foregroundStyle(.ink(.secondary))
                .multilineTextAlignment(.center)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var loadingLocationState: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Finding nearby stops...")
                .roadBeansStyle(.bodyM)
                .foregroundStyle(.ink(.secondary))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func currentLocationUnavailableState(_ viewModel: MapTabViewModel) -> some View {
        VStack(spacing: 16) {
            ContentUnavailableView(
                "Current Location Unavailable",
                systemImage: "location.slash",
                description: Text(viewModel.currentLocationErrorMessage ?? "Road Beans could not get your current location.")
            )

            Button("Try Again") {
                Task {
                    await viewModel.retryNearMe()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func placeSheet(_ place: PlaceSummary) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: RoadBeansSpacing.lg) {
                HStack(alignment: .top, spacing: RoadBeansSpacing.md) {
                    ZStack {
                        TopoShape(seed: TopoSeeds.emptyState, ringCount: 4, amplitude: 0.12, frequency: 4)
                            .stroke(place.kind.accentColor.opacity(0.22), lineWidth: 1)
                            .frame(width: 72, height: 72)

                        PlaceKindIcon(kind: place.kind)
                            .stroke(
                                place.kind.accentColor,
                                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                            )
                            .frame(width: 30, height: 30)
                    }

                    VStack(alignment: .leading, spacing: RoadBeansSpacing.xs) {
                        Text(place.name)
                            .roadBeansStyle(.titleL)
                            .foregroundStyle(.ink(.primary))
                            .lineLimit(2)

                        RoadBeansChip(title: place.kind.displayName, state: .default)
                    }

                    Spacer(minLength: RoadBeansSpacing.md)
                }

                if let averageRating = place.averageRating {
                    HStack {
                        Text("Average rating")
                            .roadBeansStyle(.labelM)
                            .foregroundStyle(.ink(.secondary))

                        Spacer()

                        BeanRatingView(value: .constant(averageRating), size: 18, editable: false)
                    }
                    .padding(RoadBeansSpacing.md)
                    .surface(.sunken, radius: RoadBeansRadius.md)
                }

                NavigationLink(value: place.id) {
                    Label("View Visits", systemImage: "chevron.right.circle.fill")
                        .roadBeansStyle(.label)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .background(Color.accent(.default), in: Capsule())
                        .foregroundStyle(Color.accent(.on))
                }
                .buttonStyle(.plain)
            }
            .padding(RoadBeansSpacing.lg)
            .roadBeansSurface(.base, tint: place.kind.accentColor)
            .padding()
            .navigationDestination(for: UUID.self) { id in
                PlaceDetailView(placeID: id)
            }
            .presentationDetents([.medium])
        }
    }

    private func communityPlaceSheet(_ annotation: CommunityPlaceAnnotation) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: RoadBeansSpacing.lg) {
                HStack(alignment: .top, spacing: RoadBeansSpacing.md) {
                    ZStack {
                        TopoShape(seed: TopoSeeds.emptyState, ringCount: 4, amplitude: 0.12, frequency: 4)
                            .stroke(annotation.kind.accentColor.opacity(0.22), lineWidth: 1)
                            .frame(width: 72, height: 72)

                        PlaceKindIcon(kind: annotation.kind)
                            .stroke(
                                annotation.kind.accentColor,
                                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                            )
                            .frame(width: 30, height: 30)
                    }

                    VStack(alignment: .leading, spacing: RoadBeansSpacing.xs) {
                        Text(annotation.name)
                            .roadBeansStyle(.titleL)
                            .foregroundStyle(.ink(.primary))
                            .lineLimit(2)

                        RoadBeansChip(title: annotation.kind.displayName, state: .default)
                    }

                    Spacer(minLength: RoadBeansSpacing.md)
                }

                HStack {
                    Text("Community rating")
                        .roadBeansStyle(.labelM)
                        .foregroundStyle(.ink(.secondary))

                    Spacer()

                    BeanRatingView(value: .constant(annotation.averageRating), size: 18, editable: false)
                }
                .padding(RoadBeansSpacing.md)
                .surface(.sunken, radius: RoadBeansRadius.md)
            }
            .padding(RoadBeansSpacing.lg)
            .roadBeansSurface(.base, tint: annotation.kind.accentColor)
            .padding()
            .presentationDetents([.medium])
        }
    }

    @MainActor
    private func fitCommunityContent(_ viewModel: MapTabViewModel) {
        var coordinates: [CLLocationCoordinate2D] = []
        coordinates.append(contentsOf: viewModel.places.compactMap(\.coordinate))
        coordinates.append(contentsOf: viewModel.communityAnnotations.map(\.coordinate))
        if let currentLocation = viewModel.currentLocation {
            coordinates.append(currentLocation.coordinate)
        }

        guard let first = coordinates.first else { return }
        guard coordinates.count > 1 else {
            mapPosition = .region(
                MKCoordinateRegion(
                    center: first,
                    latitudinalMeters: 25_000,
                    longitudinalMeters: 25_000
                )
            )
            return
        }

        let minLatitude = coordinates.map(\.latitude).min() ?? first.latitude
        let maxLatitude = coordinates.map(\.latitude).max() ?? first.latitude
        let minLongitude = coordinates.map(\.longitude).min() ?? first.longitude
        let maxLongitude = coordinates.map(\.longitude).max() ?? first.longitude
        let center = CLLocationCoordinate2D(
            latitude: (minLatitude + maxLatitude) / 2,
            longitude: (minLongitude + maxLongitude) / 2
        )
        let latitudeDelta = max((maxLatitude - minLatitude) * 1.5, 0.02)
        let longitudeDelta = max((maxLongitude - minLongitude) * 1.5, 0.02)
        mapPosition = .region(
            MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(
                    latitudeDelta: latitudeDelta,
                    longitudeDelta: longitudeDelta
                )
            )
        )
    }
}

private struct MapMarkerView: View {
    let kind: PlaceKind
    let rating: Double?

    var body: some View {
        VStack(spacing: RoadBeansSpacing.xs) {
            ZStack {
                Circle()
                    .fill(Color.surface(.raised))
                    .frame(width: 38, height: 38)
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                    .overlay {
                        Circle()
                            .stroke(kind.accentColor.opacity(0.38), lineWidth: 1.5)
                    }

                PlaceKindIcon(kind: kind)
                    .stroke(
                        kind.accentColor,
                        style: StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: 19, height: 19)
            }

            if let rating {
                Text(String(format: "%.1f", rating))
                    .roadBeansStyle(.labelM)
                    .padding(.horizontal, RoadBeansSpacing.sm)
                    .padding(.vertical, RoadBeansSpacing.xs)
                    .surface(.raised, radius: RoadBeansRadius.md)
                    .foregroundStyle(.ink(.primary))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(kind.displayName) stop")
        .accessibilityValue(rating.map { BeanRatingView.accessibilityValue($0) } ?? "No rating")
    }
}

private struct CommunityMapMarkerView: View {
    let kind: PlaceKind
    let rating: Double

    var body: some View {
        VStack(spacing: RoadBeansSpacing.xs) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(Color.surface(.raised))
                        .frame(width: 38, height: 38)
                        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                        .overlay {
                            Circle()
                                .stroke(kind.accentColor.opacity(0.38), lineWidth: 1.5)
                        }

                    PlaceKindIcon(kind: kind)
                        .stroke(
                            kind.accentColor,
                            style: StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round)
                        )
                        .frame(width: 19, height: 19)
                }

                ZStack {
                    Circle()
                        .fill(Color.surface(.canvas))
                        .overlay {
                            Circle().stroke(Color.divider(.hairline), lineWidth: 1)
                        }
                        .frame(width: 16, height: 16)

                    Image(systemName: "globe")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(Color.ink(.secondary))
                }
                .offset(x: 4, y: -4)
            }

            Text(String(format: "%.1f", rating))
                .roadBeansStyle(.labelM)
                .padding(.horizontal, RoadBeansSpacing.sm)
                .padding(.vertical, RoadBeansSpacing.xs)
                .surface(.raised, radius: RoadBeansRadius.md)
                .foregroundStyle(.ink(.primary))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(kind.displayName) community stop")
        .accessibilityValue(BeanRatingView.accessibilityValue(rating))
    }
}
