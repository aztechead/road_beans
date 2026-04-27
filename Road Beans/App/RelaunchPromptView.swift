import SwiftUI

struct RelaunchPromptView: View {
    var body: some View {
        VStack(spacing: RoadBeansSpacing.lg) {
            Image(systemName: "exclamationmark.icloud")
                .font(.largeTitle)

            Text("Your iCloud account changed.")
                .roadBeansStyle(.titleL)

            Text("Relaunch Road Beans to continue.")
                .roadBeansStyle(.bodyM)
                .foregroundStyle(.ink(.secondary))
        }
        .multilineTextAlignment(.center)
        .padding()
    }
}

#Preview {
    RelaunchPromptView()
}
