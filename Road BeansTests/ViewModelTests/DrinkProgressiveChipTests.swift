import Foundation
import Testing
@testable import Road_Beans

@Suite("Progressive drink chips")
struct DrinkProgressiveChipTests {
    @Test func latteProgressesFromMilkToTemperature() throws {
        let groups = try #require(DrinkChipCatalog.groupsByCategory[.latte])

        #expect(groups.map(\.title).prefix(2) == ["Milk", "Temperature"])
        #expect(groups[0].options.contains("oat milk"))
        #expect(groups[1].options == ["hot", "iced"])
    }

    @Test func presetTagsAreNormalizedAndUnique() {
        let presets = DrinkChipCatalog.allPresetTags

        #expect(presets.contains("oat milk"))
        #expect(presets.contains("iced"))
        #expect(presets.contains("single origin"))
        #expect(presets.count == Set(presets).count)
    }

    @Test func latteFlavorDefaultsToNoFlavorAfterTemperatureSelection() throws {
        let groups = try #require(DrinkChipCatalog.groupsByCategory[.latte])
        var drink = DrinkDraft(name: "Latte", category: .latte, rating: 3, tags: ["oat milk"])

        DrinkChipLogic.select("iced", in: groups[1], nextGroup: groups[2], for: &drink)

        #expect(drink.tags.contains("iced"))
        #expect(drink.tags.contains("no flavor"))
    }

    @Test func customDrinkTypeUsesOtherCategoryAndEnteredName() {
        var drink = DrinkDraft(name: "", category: .drip, rating: 3, tags: ["light roast", "single origin"])

        DrinkChipLogic.addCustomDrinkType("Flat White", to: &drink)

        #expect(drink.name == "Flat White")
        #expect(drink.category == .other)
        #expect(drink.tags.isEmpty)
    }

    @Test func customDrinkTypeShowsCustomChipAndCustomGroups() {
        let drink = DrinkDraft(name: "Flat White", category: .other, rating: 3, tags: [])

        #expect(DrinkChipCatalog.customDrinkTypeName(for: drink) == "Flat White")
        #expect(DrinkChipCatalog.groups(for: drink).map(\.title).prefix(2) == ["Roast", "Origin"])
    }

    @Test func plainOtherKeepsGenericOtherGroups() {
        let drink = DrinkDraft(name: "Other", category: .other, rating: 3, tags: [])

        #expect(DrinkChipCatalog.customDrinkTypeName(for: drink) == nil)
        #expect(DrinkChipCatalog.groups(for: drink).map(\.title) == ["Temperature", "Style"])
    }

    @Test func customDrinkTypeStorePersistsUniqueLocalNames() {
        let suiteName = "DrinkProgressiveChipTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        CustomDrinkTypeStore.add("Flat White", defaults: defaults)
        CustomDrinkTypeStore.add(" flat white ", defaults: defaults)
        CustomDrinkTypeStore.add("Long Black", defaults: defaults)

        #expect(CustomDrinkTypeStore.load(defaults: defaults) == ["Flat White", "Long Black"])
    }

    @Test func customDrinkTypeStoreIgnoresBuiltInOtherName() {
        let suiteName = "DrinkProgressiveChipTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        CustomDrinkTypeStore.add("Other", defaults: defaults)

        #expect(CustomDrinkTypeStore.load(defaults: defaults).isEmpty)
    }
}
