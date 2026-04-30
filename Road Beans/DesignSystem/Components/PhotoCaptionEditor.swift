import SwiftUI

struct PhotoCaptionEditor: View {
    let title: String
    @Binding var caption: String?

    var body: some View {
        VStack(alignment: .leading, spacing: RoadBeansSpacing.xs) {
            Text(title)
                .roadBeansStyle(.caption)
                .foregroundStyle(.ink(.secondary))

            ZStack(alignment: .topLeading) {
                TextEditor(text: captionText)
                    .textInputAutocapitalization(.sentences)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 74)
                    .roadBeansWritingTools()

                if captionText.wrappedValue.isEmpty {
                    Text("Add a photo note")
                        .roadBeansStyle(.bodyS)
                        .foregroundStyle(.ink(.tertiary))
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, RoadBeansSpacing.sm)
            .padding(.vertical, RoadBeansSpacing.xs)
            .surface(.sunken, radius: RoadBeansRadius.md)
        }
    }

    private var captionText: Binding<String> {
        Binding(
            get: { caption ?? "" },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                caption = trimmed.isEmpty ? nil : newValue
            }
        )
    }
}

private extension View {
    @ViewBuilder
    func roadBeansWritingTools() -> some View {
        if #available(iOS 18.0, *) {
            writingToolsBehavior(.complete)
        } else {
            self
        }
    }
}
