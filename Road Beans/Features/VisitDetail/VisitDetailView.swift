import SwiftUI
import UIKit

struct VisitDetailView: View {
    let visitID: UUID
    @Environment(\.visitRepository) private var visitsRepository
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: VisitDetailViewModel?
    @State private var isConfirmingDelete = false
    @State private var isEditing = false

    var body: some View {
        Group {
            if let viewModel {
                switch viewModel.state {
                case .idle, .loading:
                    RoadBeansLoadingState(title: "Loading visit...")
                case .loaded:
                    if let detail = viewModel.detail {
                        content(detail)
                    } else {
                        missingVisitState
                    }
                case .empty:
                    missingVisitState
                case .failed(let message):
                    failedState(message)
                }
            } else {
                RoadBeansLoadingState(title: "Loading visit...")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surface(.canvas).ignoresSafeArea())
        .navigationTitle("Visit")
        .navigationBarTitleDisplayMode(.inline)
        .task { await ensureLoaded() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    isEditing = true
                }
                .disabled(viewModel?.detail == nil)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    isConfirmingDelete = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            if let detail = viewModel?.detail {
                EditVisitView(detail: detail) { command in
                    try await viewModel?.update(command)
                }
            }
        }
        .confirmationDialog("Delete this visit?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task {
                    try? await viewModel?.delete()
                    NotificationCenter.default.post(name: .roadBeansVisitDeleted, object: nil)
                    dismiss()
                }
            }
        }
    }

    private func ensureLoaded() async {
        if viewModel == nil {
            viewModel = VisitDetailViewModel(visits: visitsRepository, visitID: visitID)
        }
        await viewModel?.load()
    }

    private var missingVisitState: some View {
        ContentUnavailableView(
            "Visit not found",
            systemImage: "cup.and.saucer",
            description: Text("This visit may have been deleted.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surface(.canvas).ignoresSafeArea())
        .padding()
    }

    private func failedState(_ message: String) -> some View {
        VStack(spacing: 16) {
            ContentUnavailableView(
                "Could not load visit",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )

            Button("Try Again") {
                Task { await ensureLoaded() }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surface(.canvas).ignoresSafeArea())
        .padding()
    }

    private func content(_ detail: VisitDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RoadBeansSpacing.md) {
                header(detail)
                photoPager(detail.photos)
                tags(detail.tagNames)
                drinks(detail.drinks)
            }
            .padding(RoadBeansSpacing.md)
            .padding(.bottom, 88)
        }
        .background(Color.surface(.canvas).ignoresSafeArea())
    }

    private func header(_ detail: VisitDetail) -> some View {
        RoadBeansCard(tint: detail.placeKind.accentColor) {
            VStack(alignment: .leading, spacing: RoadBeansSpacing.sm) {
            Text(detail.date.formatted(date: .complete, time: .shortened))
                .roadBeansStyle(.titleM)

            HStack {
                Icon(.place(detail.placeKind), size: 16)
                Text(detail.placeName)
                    .roadBeansStyle(.bodyM)
            }
            .foregroundStyle(.ink(.secondary))
            }
        }
    }

    @ViewBuilder
    private func photoPager(_ photos: [PhotoReference]) -> some View {
        if !photos.isEmpty {
            TabView {
                ForEach(photos) { photo in
                    VisitPhotoPage(data: photo.thumbnailData)
                }
            }
            .tabViewStyle(.page)
            .frame(height: 280)
            .padding(RoadBeansSpacing.lg)
            .surface(.raised, radius: RoadBeansRadius.lg)
        }
    }

    @ViewBuilder
    private func tags(_ tagNames: [String]) -> some View {
        if !tagNames.isEmpty {
            FlowTags(tags: tagNames)
        }
    }

    private func drinks(_ drinks: [DrinkRow]) -> some View {
        RoadBeansCard {
            VStack(alignment: .leading, spacing: RoadBeansSpacing.sm) {
            Text("Drinks")
                .roadBeansStyle(.titleM)

            ForEach(drinks) { drink in
                HStack(spacing: 12) {
                    Icon(.drink(drink.category), size: 16)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(drink.name)
                            .roadBeansStyle(.bodyM)

                        if !drink.tagNames.isEmpty {
                            Text(drink.tagNames.joined(separator: " · "))
                                .roadBeansStyle(.bodyS)
                                .foregroundStyle(.ink(.secondary))
                        }
                    }

                    Spacer()
                    BeanRatingView(value: .constant(drink.rating), size: 16, editable: false)
                }
                .padding(.vertical, 6)
            }
            }
        }
    }
}

private struct VisitPhotoPage: View {
    let data: Data
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
        }
        .task(id: data) {
            image = UIImage(data: data)
        }
    }
}

extension Notification.Name {
    static let roadBeansVisitDeleted = Notification.Name("RoadBeans.visitDeleted")
    static let roadBeansPlaceUpdated = Notification.Name("RoadBeans.placeUpdated")
    static let roadBeansPlaceDeleted = Notification.Name("RoadBeans.placeDeleted")
}

private struct FlowTags: View {
    let tags: [String]

    var body: some View {
        HStack {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .roadBeansStyle(.labelM)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .overlay(Capsule().stroke(Color.divider(.strong), lineWidth: 1))
            }
        }
    }
}
