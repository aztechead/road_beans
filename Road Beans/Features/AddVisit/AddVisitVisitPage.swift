import PhotosUI
import SwiftUI
import UIKit

struct AddVisitVisitPage: View {
    @Bindable var model: AddVisitFlowModel
    @State private var pickerItems: [PhotosPickerItem] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RoadBeansSpacing.lg) {
                RoadBeansSection("Visit") {
                    DatePicker("When", selection: $model.date)
                        .roadBeansStyle(.bodyM)
                        .padding(RoadBeansSpacing.md)
                        .surface(.raised, radius: RoadBeansRadius.md)
                }

                RoadBeansSection("Photos") {
                    VStack(alignment: .leading, spacing: RoadBeansSpacing.md) {
                        PhotosPicker(
                            selection: $pickerItems,
                            maxSelectionCount: 8,
                            matching: .images
                        ) {
                            Label("Choose photos", systemImage: "photo.on.rectangle")
                                .roadBeansStyle(.label)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 44)
                                .foregroundStyle(Color.accent(.default))
                                .background(Color.surface(.raised), in: Capsule())
                                .overlay {
                                    Capsule().stroke(Color.accent(.default), lineWidth: 1)
                                }
                        }
                        .onChange(of: pickerItems) { _, newItems in
                            Task {
                                await loadPhotos(newItems)
                            }
                        }

                        if model.photos.isEmpty {
                            PhotoEmptyDropZone()
                        } else {
                            photoPreviewStrip
                        }
                    }
                }

                RoadBeansSection("Visit Tags") {
                    TagTokenField(tags: $model.visitTags) { prefix in
                        (try? await model.tagsRepo.suggestions(prefix: prefix, limit: 5)) ?? []
                    }
                    .padding(RoadBeansSpacing.md)
                    .surface(.raised, radius: RoadBeansRadius.md)
                }
            }
            .padding(RoadBeansSpacing.lg)
        }
        .background(Color.surface(.canvas))
    }

    private var photoPreviewStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(model.photos.enumerated()), id: \.offset) { index, draft in
                    PhotoThumbnail(data: draft.previewImageData ?? draft.rawImageData) {
                        model.photos.remove(at: index)
                        if index < pickerItems.count {
                            pickerItems.remove(at: index)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func loadPhotos(_ items: [PhotosPickerItem]) async {
        var drafts: [PhotoDraft] = []
        for item in items.prefix(8) {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let previewData = try? await model.photoProcessor.process(data).thumbnailData
                drafts.append(PhotoDraft(rawImageData: data, previewImageData: previewData, caption: nil))
            }
        }
        model.photos = drafts
    }
}

private struct PhotoEmptyDropZone: View {
    var body: some View {
        VStack(spacing: RoadBeansSpacing.sm) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Color.accent(.default))

            Text("Add road photos")
                .roadBeansStyle(.headline)

            Text("Receipts, menus, and cup shots help the visit feel complete.")
                .roadBeansStyle(.bodyS)
                .foregroundStyle(.ink(.secondary))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(RoadBeansSpacing.lg)
        .roadBeansSurface(.inset, tint: Color.accent(.default))
    }
}

private struct PhotoThumbnail: View {
    let data: Data
    let onRemove: () -> Void
    @State private var image: UIImage?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "photo")
                        .foregroundStyle(.ink(.secondary))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(width: 92, height: 92)
            .clipShape(RoundedRectangle(cornerRadius: RoadBeansRadius.md, style: .continuous))

            Button(role: .destructive, action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .frame(width: 24, height: 24)
                    .background(Color.surface(.raised), in: Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.state(.danger))
            .padding(5)
        }
        .task(id: data) {
            image = UIImage(data: data)
        }
    }
}
