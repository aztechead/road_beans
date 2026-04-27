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

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !tags.isEmpty {
                tagChips
            }

            TextField("Add a tag", text: $input)
                .textFieldStyle(.roundedBorder)
                .onSubmit(addInput)
                .onChange(of: input) { _, newValue in
                    handleInputChange(newValue)
                }

            if !currentSuggestions.isEmpty {
                suggestionChips
            }
        }
        .task {
            await refreshSuggestions(for: input)
        }
    }

    private var tagChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    HStack(spacing: 6) {
                        Text(tag)

                        Button {
                            tags.removeAll { $0 == tag }
                            Task { await refreshSuggestions(for: input) }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .imageScale(.small)
                        }
                        .buttonStyle(.plain)
                    }
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.16), in: Capsule())
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var suggestionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(currentSuggestions.prefix(5)) { suggestion in
                    Button(suggestion.name) {
                        TagTokenLogic.add(suggestion.name, to: &tags)
                        input = ""
                        Task { await refreshSuggestions(for: "") }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private func addInput() {
        TagTokenLogic.add(input, to: &tags)
        input = ""
        Task { await refreshSuggestions(for: "") }
    }

    private func handleInputChange(_ value: String) {
        if value.contains(",") {
            for part in value.split(separator: ",") {
                TagTokenLogic.add(String(part), to: &tags)
            }
            input = ""
            Task { await refreshSuggestions(for: "") }
            return
        }

        Task {
            await refreshSuggestions(for: value)
        }
    }

    private func refreshSuggestions(for value: String) async {
        let normalizedTags = Set(tags.map(LocalTagRepository.normalize(_:)))
        currentSuggestions = await suggestions(value)
            .filter { !normalizedTags.contains(LocalTagRepository.normalize($0.name)) }
    }
}
