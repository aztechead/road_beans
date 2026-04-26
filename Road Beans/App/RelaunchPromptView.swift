import SwiftUI

struct RelaunchPromptView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.icloud")
                .font(.largeTitle)

            Text("Your iCloud account changed.")
                .font(.roadBeansHeadline)

            Text("Relaunch Road Beans to continue.")
                .font(.roadBeansBody)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding()
    }
}

#Preview {
    RelaunchPromptView()
}
