import SwiftUI

struct MigrationPromptView: View {
    let keepLocalOnly: () -> Void
    let migrate: () async -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "icloud.and.arrow.up.fill")
                .font(.largeTitle)

            Text("Bring your existing road trip data into iCloud?")
                .font(.roadBeansHeadline)
                .multilineTextAlignment(.center)

            HStack {
                Button("Keep local only", action: keepLocalOnly)
                    .buttonStyle(.bordered)

                Button("Yes, migrate") {
                    Task { await migrate() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

#Preview {
    MigrationPromptView(keepLocalOnly: {}, migrate: {})
}
