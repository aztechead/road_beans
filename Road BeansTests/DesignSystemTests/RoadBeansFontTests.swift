import SwiftUI
import Testing
@testable import Road_Beans

@Suite("RoadBeansFont")
struct RoadBeansFontTests {
    @Test func everyStyleProducesAFont() {
        for style in RoadBeansFont.Style.allCases {
            _ = style.font
        }
    }

    @Test func exposesTwelveCoreStyles() {
        #expect(RoadBeansFont.Style.allCases.count == 12)
    }

    @Test func eyebrowIsUppercase() {
        #expect(RoadBeansFont.Style.eyebrow.transformsToUppercase)
    }

    @Test func displayStylesCapDynamicType() {
        #expect(RoadBeansFont.Style.displayXL.maxDynamicTypeSize == .accessibility3)
        #expect(RoadBeansFont.Style.numericDisplay.maxDynamicTypeSize == .accessibility3)
        #expect(RoadBeansFont.Style.bodyL.maxDynamicTypeSize == nil)
    }
}
