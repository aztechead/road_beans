import Testing
@testable import Road_Beans

@Suite("BeanRatingView model")
struct BeanRatingViewTests {
    @Test func snapToHalfBean() {
        #expect(BeanRatingView.snap(2.34, granularity: 0.5) == 2.5)
        #expect(BeanRatingView.snap(2.20, granularity: 0.5) == 2.0)
        #expect(BeanRatingView.snap(0.0, granularity: 0.5) == 0.0)
        #expect(BeanRatingView.snap(5.4, granularity: 0.5) == 5.0)
    }

    @Test func dragLocationToRating() {
        #expect(BeanRatingView.rating(forDragX: 0, rowWidth: 100, range: 0...5, granularity: 0.5) == 0)
        #expect(BeanRatingView.rating(forDragX: 50, rowWidth: 100, range: 0...5, granularity: 0.5) == 2.5)
        #expect(BeanRatingView.rating(forDragX: 100, rowWidth: 100, range: 0...5, granularity: 0.5) == 5.0)
    }

    @Test func voiceOverTextForFractions() {
        #expect(BeanRatingView.accessibilityValue(0.0) == "0 of 5 beans")
        #expect(BeanRatingView.accessibilityValue(3.5) == "3 and a half of 5 beans")
        #expect(BeanRatingView.accessibilityValue(4.0) == "4 of 5 beans")
        #expect(BeanRatingView.accessibilityValue(2.25) == "2 and a quarter of 5 beans")
    }
}
