import SwiftUI
import Testing
@testable import Road_Beans

@Suite("Domain enums")
struct EnumTests {
    @Test func placeKindRawValuesAreStable() {
        #expect(PlaceKind.coffeeShop.rawValue == "coffeeShop")
        #expect(PlaceKind.truckStop.rawValue == "truckStop")
        #expect(PlaceKind.gasStation.rawValue == "gasStation")
        #expect(PlaceKind.fastFood.rawValue == "fastFood")
        #expect(PlaceKind.other.rawValue == "other")
    }

    @Test func placeKindHasDisplayMetadata() {
        for kind in PlaceKind.allCases {
            #expect(!kind.displayName.isEmpty)
            #expect(!kind.sfSymbol.isEmpty)
        }
    }

    @Test func placeSourceRawValuesAreStable() {
        #expect(PlaceSource.mapKit.rawValue == "mapKit")
        #expect(PlaceSource.custom.rawValue == "custom")
    }

    @Test func drinkCategoryHasDisplayMetadata() {
        for category in DrinkCategory.allCases {
            #expect(!category.displayName.isEmpty)
            #expect(!category.sfSymbol.isEmpty)
        }
    }

    @Test func syncStateRawValuesAreStable() {
        #expect(SyncState.pendingUpload.rawValue == "pendingUpload")
        #expect(SyncState.synced.rawValue == "synced")
        #expect(SyncState.failed.rawValue == "failed")
    }
}
