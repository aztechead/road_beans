import Foundation
import Testing
@testable import Road_Beans

@Suite("OnboardingState")
struct OnboardingStateTests {
    @Test func completionPersistsInDefaults() throws {
        let defaults = try #require(UserDefaults(suiteName: "RoadBeans.OnboardingStateTests"))
        OnboardingState.reset(in: defaults)

        #expect(OnboardingState.isCompleted(in: defaults) == false)

        OnboardingState.markCompleted(in: defaults)

        #expect(OnboardingState.isCompleted(in: defaults))
        OnboardingState.reset(in: defaults)
    }
}
