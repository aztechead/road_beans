import SwiftUI

struct RootView: View {
    @Environment(PersistenceController.self) private var persistence
    @State private var selectedTab = AppTab.list
    @State private var isShowingAddVisit = false

    var body: some View {
        Group {
            switch persistence.mode {
            case .pendingRelaunch:
                RelaunchPromptView()
            case .pendingMigration:
                MigrationPromptView(keepLocalOnly: persistence.deferMigration)
            case .localOnly, .cloudKitBacked:
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
                PlaceListView()
                    .tabItem { Label("List", systemImage: "list.bullet") }
                    .tag(AppTab.list)

                MapTabView()
                    .tabItem { Label("Map", systemImage: "map.fill") }
                    .tag(AppTab.map)

                BackupSettingsView()
                    .tabItem { Label("Backup", systemImage: "externaldrive.fill") }
                    .tag(AppTab.backup)

                Color.clear
                    .tabItem { Label("Add", systemImage: "plus.circle.fill") }
                    .tag(AppTab.add)
            }
            .onChange(of: selectedTab) { _, newTab in
                guard newTab == .add else { return }
                isShowingAddVisit = true
                selectedTab = .list
            }
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
    case backup
    case add
}
