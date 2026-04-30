import AppIntents

struct RoadBeansShortcuts: AppShortcutsProvider {
    static let shortcutTileColor: ShortcutTileColor = .grayBrown

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenAddVisitIntent(),
            phrases: [
                "Log a visit in \(.applicationName)",
                "Add a stop in \(.applicationName)",
                "Log coffee in \(.applicationName)"
            ],
            shortTitle: "Add Visit",
            systemImageName: "plus.circle.fill"
        )

        AppShortcut(
            intent: QuickLogHereIntent(),
            phrases: [
                "Quick log here in \(.applicationName)",
                "Log this stop in \(.applicationName)"
            ],
            shortTitle: "Quick Log",
            systemImageName: "bolt.fill"
        )

        AppShortcut(
            intent: OpenRadarIntent(),
            phrases: [
                "Show Radar in \(.applicationName)",
                "Show my nearby picks in \(.applicationName)"
            ],
            shortTitle: "Radar",
            systemImageName: "sparkles"
        )

        AppShortcut(
            intent: FindNearbyCoffeeIntent(),
            phrases: [
                "Find nearby coffee in \(.applicationName)",
                "Find a coffee stop in \(.applicationName)"
            ],
            shortTitle: "Nearby Coffee",
            systemImageName: "location.magnifyingglass"
        )

        AppShortcut(
            intent: WhatIsMyTasteIntent(),
            phrases: [
                "Show my taste in \(.applicationName)",
                "What is my Road Beans taste in \(.applicationName)"
            ],
            shortTitle: "My Taste",
            systemImageName: "person.text.rectangle"
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
