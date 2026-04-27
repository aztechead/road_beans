import SwiftUI

struct RoadBeansClearableTextField: View {
    let placeholder: String
    @Binding var text: String
    var systemImage: String?
    var autocapitalization: TextInputAutocapitalization?
    var autocorrectionDisabled = false
    var onSubmit: (() -> Void)?

    var body: some View {
        HStack(spacing: RoadBeansSpacing.sm) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(.ink(.secondary))
            }

            TextField(placeholder, text: $text)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(autocorrectionDisabled)
                .onSubmit {
                    onSubmit?()
                }

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.ink(.tertiary))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear text")
            }
        }
    }

    init(
        _ placeholder: String,
        text: Binding<String>,
        systemImage: String? = nil,
        autocapitalization: TextInputAutocapitalization? = nil,
        autocorrectionDisabled: Bool = false,
        onSubmit: (() -> Void)? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.systemImage = systemImage
        self.autocapitalization = autocapitalization
        self.autocorrectionDisabled = autocorrectionDisabled
        self.onSubmit = onSubmit
    }
}

struct RoadBeansButton: View {
    enum Variant {
        case primary
        case secondary
        case tertiary
        case destructive
    }

    let title: String
    var systemImage: String?
    var variant: Variant = .primary
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                Text(title)
            } icon: {
                if let systemImage {
                    Image(systemName: systemImage)
                }
            }
            .roadBeansStyle(.label)
            .frame(minHeight: 44)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, RoadBeansSpacing.lg)
            .background(background, in: Capsule())
            .foregroundStyle(foreground)
            .overlay(border)
        }
        .buttonStyle(PressedScaleStyle())
        .contentShape(Capsule())
    }

    private var background: Color {
        switch variant {
        case .primary:
            .accent(.default)
        case .secondary:
            .clear
        case .tertiary:
            .clear
        case .destructive:
            .state(.danger)
        }
    }

    private var foreground: Color {
        switch variant {
        case .primary, .destructive:
            .accent(.on)
        case .secondary, .tertiary:
            .accent(.default)
        }
    }

    @ViewBuilder private var border: some View {
        if variant == .secondary {
            Capsule().stroke(Color.accent(.default), lineWidth: 1)
        }
    }
}

struct RoadBeansChip: View {
    enum State {
        case `default`
        case selected
        case removable
    }

    let title: String
    var systemImage: String?
    var state: State = .default
    var action: (() -> Void)?
    var onRemove: (() -> Void)?

    init(
        title: String,
        systemImage: String? = nil,
        isSelected: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.systemImage = systemImage
        self.state = isSelected ? .selected : .default
        self.action = action
    }

    init(
        title: String,
        systemImage: String? = nil,
        state: State,
        action: (() -> Void)? = nil,
        onRemove: (() -> Void)? = nil
    ) {
        self.title = title
        self.systemImage = systemImage
        self.state = state
        self.action = action
        self.onRemove = onRemove
    }

    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    label
                }
                .buttonStyle(.plain)
            } else {
                label
            }
        }
        .accessibilityAddTraits(state == .selected ? [.isSelected] : [])
    }

    private var label: some View {
        HStack(spacing: RoadBeansSpacing.xs) {
            if let systemImage {
                Image(systemName: systemImage)
            }

            Text(title)
                .lineLimit(1)

            if state == .removable {
                Button {
                    onRemove?()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }
        }
        .roadBeansStyle(.caption)
        .padding(.horizontal, RoadBeansSpacing.md)
        .padding(.vertical, 6)
        .background(state == .selected ? Color.accent(.default) : Color.clear, in: Capsule())
        .overlay {
            if state != .selected {
                Capsule().stroke(Color.divider(.strong), lineWidth: 1)
            }
        }
        .foregroundStyle(state == .selected ? Color.accent(.on) : Color.ink(.secondary))
    }
}

private struct PressedScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(RoadBeansMotion.snap, value: configuration.isPressed)
    }
}

#Preview {
    VStack {
        RoadBeansButton(title: "Add Visit", systemImage: "plus") {}
        HStack {
            RoadBeansChip(title: "Coffee Shop", systemImage: "cup.and.saucer.fill", isSelected: true)
            RoadBeansChip(title: "Any Date", systemImage: "calendar")
        }
    }
    .padding()
}
