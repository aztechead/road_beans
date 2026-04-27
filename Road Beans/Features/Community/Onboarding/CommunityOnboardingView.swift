import SwiftUI

struct CommunityOnboardingView: View {
    @Bindable var viewModel: CommunityOnboardingViewModel
    let onJoined: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Display name", text: $viewModel.displayName)
                        .textInputAutocapitalization(.words)
                }

                Section("Taste Profile") {
                    TasteProfileEditor(profile: $viewModel.profile)
                }

                if viewModel.state == .loading {
                    Section {
                        HStack {
                            ProgressView()
                            Text("Joining community...")
                        }
                    }
                }

                if let message = viewModel.errorMessage {
                    Text(message)
                        .foregroundStyle(.red)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.surface(.canvas).ignoresSafeArea())
            .navigationTitle("Join Community")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.state == .loading ? "Joining..." : "Join") {
                        Task {
                            if await viewModel.join() {
                                onJoined()
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.canJoin || viewModel.state == .loading)
                }
            }
        }
        .background(Color.surface(.canvas).ignoresSafeArea())
    }
}
