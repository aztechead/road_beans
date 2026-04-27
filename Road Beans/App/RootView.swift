import SwiftUI

struct RootView: View {
    @Environment(PersistenceController.self) private var persistence
    @State private var selectedTab = AppTab.list
    @State private var isShowingAddVisit = false

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
                AddVisitView()
            }

            RootToastOverlay()
                .allowsHitTesting(false)
        }
    }

    private func handle(_ route: AppRoute) {
        switch route {
        case .addVisit:
            selectedTab = .list
            isShowingAddVisit = true
        case .recentVisits:
            selectedTab = .list
            isShowingAddVisit = false
        case .map:
            selectedTab = .map
            isShowingAddVisit = false
        }
    }
}

private enum AppTab: Hashable {
    case list
    case map
    case community
}
