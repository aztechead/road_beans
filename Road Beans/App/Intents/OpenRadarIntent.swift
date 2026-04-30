import AppIntents

struct OpenRadarIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Road Beans Radar"
    static let description = IntentDescription("Open Road Beans to nearby picks based on your saved taste history.")
    static let supportedModes: IntentModes = .foreground(.dynamic)

    func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(AppRoute.radar.url))
    }
}
