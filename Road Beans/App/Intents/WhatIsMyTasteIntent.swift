import AppIntents

struct WhatIsMyTasteIntent: AppIntent {
    static let title: LocalizedStringResource = "Show My Road Beans Taste"
    static let description = IntentDescription("Open Road Beans to the taste signals used for nearby picks.")
    static let supportedModes: IntentModes = .foreground(.dynamic)

    func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(AppRoute.tasteProfile.url))
    }
}
