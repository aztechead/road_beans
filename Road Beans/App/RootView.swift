import SwiftUI

struct RootView: View {
    @Environment(PersistenceController.self) private var persistence
    @Environment(\.placeRepository) private var placeRepository
    @Environment(\.visitRepository) private var visitRepository
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab = AppTab.list
    @State private var isShowingAddVisit = false
    @State private var addVisitLaunchMode = AddVisitLaunchMode.standard
    @State private var spotlightIndexTask: Task<Void, Never>?

    var body: some View {
        Group {
            switch persistence.mode {
            case .iCloudUnavailable:
                ICloudRequiredView()
            case .pendingRelaunch:
                RelaunchPromptView()
            case .cloudKitBacked:
                tabs
            }
        }
        .onOpenURL { url in
            guard let route = AppRoute(url: url) else { return }
            handle(route)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            scheduleSpotlightReindex()
        }
        .onReceive(NotificationCenter.default.publisher(for: .roadBeansVisitSaved)) { _ in
            scheduleSpotlightReindex()
        }
        .onReceive(NotificationCenter.default.publisher(for: .roadBeansVisitDeleted)) { _ in
            scheduleSpotlightReindex()
        }
        .onReceive(NotificationCenter.default.publisher(for: .roadBeansPlaceUpdated)) { _ in
            scheduleSpotlightReindex()
        }
    }

    private var tabs: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                PlaceListView {
                    isShowingAddVisit = true
                }
                    .tabItem { Label("List", systemImage: "list.bullet") }
                    .tag(AppTab.list)

                MapTabView()
                    .tabItem { Label("Map", systemImage: "map.fill") }
                    .tag(AppTab.map)

                CommunityTabView()
                    .tabItem { Label("Community", systemImage: "person.3.fill") }
                    .tag(AppTab.community)
            }
            .tint(Color.accent(.default))
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarBackground(Color.surface(.raised), for: .tabBar)
            .toolbarColorScheme(.light, for: .tabBar)
            .background(Color.surface(.canvas).ignoresSafeArea())
            .fullScreenCover(isPresented: $isShowingAddVisit) {
                AddVisitView(launchMode: addVisitLaunchMode)
            }

            RootToastOverlay()
                .allowsHitTesting(false)
        }
    }

    private func handle(_ route: AppRoute) {
        switch route {
        case .addVisit:
            addVisitLaunchMode = .standard
            selectedTab = .list
            isShowingAddVisit = true
        case .quickLog:
            addVisitLaunchMode = .quickLogHere
            selectedTab = .list
            isShowingAddVisit = true
        case .recentVisits:
            selectedTab = .list
            isShowingAddVisit = false
        case .radar:
            selectedTab = .list
            isShowingAddVisit = false
            UserDefaults.standard.set(false, forKey: "recommendationsCollapsed")
        case .tasteProfile:
            selectedTab = .list
            isShowingAddVisit = false
            UserDefaults.standard.set(false, forKey: "recommendationsCollapsed")
        case .map:
            selectedTab = .map
            isShowingAddVisit = false
        }
    }

    private func scheduleSpotlightReindex() {
        guard persistence.mode == .cloudKitBacked else { return }
        spotlightIndexTask?.cancel()
        spotlightIndexTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            guard let places = try? await placeRepository.summaries(),
                  let visits = try? await visitRepository.recentRows(limit: 200) else {
                return
            }
            SpotlightIndexingService.shared.reindex(places: places, visits: visits)
        }
    }
}

private enum AppTab: Hashable {
    case list
    case map
    case community
}
