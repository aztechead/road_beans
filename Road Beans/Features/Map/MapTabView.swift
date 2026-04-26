import MapKit
import SwiftUI
import UIKit

struct MapTabView: View {
    @Environment(\.placeRepository) private var placeRepository
    @Environment(\.locationPermissionService) private var permissionService
    @Environment(\.currentLocationProvider) private var currentLocationProvider
    @State private var viewModel: MapTabViewModel?
    @State private var selectedPlace: PlaceSummary?
    @State private var mapPosition: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    content(viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Map")
        }
        .task {
            guard viewModel == nil else { return }
            let model = MapTabViewModel(
                places: placeRepository,
                permission: permissionService,
                currentLocation: currentLocationProvider
            )
            viewModel = model
            await model.refreshPermissionStatus()
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

            if viewModel.isLoadingCurrentLocation {
                loadingLocationState
            } else if viewModel.nearMeOn && (viewModel.permissionStatus == .denied || viewModel.permissionStatus == .restricted) {
                deniedRationale
            } else if viewModel.currentLocationUnavailable {
                currentLocationUnavailableState(viewModel)
            } else {
                Map(position: $mapPosition) {
                    if viewModel.currentLocation != nil {
                        UserAnnotation()
                    }

                    ForEach(viewModel.places) { place in
                        if let coordinate = place.coordinate {
                            Annotation(place.name, coordinate: coordinate) {
                                Button {
                                    selectedPlace = place
                                } label: {
                                    Image(systemName: place.kind.sfSymbol)
                                        .padding(8)
                                        .background(place.kind.accentColor, in: Circle())
                                        .foregroundStyle(.white)
                                }
                                .buttonStyle(.plain)
                            }
                            .tint(place.kind.accentColor)
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
        .sheet(item: $selectedPlace) { place in
            placeSheet(place)
        }
    }

    private var deniedRationale: some View {
        VStack(spacing: 12) {
            Text("Location is off.")
                .font(.roadBeansHeadline)

            Text("Open Settings to enable nearby stops.")
                .font(.roadBeansBody)
                .foregroundStyle(.secondary)
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
                .font(.roadBeansBody)
                .foregroundStyle(.secondary)
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
            VStack(alignment: .leading, spacing: 12) {
                Text(place.name)
                    .font(.roadBeansHeadline)

                PlaceKindStyle.badge(for: place.kind)

                if let averageRating = place.averageRating {
                    BeanRating(value: averageRating, pixelSize: 3)
                }

                NavigationLink("View visits", value: place.id)
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .glassCard(tint: place.kind.accentColor)
            .padding()
            .navigationDestination(for: UUID.self) { id in
                PlaceDetailView(placeID: id)
            }
            .presentationDetents([.medium])
        }
    }
}
