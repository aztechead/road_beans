import SwiftUI

struct EditPlaceView: View {
    let detail: PlaceDetail
    let save: (UpdatePlaceCommand) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var kind: PlaceKind
    @State private var address: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(detail: PlaceDetail, save: @escaping (UpdatePlaceCommand) async throws -> Void) {
        self.detail = detail
        self.save = save
        _name = State(initialValue: detail.name)
        _kind = State(initialValue: detail.kind)
        _address = State(initialValue: detail.address ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)

                Picker("Kind", selection: $kind) {
                    ForEach(PlaceKind.allCases, id: \.self) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }

                TextField("Address", text: $address)

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Edit Stop")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Save") {
                        Task { await performSave() }
                    }
                    .disabled(isSaving || trimmedName.isEmpty)
                }
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedAddress: String {
        address.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func performSave() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            try await save(
                UpdatePlaceCommand(
                    id: detail.id,
                    name: trimmedName,
                    kind: kind,
                    address: trimmedAddress.isEmpty ? nil : trimmedAddress
                )
            )
            NotificationCenter.default.post(name: .roadBeansPlaceUpdated, object: nil)
            dismiss()
        } catch {
            errorMessage = "Could not save this stop."
        }
    }
}
