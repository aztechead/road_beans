import AppIntents

struct OpenRecentVisitsIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Road Beans Visits"
    static let description = IntentDescription("Open Road Beans to your recent saved visits.")
    static let supportedModes: IntentModes = .foreground(.dynamic)

    func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(AppRoute.recentVisits.url))
    }
}
