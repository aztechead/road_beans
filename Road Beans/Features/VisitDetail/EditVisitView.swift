import PhotosUI
import SwiftUI
import UIKit

struct EditVisitView: View {
    let detail: VisitDetail
    let save: (UpdateVisitCommand) async throws -> Void

    @Environment(\.dismiss) private var dismiss
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
            Form {
                DatePicker("When", selection: $date)

                Section("Visit Tags") {
                    TextField("roadtrip, smooth, favorite", text: $visitTags)
                        .textInputAutocapitalization(.never)
                }

                Section("Drinks") {
                    ForEach(drinks.indices, id: \.self) { index in
                        drinkEditor(index)
                    }
                    .onDelete { offsets in
                        drinks.remove(atOffsets: offsets)
                    }

                    Button {
                        drinks.append(DrinkDraft(name: "", category: .drip, rating: 3, tags: []))
                    } label: {
                        Label("Add drink", systemImage: "plus")
                    }
                }

                Section("Photos") {
                    if existingPhotos.isEmpty && newPhotos.isEmpty {
                        Text("No photos attached.")
                            .foregroundStyle(.secondary)
                    }

                    ForEach(existingPhotos) { photo in
                        existingPhotoRow(photo)
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            removedPhotoIDs.insert(existingPhotos[index].id)
                        }
                        existingPhotos.remove(atOffsets: offsets)
                    }

                    if !newPhotos.isEmpty {
                        newPhotoStrip
                    }

                    PhotosPicker(selection: $pickerItems, maxSelectionCount: 8, matching: .images) {
                        Label("Add photos", systemImage: "photo.on.rectangle")
                    }
                    .onChange(of: pickerItems) { _, items in
                        Task { await loadPhotos(items) }
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
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
        VStack(alignment: .leading, spacing: 12) {
            TextField("Drink name", text: $drinks[index].name)

            DrinkCategoryPicker(selection: $drinks[index].category)

            TextField(
                "Tags",
                text: Binding(
                    get: { drinks[index].tags.joined(separator: ", ") },
                    set: { drinks[index].tags = parseTags($0) }
                )
            )
            .textInputAutocapitalization(.never)

            BeanSlider(value: $drinks[index].rating)
                .padding(.top, 12)
        }
        .padding(.vertical, 6)
    }

    private func existingPhotoRow(_ photo: PhotoReference) -> some View {
        HStack(spacing: 12) {
            if let image = UIImage(data: photo.thumbnailData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                Image(systemName: "photo")
                    .frame(width: 56, height: 56)
                    .foregroundStyle(.secondary)
            }

            Text(photo.caption ?? "Photo")
                .foregroundStyle(.secondary)
        }
    }

    private var newPhotoStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(newPhotos.enumerated()), id: \.offset) { _, draft in
                    if let image = UIImage(data: draft.rawImageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                drafts.append(PhotoDraft(rawImageData: data, caption: nil))
            }
        }
        newPhotos = drafts
    }
}
