import SwiftUI

struct RootToastOverlay: View {
    @State private var text: String?

    var body: some View {
        VStack {
            Spacer()

            if let text {
                Text(text)
                    .font(.roadBeansBody)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .glassCard()
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: text)
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
