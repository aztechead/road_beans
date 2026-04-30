import AppIntents

struct FindNearbyCoffeeIntent: AppIntent {
    static let title: LocalizedStringResource = "Find Nearby Coffee"
    static let description = IntentDescription("Open Road Beans Radar to find nearby coffee and road stops.")
    static let supportedModes: IntentModes = .foreground(.dynamic)

    func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(AppRoute.radar.url))
    }
}
