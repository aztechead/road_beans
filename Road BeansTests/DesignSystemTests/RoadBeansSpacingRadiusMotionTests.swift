import CoreGraphics
import Testing
@testable import Road_Beans

@Suite("RoadBeans spacing radius motion")
struct RoadBeansSpacingRadiusMotionTests {
    @Test func spacingUsesFourPointGridWithTwoPointMicroStep() {
        #expect(RoadBeansSpacing.xxs == CGFloat(2))
        #expect(RoadBeansSpacing.xs == CGFloat(4))
        #expect(RoadBeansSpacing.sm == CGFloat(8))
        #expect(RoadBeansSpacing.md == CGFloat(12))
        #expect(RoadBeansSpacing.lg == CGFloat(16))
        #expect(RoadBeansSpacing.xl == CGFloat(24))
        #expect(RoadBeansSpacing.xxl == CGFloat(32))
        #expect(RoadBeansSpacing.xxxl == CGFloat(48))
    }

    @Test func radiusExposesCanonicalValues() {
        #expect(RoadBeansRadius.sm == CGFloat(8))
        #expect(RoadBeansRadius.md == CGFloat(14))
        #expect(RoadBeansRadius.lg == CGFloat(18))
        #expect(RoadBeansRadius.sheet == CGFloat(24))
    }

    @Test func motionDurationsMatchSpec() {
        #expect(RoadBeansMotion.Duration.micro == 0.12)
        #expect(RoadBeansMotion.Duration.short == 0.20)
        #expect(RoadBeansMotion.Duration.medium == 0.30)
        #expect(RoadBeansMotion.Duration.long == 0.50)
    }
}
