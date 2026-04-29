import SwiftUI

struct CommunityMemberProfileView: View {
    @Bindable var viewModel: CommunityMemberProfileViewModel
    let onLeave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showLeaveConfirm = false

    var body: some View {
        NavigationStack {
            List {
                switch viewModel.state {
                case .idle, .loading:
                    RoadBeansLoadingState(title: "Loading member...")
                case .empty:
                    ContentUnavailableView("Member not found", systemImage: "person.crop.circle.badge.questionmark")
                case .failed(let message):
                    ContentUnavailableView("Could not load member", systemImage: "exclamationmark.triangle", description: Text(message))
                case .loaded:
                    if let member = viewModel.member {
                        Section {
                            Text(member.displayName)
                                .roadBeansStyle(.titleL)
                            TasteProfileEditor(profile: .constant(member.tasteProfile), isReadOnly: true)
                        }

                        Section {
                            if viewModel.isSelf {
                                Button(role: .destructive) {
                                    showLeaveConfirm = true
                                } label: {
                                    Label("Leave the Community", systemImage: "person.crop.circle.badge.minus")
                                }
                            } else {
                                Button {
                                    viewModel.toggleFavorite()
                                } label: {
                                    Label(
                                        viewModel.isFavorite ? "Remove Favorite" : "Favorite Member",
                                        systemImage: viewModel.isFavorite ? "star.fill" : "star"
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.surface(.canvas).ignoresSafeArea())
            .navigationTitle("Member")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Leave the Community?", isPresented: $showLeaveConfirm, titleVisibility: .visible) {
                Button("Leave", role: .destructive) {
                    Task {
                        if await viewModel.leave() {
                            onLeave()
                            dismiss()
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your published visits and likes will be removed.")
            }
            .task {
                if viewModel.state == .idle {
                    await viewModel.load()
                }
            }
        }
        .background(Color.surface(.canvas).ignoresSafeArea())
    }
}
