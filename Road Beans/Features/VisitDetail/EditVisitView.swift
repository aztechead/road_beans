import PhotosUI
import SwiftUI
import UIKit

struct EditVisitView: View {
    let detail: VisitDetail
    let save: (UpdateVisitCommand) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.photoProcessingService) private var photoProcessor
    @State private var date: Date
    @State private var visitTags: String
    @State private var drinks: [DrinkDraft]
    @State private var existingPhotos: [PhotoReference]
    @State private var removedPhotoIDs: Set<UUID> = []
    @State private var newPhotos: [PhotoDraft] = []
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(detail: VisitDetail, save: @escaping (UpdateVisitCommand) async throws -> Void) {
        self.detail = detail
        self.save = save
        _date = State(initialValue: detail.date)
        _visitTags = State(initialValue: detail.tagNames.joined(separator: ", "))
        _existingPhotos = State(initialValue: detail.photos)
        _drinks = State(initialValue: detail.drinks.map {
            DrinkDraft(
                name: $0.name,
                category: $0.category,
                rating: $0.rating,
                tags: $0.tagNames
            )
        })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: RoadBeansSpacing.lg) {
                    RoadBeansSection("Visit") {
                        DatePicker("When", selection: $date)
                            .roadBeansStyle(.bodyM)
                            .padding(RoadBeansSpacing.md)
                            .surface(.raised, radius: RoadBeansRadius.md)
                    }

                    RoadBeansSection("Visit Tags") {
                        RoadBeansClearableTextField(
                            "roadtrip, smooth, favorite",
                            text: $visitTags,
                            autocapitalization: .never
                        )
                            .padding(RoadBeansSpacing.md)
                            .surface(.sunken, radius: RoadBeansRadius.md)
                    }

                    RoadBeansSection("Drinks") {
                        VStack(spacing: RoadBeansSpacing.md) {
                            ForEach(drinks.indices, id: \.self) { index in
                                drinkEditor(index)
                            }

                            RoadBeansButton(title: "Add Drink", systemImage: "plus", variant: .secondary) {
                                drinks.append(DrinkDraft(name: "", category: .drip, rating: 3, tags: []))
                            }
                        }
                    }

                    RoadBeansSection("Photos") {
                        VStack(alignment: .leading, spacing: RoadBeansSpacing.md) {
                            if existingPhotos.isEmpty && newPhotos.isEmpty {
                                PhotoEmptyDropZone()
                            }

                            ForEach(existingPhotos) { photo in
                                existingPhotoRow(photo)
                            }

                            if !newPhotos.isEmpty {
                                newPhotoStrip
                            }

                            PhotosPicker(selection: $pickerItems, maxSelectionCount: 8, matching: .images) {
                                Label("Add photos", systemImage: "photo.on.rectangle")
                                    .roadBeansStyle(.label)
                                    .frame(maxWidth: .infinity)
                                    .frame(minHeight: 44)
                                    .foregroundStyle(Color.accent(.default))
                                    .background(Color.surface(.raised), in: Capsule())
                                    .overlay {
                                        Capsule().stroke(Color.accent(.default), lineWidth: 1)
                                    }
                            }
                            .onChange(of: pickerItems) { _, items in
                                Task { await loadPhotos(items) }
                            }
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .roadBeansStyle(.bodyM)
                            .foregroundStyle(Color.state(.danger))
                            .padding(RoadBeansSpacing.md)
                            .surface(.raised, radius: RoadBeansRadius.md)
                    }
                }
                .padding(RoadBeansSpacing.lg)
            }
            .background(Color.surface(.canvas).ignoresSafeArea())
            .navigationTitle("Edit Visit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Save") {
                        Task { await performSave() }
                    }
                    .disabled(isSaving || drinks.isEmpty || drinks.contains { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
                }
            }
        }
    }

    private func drinkEditor(_ index: Int) -> some View {
        VStack(alignment: .leading, spacing: RoadBeansSpacing.md) {
            HStack {
                Text("Drink \(index + 1)")
                    .roadBeansStyle(.title3)

                Spacer()

                if drinks.count > 1 {
                    Button(role: .destructive) {
                        drinks.remove(at: index)
                    } label: {
                        Image(systemName: "trash")
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.state(.danger))
                }
            }

            RoadBeansClearableTextField("Drink name", text: $drinks[index].name)
                .padding(RoadBeansSpacing.md)
                .surface(.sunken, radius: RoadBeansRadius.md)

            EditVisitDrinkCategoryChips(selection: $drinks[index].category)

            RoadBeansClearableTextField(
                "Tags",
                text: Binding(
                    get: { drinks[index].tags.joined(separator: ", ") },
                    set: { drinks[index].tags = parseTags($0) }
                ),
                autocapitalization: .never
            )
            .padding(RoadBeansSpacing.md)
            .surface(.sunken, radius: RoadBeansRadius.md)

            BeanRatingView(value: $drinks[index].rating, size: 24)
                .frame(maxWidth: .infinity)
                .padding(.top, RoadBeansSpacing.sm)
        }
        .padding(RoadBeansSpacing.lg)
        .roadBeansSurface(.base, tint: Color.accent(.default))
    }

    private func existingPhotoRow(_ photo: PhotoReference) -> some View {
        HStack(spacing: 12) {
            PhotoThumbnailData(data: photo.thumbnailData, size: 56, radius: 10)

            Text(photo.caption ?? "Photo")
                .roadBeansStyle(.bodyM)
                .foregroundStyle(.ink(.secondary))

            Spacer()

            Button(role: .destructive) {
                removedPhotoIDs.insert(photo.id)
                existingPhotos.removeAll { $0.id == photo.id }
            } label: {
                Image(systemName: "trash")
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.state(.danger))
        }
        .padding(RoadBeansSpacing.md)
        .surface(.raised, radius: RoadBeansRadius.md)
    }

    private var newPhotoStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(newPhotos.enumerated()), id: \.offset) { index, draft in
                    PhotoThumbnail(data: draft.previewImageData ?? draft.rawImageData) {
                        newPhotos.remove(at: index)
                        if index < pickerItems.count {
                            pickerItems.remove(at: index)
                        }
                    }
                }
            }
        }
    }

    private func performSave() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            try await save(
                UpdateVisitCommand(
                    id: detail.id,
                    date: date,
                    tags: parseTags(visitTags),
                    drinks: drinks,
                    photoAdditions: newPhotos.isEmpty ? nil : newPhotos,
                    photoRemovals: removedPhotoIDs.isEmpty ? nil : Array(removedPhotoIDs)
                )
            )
            NotificationCenter.default.post(name: .roadBeansVisitSaved, object: nil)
            dismiss()
        } catch {
            errorMessage = "Could not save this visit."
        }
    }

    private func parseTags(_ text: String) -> [String] {
        text.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func loadPhotos(_ items: [PhotosPickerItem]) async {
        var drafts: [PhotoDraft] = []
        for item in items.prefix(8) {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let previewData = try? await photoProcessor.process(data).thumbnailData
                drafts.append(PhotoDraft(rawImageData: data, previewImageData: previewData, caption: nil))
            }
        }
        newPhotos = drafts
    }
}

private struct EditVisitDrinkCategoryChips: View {
    @Binding var selection: DrinkCategory

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RoadBeansSpacing.sm) {
                ForEach(DrinkCategory.allCases, id: \.self) { category in
                    Button {
                        selection = category
                    } label: {
                        HStack(spacing: RoadBeansSpacing.xs) {
                            Icon(.drink(category), size: 16, active: selection == category)
                            Text(category.displayName)
                        }
                        .roadBeansStyle(.labelM)
                        .padding(.horizontal, RoadBeansSpacing.md)
                        .padding(.vertical, 6)
                        .background(selection == category ? Color.accent(.default) : Color.clear, in: Capsule())
                        .foregroundStyle(selection == category ? Color.accent(.on) : Color.ink(.secondary))
                        .overlay {
                            if selection != category {
                                Capsule().stroke(Color.divider(.strong), lineWidth: 1)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selection == category ? [.isSelected] : [])
                }
            }
        }
    }
}

private struct PhotoEmptyDropZone: View {
    var body: some View {
        VStack(spacing: RoadBeansSpacing.sm) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Color.accent(.default))

            Text("No photos attached")
                .roadBeansStyle(.headline)

            Text("Add menus, cups, and receipt shots from this stop.")
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

private struct PhotoThumbnailData: View {
    let data: Data
    let size: CGFloat
    let radius: CGFloat
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .task(id: data) {
            image = UIImage(data: data)
        }
    }
}
