import CoreGraphics
import SwiftUI
import Testing
@testable import Road_Beans

@Suite("TopoShape")
struct TopoShapeTests {
    @Test func deterministicForSameSeed() {
        let shape = TopoShape(seed: 42, ringCount: 7, amplitude: 0.1, frequency: 3)
        let rect = CGRect(x: 0, y: 0, width: 200, height: 200)

        #expect(shape.path(in: rect).description == shape.path(in: rect).description)
    }

    @Test func differentSeedsDiffer() {
        let rect = CGRect(x: 0, y: 0, width: 200, height: 200)
        let first = TopoShape(seed: 1, ringCount: 7, amplitude: 0.1, frequency: 3).path(in: rect)
        let second = TopoShape(seed: 2, ringCount: 7, amplitude: 0.1, frequency: 3).path(in: rect)

        #expect(first.description != second.description)
    }

    @Test func canonicalSeedsAreStable() {
        #expect(TopoSeeds.onboarding != TopoSeeds.emptyState)
        #expect(TopoSeeds.profileHeader != TopoSeeds.appIcon)
    }
}
