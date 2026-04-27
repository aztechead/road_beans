import Testing
@testable import Road_Beans

@Suite("BeanMark")
struct BeanMarkTests {
    @Test func fractionForEachState() {
        #expect(BeanMark.State.empty.fraction == 0.00)
        #expect(BeanMark.State.quarter.fraction == 0.25)
        #expect(BeanMark.State.half.fraction == 0.50)
        #expect(BeanMark.State.threeQuarter.fraction == 0.75)
        #expect(BeanMark.State.full.fraction == 1.00)
    }

    @Test func stateForRatingValue() {
        #expect(BeanMark.state(forRating: 0.0, position: 0) == .empty)
        #expect(BeanMark.state(forRating: 0.5, position: 0) == .half)
        #expect(BeanMark.state(forRating: 1.0, position: 0) == .full)
        #expect(BeanMark.state(forRating: 3.5, position: 3) == .half)
        #expect(BeanMark.state(forRating: 3.5, position: 4) == .empty)
        #expect(BeanMark.state(forRating: 4.25, position: 4) == .quarter)
    }
}
