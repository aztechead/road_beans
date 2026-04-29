import SwiftUI

struct CommunitySettingsView: View {
    @Bindable var viewModel: CommunitySettingsViewModel
    let onCommunityChanged: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showLeaveConfirmation = false

    var body: some View {
        NavigationStack {
            content
                .scrollContentBackground(.hidden)
                .background(Color.surface(.canvas).ignoresSafeArea())
                .navigationTitle("Settings")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button(viewModel.state == .loading ? "Saving..." : "Save") {
                            Task {
                                if await viewModel.save() {
                                    onCommunityChanged()
                                }
                            }
                        }
                        .disabled(!viewModel.canSave || viewModel.state == .loading)
                    }
                }
                .confirmationDialog("Leave the Community?", isPresented: $showLeaveConfirmation, titleVisibility: .visible) {
                    Button(leaveButtonTitle, role: .destructive) {
                        Task {
                            if await viewModel.leave() {
                                onCommunityChanged()
                                dismiss()
                            }
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text(leaveConfirmationMessage)
                }
                .task {
                    if viewModel.state == .idle {
                        await viewModel.load()
                    }
                }
        }
        .background(Color.surface(.canvas).ignoresSafeArea())
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.isMember {
            switch viewModel.state {
            case .idle, .loading:
                RoadBeansLoadingState(title: "Loading settings...")
            case .empty:
                ContentUnavailableView(
                    "Community not joined",
                    systemImage: "person.3",
                    description: Text("Join the Community before changing community settings.")
                )
            case .failed(let message):
                ContentUnavailableView(
                    "Could not load settings",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            case .loaded:
                form
            }
        } else {
            form
        }
    }

    private var form: some View {
        Form {
            Section {
                RoadBeansClearableTextField(
                    "Username",
                    text: $viewModel.displayName,
                    autocapitalization: .words,
                    autocorrectionDisabled: true
                )

                if viewModel.shouldShowUsernameWarning {
                    WarningBanner(
                        title: "Changing your username has consequences",
                        message: "Ratings already published under your old username may no longer be available for deletion after this change."
                    )
                }
            } header: {
                Text("Profile")
            }

            Section {
                TasteProfileEditor(profile: $viewModel.profile)
            } header: {
                Text("Taste Profile")
            }

            Section {
                Toggle("Delete my ratings when leaving", isOn: $viewModel.deleteRatingsWhenLeaving)

                Button(role: .destructive) {
                    showLeaveConfirmation = true
                } label: {
                    Label("Leave the Community", systemImage: "person.crop.circle.badge.minus")
                }
                .disabled(viewModel.state == .loading)
            } header: {
                Text("Community Data")
            } footer: {
                Text("Leaving removes your community profile and likes. Your published ratings are only deleted when the toggle is on.")
            }

            Section {
                Label("Favorite members are stored on this device", systemImage: "star")
                    .foregroundStyle(.ink(.secondary))
            } header: {
                Text("Feed")
            }

            Section {
                Link(destination: URL(string: "mailto:nctightend@gmail.com?subject=Road%20Beans%20Community%20Report")!) {
                    Label("Report inappropriate activity", systemImage: "envelope")
                }

                Text("Reports are reviewed within 24 hours. Road Beans may remove offending posts and eject users who provide objectionable content.")
                    .roadBeansStyle(.caption)
                    .foregroundStyle(.ink(.secondary))
            } header: {
                Text("Safety")
            }

            if let actionMessage = viewModel.actionMessage {
                Text(actionMessage)
                    .foregroundStyle(.state(.success))
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.state(.danger))
            }

            if viewModel.state == .loading {
                HStack {
                    ProgressView()
                    Text("Updating community...")
                }
            }
        }
    }

    private var leaveButtonTitle: String {
        viewModel.deleteRatingsWhenLeaving ? "Leave and Delete Ratings" : "Leave and Keep Ratings"
    }

    private var leaveConfirmationMessage: String {
        if viewModel.deleteRatingsWhenLeaving {
            return "Your community profile, likes, and published ratings will be removed."
        }
        return "Your community profile and likes will be removed. Published ratings will remain visible under your current username."
    }
}

private struct WarningBanner: View {
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: RoadBeansSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.state(.warning))
                .imageScale(.medium)

            VStack(alignment: .leading, spacing: RoadBeansSpacing.xxs) {
                Text(title)
                    .roadBeansStyle(.label)
                    .foregroundStyle(.ink(.primary))
                Text(message)
                    .roadBeansStyle(.caption)
                    .foregroundStyle(.ink(.secondary))
            }
        }
        .padding(.vertical, RoadBeansSpacing.xs)
        .accessibilityElement(children: .combine)
    }
}
