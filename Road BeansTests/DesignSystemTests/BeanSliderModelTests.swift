import Testing
@testable import Road_Beans

@Suite("BeanSliderModel")
struct BeanSliderModelTests {
    @Test func snapToStep() {
        #expect(BeanSliderModel.snap(0.123, step: 0.1) == 0.1)
        #expect(BeanSliderModel.snap(0.05, step: 0.1) == 0.1)
        #expect(BeanSliderModel.snap(0.04, step: 0.1) == 0.0)
        #expect(BeanSliderModel.snap(4.97, step: 0.1) == 5.0)
    }

    @Test func clampToRange() {
        #expect(BeanSliderModel.clamp(-0.5, range: 0...5) == 0)
        #expect(BeanSliderModel.clamp(7.0, range: 0...5) == 5)
        #expect(BeanSliderModel.clamp(2.5, range: 0...5) == 2.5)
    }

    @Test func crossedWholeBoundary() {
        #expect(BeanSliderModel.crossedWholeBoundary(from: 0.95, to: 1.05))
        #expect(!BeanSliderModel.crossedWholeBoundary(from: 1.05, to: 1.20))
        #expect(BeanSliderModel.crossedWholeBoundary(from: 4.99, to: 5.0))
    }

    @Test func accessibilityValueFormat() {
        #expect(BeanSliderModel.accessibilityValueText(3.6) == "3.6 of 5")
        #expect(BeanSliderModel.accessibilityValueText(0.0) == "0.0 of 5")
    }
}
