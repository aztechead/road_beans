import SwiftUI

enum TagTokenLogic {
    static func add(_ raw: String, to tags: inout [String]) {
        let normalized = LocalTagRepository.normalize(raw)
        guard !normalized.isEmpty, !tags.contains(normalized) else { return }
        tags.append(normalized)
    }
}

struct TagTokenField: View {
    @Binding var tags: [String]
    let suggestions: (String) async -> [TagSuggestion]

    @State private var input = ""
    @State private var currentSuggestions: [TagSuggestion] = []
    @State private var suggestionTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: RoadBeansSpacing.sm) {
            if !tags.isEmpty {
                tagChips
            }

            HStack(spacing: RoadBeansSpacing.sm) {
                Image(systemName: "tag")
                    .foregroundStyle(.ink(.secondary))

                RoadBeansClearableTextField(
                    "Add a tag",
                    text: $input,
                    autocapitalization: .never,
                    autocorrectionDisabled: true,
                    onSubmit: addInput
                )
                    .onChange(of: input) { _, newValue in
                        handleInputChange(newValue)
                    }
            }
            .roadBeansStyle(.bodyM)

            if !currentSuggestions.isEmpty {
                suggestionChips
            }
        }
        .task {
            await refreshSuggestions(for: input)
        }
        .onDisappear {
            suggestionTask?.cancel()
        }
    }

    private var tagChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RoadBeansSpacing.sm) {
                ForEach(tags, id: \.self) { tag in
                    RoadBeansChip(
                        title: tag,
                        state: .removable,
                        onRemove: {
                            tags.removeAll { $0 == tag }
                            scheduleSuggestionRefresh(for: input)
                        }
                    )
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var suggestionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RoadBeansSpacing.sm) {
                ForEach(currentSuggestions.prefix(5)) { suggestion in
                    RoadBeansChip(title: suggestion.name, systemImage: "plus", action: {
                        TagTokenLogic.add(suggestion.name, to: &tags)
                        input = ""
                        scheduleSuggestionRefresh(for: "")
                    })
                }
            }
        }
    }

    private func addInput() {
        TagTokenLogic.add(input, to: &tags)
        input = ""
        scheduleSuggestionRefresh(for: "")
    }

    private func handleInputChange(_ value: String) {
        if value.contains(",") {
            for part in value.split(separator: ",") {
                TagTokenLogic.add(String(part), to: &tags)
            }
            input = ""
            scheduleSuggestionRefresh(for: "")
            return
        }

        scheduleSuggestionRefresh(for: value, delayNanoseconds: 180_000_000)
    }

    private func refreshSuggestions(for value: String) async {
        let normalizedTags = Set(tags.map(LocalTagRepository.normalize(_:)))
        currentSuggestions = await suggestions(value)
            .filter { !normalizedTags.contains(LocalTagRepository.normalize($0.name)) }
    }

    private func scheduleSuggestionRefresh(for value: String, delayNanoseconds: UInt64 = 0) {
        suggestionTask?.cancel()
        suggestionTask = Task {
            if delayNanoseconds > 0 {
                try? await Task.sleep(nanoseconds: delayNanoseconds)
            }
            guard !Task.isCancelled else { return }
            await refreshSuggestions(for: value)
        }
    }
}
