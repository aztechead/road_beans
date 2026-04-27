import SwiftUI

struct RoadBeansListRow<Leading: View, Trailing: View, Supporting: View>: View {
    let title: String
    @ViewBuilder var leading: Leading
    @ViewBuilder var trailing: Trailing
    @ViewBuilder var supporting: Supporting

    init(
        _ title: String,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder supporting: () -> Supporting,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.leading = leading()
        self.supporting = supporting()
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: RoadBeansSpacing.md) {
            leading

            VStack(alignment: .leading, spacing: RoadBeansSpacing.xxs) {
                Text(title)
                    .roadBeansStyle(.headline)

                supporting
                    .roadBeansStyle(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: RoadBeansSpacing.md)

            trailing
        }
        .padding(.vertical, RoadBeansSpacing.lg)
        .accessibilityElement(children: .combine)
    }
}

extension RoadBeansListRow where Leading == EmptyView, Trailing == EmptyView, Supporting == EmptyView {
    init(_ title: String) {
        self.init(title, leading: { EmptyView() }, supporting: { EmptyView() }, trailing: { EmptyView() })
    }
}

extension RoadBeansListRow where Leading == EmptyView, Trailing == EmptyView {
    init(_ title: String, @ViewBuilder supporting: () -> Supporting) {
        self.init(title, leading: { EmptyView() }, supporting: supporting, trailing: { EmptyView() })
    }
}

struct RoadBeansSection<Content: View, HeaderAccessory: View>: View {
    let title: String
    @ViewBuilder var headerAccessory: HeaderAccessory
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: RoadBeansSpacing.sm) {
            HStack {
                Text(title)
                    .roadBeansStyle(.title3)

                Spacer()

                headerAccessory
            }

            content
        }
    }
}

extension RoadBeansSection where HeaderAccessory == EmptyView {
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        headerAccessory = EmptyView()
        self.content = content()
    }
}

struct RoadBeansEmptyState<Actions: View>: View {
    let title: String
    let message: String
    var systemImage: String = "cup.and.saucer"
    @ViewBuilder var actions: Actions

    var body: some View {
        VStack(spacing: RoadBeansSpacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(Color.accent(.default))
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: RoadBeansSpacing.xs) {
                Text(title)
                    .roadBeansStyle(.title3)

                Text(message)
                    .roadBeansStyle(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            actions
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(RoadBeansSpacing.xl)
        .accessibilityElement(children: .combine)
    }
}

struct RoadBeansLoadingState: View {
    let title: String

    var body: some View {
        VStack(spacing: RoadBeansSpacing.md) {
            ProgressView()
                .tint(Color.accent(.default))

            Text(title)
                .roadBeansStyle(.bodyM)
                .foregroundStyle(.ink(.secondary))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surface(.canvas).ignoresSafeArea())
    }
}

extension RoadBeansEmptyState where Actions == EmptyView {
    init(title: String, message: String, systemImage: String = "cup.and.saucer") {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        actions = EmptyView()
    }
}

#Preview {
    RoadBeansEmptyState(title: "No stops yet", message: "Add your first stop to start building your road coffee log.")
}
