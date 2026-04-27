import SwiftUI

struct RootToastOverlay: View {
    @State private var text: String?

    var body: some View {
        VStack {
            Spacer()

            if let text {
                Text(text)
                    .roadBeansStyle(.bodyM)
                    .foregroundStyle(.ink(.primary))
                    .padding(.horizontal, RoadBeansSpacing.lg)
                    .padding(.vertical, RoadBeansSpacing.sm)
                    .surface(.raised, radius: RoadBeansRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: RoadBeansRadius.md, style: .continuous)
                            .stroke(Color.divider(.hairline), lineWidth: 0.5)
                    )
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(RoadBeansMotion.snap, value: text)
        .onReceive(NotificationCenter.default.publisher(for: .roadBeansVisitSaved)) { notification in
            guard let toastText = notification.userInfo?["text"] as? String else { return }
            text = toastText

            Task {
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                text = nil
            }
        }
    }
}

extension Notification.Name {
    static let roadBeansVisitSaved = Notification.Name("RoadBeans.visitSaved")
}
