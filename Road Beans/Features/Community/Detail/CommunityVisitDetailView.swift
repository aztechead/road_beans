import SwiftUI

struct CommunityVisitDetailView: View {
    let recordName: String
    @Environment(\.communityService) private var community
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CommunityVisitDetailViewModel?
    @State private var isShowingDeleteConfirmation = false

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel)
            } else {
                RoadBeansLoadingState(title: "Loading visit...")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surface(.canvas).ignoresSafeArea())
        .navigationTitle("Community Visit")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel == nil {
                let model = CommunityVisitDetailViewModel(recordName: recordName, service: community)
                viewModel = model
                await model.load()
            }
        }
        .onChange(of: viewModel?.deleteSucceeded ?? false) { _, didDelete in
            if didDelete {
                dismiss()
            }
        }
    }

    @ViewBuilder
    private func content(_ viewModel: CommunityVisitDetailViewModel) -> some View {
        switch viewModel.state {
        case .idle, .loading:
            RoadBeansLoadingState(title: "Loading visit...")
        case .empty:
            ContentUnavailableView("Visit not found", systemImage: "cup.and.saucer")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.surface(.canvas).ignoresSafeArea())
        case .failed(let message):
            ContentUnavailableView("Could not load visit", systemImage: "exclamationmark.triangle", description: Text(message))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.surface(.canvas).ignoresSafeArea())
        case .loaded:
            if let detail = viewModel.detail {
                List {
                    if let actionMessage = viewModel.actionMessage {
                        Section {
                            Label(actionMessage, systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                        }
                    }

                    Section {
                        CommunityVisitRowView(row: detail.row, isFavorite: false)
                    }

                    Section("Comments") {
                        ForEach(detail.comments) { comment in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(comment.authorDisplayName)
                                    .font(.headline)
                                Text(comment.text)
                                Text(comment.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    Task { await viewModel.deleteComment(id: comment.id) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }

                        HStack {
                            RoadBeansClearableTextField(
                                "Add a comment",
                                text: Binding(
                                    get: { viewModel.commentText },
                                    set: { viewModel.commentText = $0 }
                                )
                            )
                            Button {
                                Task { await viewModel.addComment() }
                            } label: {
                                if viewModel.isPostingComment {
                                    ProgressView()
                                } else {
                                    Image(systemName: "paperplane.fill")
                                }
                            }
                            .disabled(viewModel.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isPostingComment)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color.surface(.canvas).ignoresSafeArea())
                .toolbar {
                    if viewModel.canDeleteVisit {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(role: .destructive) {
                                isShowingDeleteConfirmation = true
                            } label: {
                                Image(systemName: "trash")
                            }
                            .disabled(viewModel.isDeletingVisit)
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Task { await viewModel.toggleLike() }
                        } label: {
                            Image(systemName: viewModel.detail?.likedByCurrentUser == true ? "heart.fill" : "heart")
                                .foregroundStyle(viewModel.detail?.likedByCurrentUser == true ? Color.state(.danger) : Color.ink(.secondary))
                        }
                        .disabled(viewModel.isUpdatingLike)
                    }
                }
                .confirmationDialog(
                    "Delete Community Review?",
                    isPresented: $isShowingDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Delete Review", role: .destructive) {
                        Task { await viewModel.deleteVisit() }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This removes your published community review, likes, and comments for this visit.")
                }
            }
        }
    }
}
