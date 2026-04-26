import Foundation

enum OnboardingState {
    static let storageKey = "roadBeans.onboarding.completed"

    static func isCompleted(in defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: storageKey)
    }

    static func markCompleted(in defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: storageKey)
    }

    static func reset(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: storageKey)
    }
}
