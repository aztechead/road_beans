// Road BeansTests/DesignSystemTests/RoadBeansColorTests.swift
import Testing
import SwiftUI
import UIKit
@testable import Road_Beans

@Suite("RoadBeansColor")
struct RoadBeansColorTests {
    @Test func everySurfaceTokenResolves() {
        for token in RoadBeansColor.Surface.allCases {
            #expect(UIColor(named: token.assetName, in: .main, compatibleWith: nil) != nil,
                    "Missing colorset: \(token.assetName)")
        }
    }

    @Test func everyInkTokenResolves() {
        for token in RoadBeansColor.Ink.allCases {
            #expect(UIColor(named: token.assetName, in: .main, compatibleWith: nil) != nil,
                    "Missing colorset: \(token.assetName)")
        }
    }

    @Test func everyAccentTokenResolves() {
        for token in RoadBeansColor.Accent.allCases {
            #expect(UIColor(named: token.assetName, in: .main, compatibleWith: nil) != nil,
                    "Missing colorset: \(token.assetName)")
        }
    }

    @Test func everyDividerTokenResolves() {
        for token in RoadBeansColor.Divider.allCases {
            #expect(UIColor(named: token.assetName, in: .main, compatibleWith: nil) != nil,
                    "Missing colorset: \(token.assetName)")
        }
    }

    @Test func everyStateTokenResolves() {
        for token in RoadBeansColor.State.allCases {
            #expect(UIColor(named: token.assetName, in: .main, compatibleWith: nil) != nil,
                    "Missing colorset: \(token.assetName)")
        }
    }
}
