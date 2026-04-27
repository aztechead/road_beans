import CoreGraphics
import Testing
@testable import Road_Beans

@Suite("RoadBeans tokens")
struct RoadBeansTokenTests {
    @Test func typographyExposesTwelveStyles() {
        #expect(RoadBeansFont.Style.allCases.count == 12)
    }

    @Test func spacingScaleKeepsExistingValuesStable() {
        #expect(RoadBeansSpacing.xs == CGFloat(4))
        #expect(RoadBeansSpacing.sm == CGFloat(8))
        #expect(RoadBeansSpacing.md == CGFloat(12))
        #expect(RoadBeansSpacing.lg == CGFloat(16))
    }

    @Test func drinkCategoriesExposeDesignSystemIcons() {
        #expect(DrinkCategory.allCases.count == 7)

        for category in DrinkCategory.allCases {
            _ = Icon(.drink(category), size: 24)
        }
    }

    @Test func tasteAxesExposeDesignSystemIcons() {
        for axis in TasteAxis.allCases {
            _ = Icon(.taste(axis), size: 24)
        }
    }
}
