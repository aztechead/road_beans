import AppIntents

struct OpenAddVisitIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Road Beans Visit"
    static let description = IntentDescription("Open Road Beans directly to the add visit flow.")
    static let supportedModes: IntentModes = .foreground(.dynamic)

    func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(AppRoute.addVisit.url))
    }
}
