import PhotosUI
import SwiftUI
import UIKit

struct AddVisitVisitPage: View {
    @Bindable var model: AddVisitFlowModel
    @State private var pickerItems: [PhotosPickerItem] = []

    var body: some View {
        Form {
            DatePicker("When", selection: $model.date)

            Section("Photos") {
                PhotosPicker(
                    selection: $pickerItems,
                    maxSelectionCount: 8,
                    matching: .images
                ) {
                    Label("Choose photos", systemImage: "photo.on.rectangle")
                }
                .onChange(of: pickerItems) { _, newItems in
                    Task {
                        await loadPhotos(newItems)
                    }
                }

                if !model.photos.isEmpty {
                    photoPreviewStrip
                }
            }

            Section("Visit Tags") {
                TagTokenField(tags: $model.visitTags) { prefix in
                    (try? await model.tagsRepo.suggestions(prefix: prefix, limit: 5)) ?? []
                }
            }
        }
    }

    private var photoPreviewStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(model.photos.enumerated()), id: \.offset) { _, draft in
                    if let image = UIImage(data: draft.rawImageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                drafts.append(PhotoDraft(rawImageData: data, caption: nil))
            }
        }
        model.photos = drafts
    }
}
