import CoreGraphics
import SwiftUI
import Testing
@testable import Road_Beans

@Suite("Icon catalog")
struct IconCatalogTests {
    @Test func drinkIconsAreDistinct() {
        let rect = CGRect(x: 0, y: 0, width: 24, height: 24)
        let paths = DrinkCategory.allCases.map { DrinkIcon(category: $0).path(in: rect).description }

        #expect(Set(paths).count == DrinkCategory.allCases.count)
    }

    @Test func placeKindIconsAreDistinct() {
        let rect = CGRect(x: 0, y: 0, width: 24, height: 24)
        let paths = PlaceKind.allCases.map { PlaceKindIcon(kind: $0).path(in: rect).description }

        #expect(Set(paths).count == PlaceKind.allCases.count)
    }

    @Test func tasteProfileIconsAreDistinct() {
        let rect = CGRect(x: 0, y: 0, width: 24, height: 24)
        let paths = TasteAxis.allCases.map { TasteProfileIcon(axis: $0).path(in: rect).description }

        #expect(Set(paths).count == TasteAxis.allCases.count)
    }

    @Test func iconFactoryCoversEveryCase() {
        for category in DrinkCategory.allCases {
            _ = Icon(.drink(category), size: 24)
        }

        for kind in PlaceKind.allCases {
            _ = Icon(.place(kind), size: 24)
        }

        for axis in TasteAxis.allCases {
            _ = Icon(.taste(axis), size: 24)
        }
    }
}
