import AppIntents

struct OpenMapIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Road Beans Map"
    static let description = IntentDescription("Open Road Beans to the map of saved stops.")
    static let supportedModes: IntentModes = .foreground(.dynamic)

    func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(AppRoute.map.url))
    }
}
