import AppIntents

struct QuickLogHereIntent: AppIntent {
    static let title: LocalizedStringResource = "Quick Log Here"
    static let description = IntentDescription("Open Road Beans with the nearest saved stop and a minimal drink ready to rate.")
    static let supportedModes: IntentModes = .foreground(.dynamic)

    func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(AppRoute.quickLog.url))
    }
}
