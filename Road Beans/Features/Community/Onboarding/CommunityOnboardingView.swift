import SwiftUI

struct CommunityOnboardingView: View {
    @Bindable var viewModel: CommunityOnboardingViewModel
    let onJoined: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    RoadBeansClearableTextField("Display name", text: $viewModel.displayName, autocapitalization: .words)
                }

                Section("Taste Profile") {
                    TasteProfileEditor(profile: $viewModel.profile)
                }

                Section("Community Terms") {
                    Toggle("I agree to the community terms", isOn: $viewModel.acceptedTerms)

                    Text("Road Beans has no tolerance for objectionable content or abusive users. Public ratings, display names, drink names, and tags must be appropriate. Users can report or block members, and offending community posts or members may be removed.")
                        .roadBeansStyle(.caption)
                        .foregroundStyle(.ink(.secondary))
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
