import SwiftUI
import UIKit

struct VisitDetailView: View {
    let visitID: UUID
    @Environment(\.visitRepository) private var visitsRepository
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: VisitDetailViewModel?
    @State private var isConfirmingDelete = false

    var body: some View {
        Group {
            if let detail = viewModel?.detail {
                content(detail)
            } else {
                ProgressView()
                    .task { await ensureLoaded() }
            }
        }
        .navigationTitle("Visit")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    isConfirmingDelete = true
                } label: {
                    Image(systemName: "trash")
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

    private func content(_ detail: VisitDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header(detail)
                photoPager(detail.photos)
                tags(detail.tagNames)
                drinks(detail.drinks)
            }
            .padding()
        }
    }

    private func header(_ detail: VisitDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(detail.date.formatted(date: .complete, time: .shortened))
                .font(.roadBeansHeadline)

            HStack {
                Image(systemName: detail.placeKind.sfSymbol)
                    .foregroundStyle(detail.placeKind.accentColor)
                Text(detail.placeName)
                    .font(.roadBeansBody)
            }
            .foregroundStyle(.secondary)
        }
        .glassCard(tint: detail.placeKind.accentColor)
    }

    @ViewBuilder
    private func photoPager(_ photos: [PhotoReference]) -> some View {
        if !photos.isEmpty {
            TabView {
                ForEach(photos) { photo in
                    if let image = UIImage(data: photo.thumbnailData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .tabViewStyle(.page)
            .frame(height: 280)
            .glassCard()
        }
    }

    @ViewBuilder
    private func tags(_ tagNames: [String]) -> some View {
        if !tagNames.isEmpty {
            FlowTags(tags: tagNames)
        }
    }

    private func drinks(_ drinks: [DrinkRow]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Drinks")
                .font(.roadBeansHeadline)

            ForEach(drinks) { drink in
                HStack(spacing: 12) {
                    Image(systemName: drink.category.sfSymbol)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(drink.name)
                            .font(.roadBeansBody)

                        if !drink.tagNames.isEmpty {
                            Text(drink.tagNames.joined(separator: " · "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                    BeanRating(value: drink.rating, pixelSize: 2)
                }
                .padding(.vertical, 6)
            }
        }
        .glassCard()
    }
}

extension Notification.Name {
    static let roadBeansVisitDeleted = Notification.Name("RoadBeans.visitDeleted")
}

private struct FlowTags: View {
    let tags: [String]

    var body: some View {
        HStack {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.18), in: Capsule())
            }
        }
    }
}
