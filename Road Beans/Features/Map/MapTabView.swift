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
                guard let viewModel else { return }
                await viewModel.refreshPermissionStatus()
                if viewModel.nearMeOn {
                    await viewModel.reload(allowingNearMe: true)
                }
                guard viewModel.communityReviewsOn else { return }
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
            MapLayerControlPanel(
                nearMeOn: viewModel.nearMeOn,
                communityReviewsOn: viewModel.communityReviewsOn,
                isCommunityMember: viewModel.isCommunityMember,
                isLoadingCommunity: viewModel.communityLoadState == .loading,
                personalCount: viewModel.places.count,
                communityCount: viewModel.communityAnnotations.reduce(0) { $0 + $1.reviewCount },
                onToggleNearMe: {
                    viewModel.nearMeOn.toggle()
                },
                onToggleCommunity: {
                    viewModel.communityReviewsOn.toggle()
                }
            )
            .padding(.horizontal, RoadBeansSpacing.md)
            .padding(.top, RoadBeansSpacing.sm)
            .padding(.bottom, RoadBeansSpacing.xs)

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
                .clipShape(RoundedRectangle(cornerRadius: RoadBeansRadius.lg, style: .continuous))
                .padding(.horizontal, RoadBeansSpacing.md)
                .padding(.bottom, RoadBeansSpacing.md)
            }
        }
        .background(Color.surface(.canvas).ignoresSafeArea())
        .onChange(of: viewModel.nearMeOn) { _, isOn in
            Task {
                if isOn {
                    await viewModel.requestPermissionIfNeeded()
                }
                await viewModel.reload(allowingNearMe: isOn)
            }
        }
        .onChange(of: viewModel.communityReviewsOn) { _, isOn in
            Task {
                await viewModel.reloadCommunityAnnotations(enabled: isOn)
                guard isOn, viewModel.communityReviewsOn else { return }
                await MainActor.run {
                    fitCommunityContent(viewModel)
                }
            }
        }
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

                    if let coordinate = place.coordinate {
                        Button {
                            openRouteInMaps(name: place.name, coordinate: coordinate)
                        } label: {
                            Image(systemName: "map.fill")
                                .font(.headline)
                                .frame(width: 44, height: 44)
                                .background(Color.accent(.default), in: Circle())
                                .foregroundStyle(Color.accent(.on))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Route to \(place.name)")
                    }
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
                    Label("View all \(place.visitCount) review\(place.visitCount == 1 ? "" : "s")", systemImage: "text.bubble.fill")
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
            ScrollView {
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

                        Button {
                            openRouteInMaps(name: annotation.name, coordinate: annotation.coordinate)
                        } label: {
                            Image(systemName: "map.fill")
                                .font(.headline)
                                .frame(width: 44, height: 44)
                                .background(Color.accent(.default), in: Circle())
                                .foregroundStyle(Color.accent(.on))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Route to \(annotation.name)")
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

                    VStack(alignment: .leading, spacing: RoadBeansSpacing.sm) {
                        Text("\(annotation.reviewCount) community review\(annotation.reviewCount == 1 ? "" : "s")")
                            .roadBeansStyle(.caption)
                            .foregroundStyle(.ink(.secondary))

                        ForEach(annotation.reviews) { review in
                            NavigationLink(value: review.id) {
                                CommunityMapReviewRow(review: review)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(RoadBeansSpacing.lg)
                .roadBeansSurface(.base, tint: annotation.kind.accentColor)
            }
            .padding()
            .navigationDestination(for: String.self) { recordName in
                CommunityVisitDetailView(recordName: recordName)
            }
            .presentationDetents([.medium])
        }
    }

    private func openRouteInMaps(name: String, coordinate: CLLocationCoordinate2D) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "maps.apple.com"
        components.queryItems = [
            URLQueryItem(name: "daddr", value: "\(coordinate.latitude),\(coordinate.longitude)"),
            URLQueryItem(name: "q", value: name)
        ]

        if let url = components.url {
            UIApplication.shared.open(url)
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

private struct MapLayerControlPanel: View {
    let nearMeOn: Bool
    let communityReviewsOn: Bool
    let isCommunityMember: Bool
    let isLoadingCommunity: Bool
    let personalCount: Int
    let communityCount: Int
    let onToggleNearMe: () -> Void
    let onToggleCommunity: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: RoadBeansSpacing.md) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Map lens")
                        .roadBeansStyle(.caption)
                        .foregroundStyle(.ink(.tertiary))

                    Text(activeSummary)
                        .roadBeansStyle(.headline)
                        .foregroundStyle(.ink(.primary))
                }

                Spacer()

                Image(systemName: "scope")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.accent(.default))
            }

            HStack(spacing: RoadBeansSpacing.sm) {
                MapLayerButton(
                    title: "Near me",
                    detail: nearMeOn ? "\(personalCount) stop\(personalCount == 1 ? "" : "s")" : nil,
                    systemImage: "location.fill",
                    isSelected: nearMeOn,
                    isLoading: false,
                    action: onToggleNearMe
                )

                if isCommunityMember {
                    MapLayerButton(
                        title: "Community",
                        detail: communityReviewsOn || isLoadingCommunity
                            ? "\(communityCount) review\(communityCount == 1 ? "" : "s")"
                            : nil,
                        systemImage: "person.2.fill",
                        isSelected: communityReviewsOn,
                        isLoading: isLoadingCommunity,
                        action: onToggleCommunity
                    )
                }
            }
        }
        .padding(RoadBeansSpacing.md)
        .roadBeansSurface(.elevated, tint: Color.accent(.default))
    }

    private var activeSummary: String {
        switch (nearMeOn, communityReviewsOn && isCommunityMember) {
        case (true, true):
            "Nearby stops plus trusted reviews"
        case (true, false):
            "Stops around your current route"
        case (false, true):
            "Community-tested places"
        case (false, false):
            "Your saved Road Beans stops"
        }
    }
}

private struct MapLayerButton: View {
    let title: String
    let detail: String?
    let systemImage: String
    let isSelected: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: RoadBeansSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.accent(.default) : Color.surface(.sunken))
                        .frame(width: 34, height: 34)

                    if isLoading {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Image(systemName: systemImage)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(isSelected ? Color.accent(.on) : Color.ink(.secondary))
                    }
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .roadBeansStyle(.labelM)
                        .foregroundStyle(.ink(.primary))

                    if let detail {
                        Text(detail)
                            .roadBeansStyle(.caption)
                            .foregroundStyle(.ink(.secondary))
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(RoadBeansSpacing.sm)
            .frame(maxWidth: .infinity)
            .background(
                isSelected ? Color.accent(.default).opacity(0.12) : Color.surface(.sunken),
                in: RoundedRectangle(cornerRadius: RoadBeansRadius.md, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: RoadBeansRadius.md, style: .continuous)
                    .stroke(isSelected ? Color.accent(.default).opacity(0.45) : Color.divider(.hairline), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

private struct CommunityMapReviewRow: View {
    let review: CommunityVisitRow

    var body: some View {
        HStack(alignment: .top, spacing: RoadBeansSpacing.sm) {
            VStack(alignment: .leading, spacing: RoadBeansSpacing.xs) {
                HStack {
                    Text(review.authorDisplayName)
                        .roadBeansStyle(.labelM)
                        .foregroundStyle(.ink(.primary))

                    Spacer()

                    BeanRatingView(value: .constant(review.beanRating), size: 14, editable: false)
                }

                Text(review.drinkSummary.isEmpty ? "Community visit" : review.drinkSummary)
                    .roadBeansStyle(.bodyS)
                    .foregroundStyle(.ink(.secondary))
                    .lineLimit(2)

                if !review.tagSummary.isEmpty {
                    Text(review.tagSummary)
                        .roadBeansStyle(.caption)
                        .foregroundStyle(.ink(.tertiary))
                        .lineLimit(1)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.ink(.tertiary))
                .padding(.top, 4)
        }
        .padding(RoadBeansSpacing.md)
        .surface(.sunken, radius: RoadBeansRadius.md)
        .accessibilityElement(children: .combine)
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
