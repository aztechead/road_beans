import SwiftUI

struct DrinkProgressiveChips: View {
    @Binding var drink: DrinkDraft
    @State private var customChipTarget: CustomChipTarget?
    @State private var customChipText = ""
    @State private var customDrinkTypeNames = CustomDrinkTypeStore.load()

    var body: some View {
        VStack(alignment: .leading, spacing: RoadBeansSpacing.md) {
            categoryRow

            ForEach(visibleGroups) { group in
                chipGroup(group)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            customChipEntry
        }
        .animation(RoadBeansMotion.soft, value: visibleGroups.map(\.id))
        .animation(RoadBeansMotion.soft, value: drink.tags)
    }

    private var categoryRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RoadBeansSpacing.sm) {
                ForEach(DrinkCategory.allCases, id: \.self) { category in
                    Button {
                        selectCategory(category)
                    } label: {
                        HStack(spacing: RoadBeansSpacing.xs) {
                            Icon(.drink(category), size: 16, active: isSelected(category))
                            Text(category.displayName)
                        }
                        .roadBeansStyle(.labelM)
                        .padding(.horizontal, RoadBeansSpacing.md)
                        .padding(.vertical, 6)
                        .background(isSelected(category) ? Color.accent(.default) : Color.clear, in: Capsule())
                        .foregroundStyle(isSelected(category) ? Color.accent(.on) : Color.ink(.secondary))
                        .overlay {
                            if !isSelected(category) {
                                Capsule().stroke(Color.divider(.strong), lineWidth: 1)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected(category) ? [.isSelected] : [])
                }

                if let customDrinkTypeName {
                    RoadBeansChip(
                        title: customDrinkTypeName,
                        systemImage: "cup.and.saucer.fill",
                        isSelected: true
                    )
                }

                ForEach(customDrinkTypeNames.filter { $0 != customDrinkTypeName }, id: \.self) { name in
                    RoadBeansChip(
                        title: name,
                        systemImage: "cup.and.saucer.fill",
                        isSelected: false,
                        action: {
                            DrinkChipLogic.addCustomDrinkType(name, to: &drink)
                        }
                    )
                }

                RoadBeansChip(
                    title: "Add chip",
                    systemImage: "plus",
                    action: {
                        customChipTarget = .drinkType
                    }
                )
            }
        }
    }

    private var visibleGroups: [DrinkChipGroup] {
        let groups = DrinkChipCatalog.groups(for: drink)
        var visible: [DrinkChipGroup] = []

        for group in groups {
            visible.append(group)
            if selectedOption(in: group) == nil {
                break
            }
        }

        return visible
    }

    private func chipGroup(_ group: DrinkChipGroup) -> some View {
        VStack(alignment: .leading, spacing: RoadBeansSpacing.xs) {
            Text(group.title)
                .roadBeansStyle(.caption)
                .foregroundStyle(.ink(.secondary))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: RoadBeansSpacing.sm) {
                    ForEach(group.options, id: \.self) { option in
                        RoadBeansChip(
                            title: option,
                            isSelected: hasTag(option),
                            action: {
                                select(option, in: group, nextGroup: nextGroup(after: group))
                            }
                        )
                    }

                    RoadBeansChip(
                        title: "Add chip",
                        systemImage: "plus",
                        action: {
                            customChipTarget = .detail
                        }
                    )
                }
            }
        }
    }

    @ViewBuilder private var customChipEntry: some View {
        if let customChipTarget {
            HStack(spacing: RoadBeansSpacing.sm) {
                RoadBeansClearableTextField(
                    customChipTarget.placeholder,
                    text: $customChipText,
                    autocapitalization: .never,
                    autocorrectionDisabled: true,
                    onSubmit: addCustomChip
                )
                .padding(RoadBeansSpacing.md)
                .surface(.sunken, radius: RoadBeansRadius.md)

                Button {
                    addCustomChip()
                } label: {
                    Image(systemName: "checkmark")
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.bordered)
                .disabled(customChipText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button {
                    customChipText = ""
                    self.customChipTarget = nil
                } label: {
                    Image(systemName: "xmark")
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Cancel custom chip")
            }
        }
    }

    private func selectCategory(_ category: DrinkCategory) {
        guard drink.category != category else { return }
        drink.category = category
        removePresetTags()

        drink.name = category.displayName
    }

    private func select(_ option: String, in group: DrinkChipGroup, nextGroup: DrinkChipGroup?) {
        DrinkChipLogic.select(option, in: group, nextGroup: nextGroup, for: &drink)
    }

    private func addCustomChip() {
        switch customChipTarget {
        case .drinkType:
            let savedName = CustomDrinkTypeStore.add(customChipText)
            DrinkChipLogic.addCustomDrinkType(savedName ?? customChipText, to: &drink)
            customDrinkTypeNames = CustomDrinkTypeStore.load()
        case .detail:
            TagTokenLogic.add(customChipText, to: &drink.tags)
        case nil:
            break
        }
        customChipText = ""
        customChipTarget = nil
    }

    private func selectedOption(in group: DrinkChipGroup) -> String? {
        group.options.first(where: hasTag(_:))
    }

    private func hasTag(_ option: String) -> Bool {
        let normalized = LocalTagRepository.normalize(option)
        return drink.tags.contains { LocalTagRepository.normalize($0) == normalized }
    }

    private func removePresetTags() {
        let presetTags = DrinkChipCatalog.allPresetTags
        drink.tags.removeAll { presetTags.contains(LocalTagRepository.normalize($0)) }
    }

    private func nextGroup(after group: DrinkChipGroup) -> DrinkChipGroup? {
        let groups = DrinkChipCatalog.groups(for: drink)
        guard
              let index = groups.firstIndex(of: group),
              groups.indices.contains(index + 1) else {
            return nil
        }
        return groups[index + 1]
    }

    private var customDrinkTypeName: String? {
        DrinkChipCatalog.customDrinkTypeName(for: drink)
    }

    private func isSelected(_ category: DrinkCategory) -> Bool {
        guard drink.category == category else { return false }
        return category != .other || customDrinkTypeName == nil
    }
}

enum CustomDrinkTypeStore {
    static let storageKey = "customDrinkTypes"

    @discardableResult
    static func add(_ raw: String, defaults: UserDefaults = .standard) -> String? {
        guard let normalizedName = normalizedName(raw) else { return nil }
        var names = load(defaults: defaults)
        guard !names.contains(where: { LocalTagRepository.normalize($0) == LocalTagRepository.normalize(normalizedName) }) else {
            return names.first { LocalTagRepository.normalize($0) == LocalTagRepository.normalize(normalizedName) }
        }
        names.append(normalizedName)
        defaults.set(names, forKey: storageKey)
        return normalizedName
    }

    static func load(defaults: UserDefaults = .standard) -> [String] {
        let rawNames = defaults.stringArray(forKey: storageKey) ?? []
        var seen: Set<String> = []
        var names: [String] = []

        for rawName in rawNames {
            guard let normalizedName = normalizedName(rawName) else { continue }
            let key = LocalTagRepository.normalize(normalizedName)
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            names.append(normalizedName)
        }

        if names != rawNames {
            defaults.set(names, forKey: storageKey)
        }
        return names
    }

    private static func normalizedName(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              LocalTagRepository.normalize(trimmed) != LocalTagRepository.normalize(DrinkCategory.other.displayName) else {
            return nil
        }
        return trimmed
    }
}

struct DrinkChipGroup: Identifiable, Hashable {
    let id: String
    let title: String
    let options: [String]
    var defaultOption: String?
}

enum DrinkChipLogic {
    static func select(_ option: String, in group: DrinkChipGroup, nextGroup: DrinkChipGroup?, for drink: inout DrinkDraft) {
        replaceSelection(with: option, in: group, for: &drink)

        guard let nextGroup,
              let defaultOption = nextGroup.defaultOption,
              selectedOption(in: nextGroup, for: drink) == nil else {
            return
        }
        replaceSelection(with: defaultOption, in: nextGroup, for: &drink)
    }

    static func addCustomDrinkType(_ raw: String, to drink: inout DrinkDraft) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        drink.category = .other
        drink.name = trimmed
        removePresetTags(from: &drink)
    }

    private static func replaceSelection(with option: String, in group: DrinkChipGroup, for drink: inout DrinkDraft) {
        let normalizedOptions = Set(group.options.map(LocalTagRepository.normalize(_:)))
        drink.tags.removeAll { normalizedOptions.contains(LocalTagRepository.normalize($0)) }
        TagTokenLogic.add(option, to: &drink.tags)
    }

    private static func selectedOption(in group: DrinkChipGroup, for drink: DrinkDraft) -> String? {
        group.options.first { option in
            let normalized = LocalTagRepository.normalize(option)
            return drink.tags.contains { LocalTagRepository.normalize($0) == normalized }
        }
    }

    private static func removePresetTags(from drink: inout DrinkDraft) {
        let presetTags = DrinkChipCatalog.allPresetTags
        drink.tags.removeAll { presetTags.contains(LocalTagRepository.normalize($0)) }
    }
}

private enum CustomChipTarget {
    case drinkType
    case detail

    var placeholder: String {
        switch self {
        case .drinkType:
            "Drink type"
        case .detail:
            "Custom chip"
        }
    }
}

enum DrinkChipCatalog {
    static let customDrinkGroups: [DrinkChipGroup] = [
        DrinkChipGroup(id: "custom-roast", title: "Roast", options: ["light roast", "medium roast", "dark roast"]),
        DrinkChipGroup(id: "custom-origin", title: "Origin", options: ["single origin", "blend", "decaf"]),
        DrinkChipGroup(id: "custom-temperature", title: "Temperature", options: ["hot", "iced"]),
        DrinkChipGroup(id: "custom-serve", title: "Serve", options: ["black", "with milk", "to go"])
    ]

    static let groupsByCategory: [DrinkCategory: [DrinkChipGroup]] = [
        .latte: [
            DrinkChipGroup(id: "latte-milk", title: "Milk", options: ["whole milk", "oat milk", "almond milk", "soy milk", "macadamia milk"]),
            DrinkChipGroup(id: "latte-temperature", title: "Temperature", options: ["hot", "iced"]),
            DrinkChipGroup(id: "latte-flavor", title: "Flavor", options: ["no flavor", "vanilla", "honey", "seasonal"], defaultOption: "no flavor")
        ],
        .cappuccino: [
            DrinkChipGroup(id: "cappuccino-milk", title: "Milk", options: ["whole milk", "oat milk", "almond milk", "soy milk"]),
            DrinkChipGroup(id: "cappuccino-style", title: "Style", options: ["dry", "wet", "traditional"]),
            DrinkChipGroup(id: "cappuccino-temperature", title: "Temperature", options: ["hot", "iced"])
        ],
        .coldBrew: [
            DrinkChipGroup(id: "cold-brew-style", title: "Style", options: ["still", "nitro", "concentrate"]),
            DrinkChipGroup(id: "cold-brew-milk", title: "Milk", options: ["black", "whole milk", "oat milk", "cream"]),
            DrinkChipGroup(id: "cold-brew-sweetness", title: "Sweetness", options: ["unsweetened", "lightly sweet", "sweet"])
        ],
        .espresso: [
            DrinkChipGroup(id: "espresso-shot", title: "Shot", options: ["single", "double", "ristretto", "lungo"]),
            DrinkChipGroup(id: "espresso-style", title: "Style", options: ["straight", "macchiato", "cortado", "americano"]),
            DrinkChipGroup(id: "espresso-temperature", title: "Temperature", options: ["hot", "iced"])
        ],
        .drip: [
            DrinkChipGroup(id: "drip-roast", title: "Roast", options: ["light roast", "medium roast", "dark roast"]),
            DrinkChipGroup(id: "drip-origin", title: "Origin", options: ["single origin", "blend", "decaf"]),
            DrinkChipGroup(id: "drip-serve", title: "Serve", options: ["black", "with milk", "to go"])
        ],
        .tea: [
            DrinkChipGroup(id: "tea-type", title: "Tea", options: ["black tea", "green tea", "chai", "matcha", "herbal"]),
            DrinkChipGroup(id: "tea-temperature", title: "Temperature", options: ["hot", "iced"]),
            DrinkChipGroup(id: "tea-milk", title: "Milk", options: ["none", "whole milk", "oat milk", "almond milk"])
        ],
        .other: [
            DrinkChipGroup(id: "other-temperature", title: "Temperature", options: ["hot", "iced"]),
            DrinkChipGroup(id: "other-style", title: "Style", options: ["seasonal", "house special", "to go"])
        ]
    ]

    static var allPresetTags: Set<String> {
        Set((groupsByCategory.values + [customDrinkGroups]).flatMap { groups in
            groups.flatMap(\.options).map(LocalTagRepository.normalize(_:))
        })
    }

    static func groups(for drink: DrinkDraft) -> [DrinkChipGroup] {
        if customDrinkTypeName(for: drink) != nil {
            return customDrinkGroups
        }
        return groupsByCategory[drink.category] ?? []
    }

    static func customDrinkTypeName(for drink: DrinkDraft) -> String? {
        guard drink.category == .other else { return nil }
        let trimmed = drink.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, LocalTagRepository.normalize(trimmed) != LocalTagRepository.normalize(DrinkCategory.other.displayName) else {
            return nil
        }
        return trimmed
    }
}
