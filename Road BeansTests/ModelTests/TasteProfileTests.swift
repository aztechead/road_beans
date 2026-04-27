import Foundation
import Testing
@testable import Road_Beans

@Suite("TasteProfile")
struct TasteProfileTests {
    @Test func midpointHasAllAxesAtHalf() {
        let profile = TasteProfile.midpoint

        for axis in TasteAxis.allCases {
            #expect(profile.value(for: axis) == 0.5)
        }
    }

    @Test func valuesAreClamped() {
        var profile = TasteProfile.midpoint

        profile.set(2.0, for: .roast)
        profile.set(-1.0, for: .body)

        #expect(profile.value(for: .roast) == 1.0)
        #expect(profile.value(for: .body) == 0.0)
    }

    @Test func roundTripsThroughJSON() throws {
        var profile = TasteProfile.midpoint
        profile.set(0.8, for: .roast)
        profile.set(0.2, for: .flavor)

        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(TasteProfile.self, from: data)

        #expect(decoded == profile)
    }
}
