import AppIntents

struct RoadBeansShortcuts: AppShortcutsProvider {
    static let shortcutTileColor: ShortcutTileColor = .grayBrown

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenAddVisitIntent(),
            phrases: [
                "Add a stop in \(.applicationName)",
                "Log coffee in \(.applicationName)"
            ],
            shortTitle: "Add Visit",
            systemImageName: "plus.circle.fill"
        )

        AppShortcut(
            intent: OpenRecentVisitsIntent(),
            phrases: [
                "Open recent visits in \(.applicationName)",
                "Show my road beans in \(.applicationName)"
            ],
            shortTitle: "Recent Visits",
            systemImageName: "cup.and.saucer.fill"
        )

        AppShortcut(
            intent: OpenMapIntent(),
            phrases: [
                "Show my Road Beans map in \(.applicationName)",
                "Open the map in \(.applicationName)"
            ],
            shortTitle: "Map",
            systemImageName: "map.fill"
        )
    }
}
