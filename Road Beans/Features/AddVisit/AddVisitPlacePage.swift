import SwiftUI

struct AddVisitPlacePage: View {
    @Bindable var model: AddVisitFlowModel
    @State private var showingCustomPlace = false

    var body: some View {
        VStack(spacing: 0) {
            searchField

            if model.searchState == .loading {
                ProgressView("Searching places...")
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let message = model.searchState.errorMessage {
                failedSearchState(message)
            } else if model.searchResults.isEmpty && !model.searchText.isEmpty {
                emptySearchState
            } else {
                searchResultsList
            }

            Spacer(minLength: 0)

            Button {
                showingCustomPlace = true
            } label: {
                Label("+ Custom place", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .sheet(isPresented: $showingCustomPlace) {
            CustomPlaceSheet { draft in
                model.selectCustom(draft)
                showingCustomPlace = false
            }
        }
    }

    private var searchField: some View {
        TextField("Search for a place", text: $model.searchText)
            .textFieldStyle(.roundedBorder)
            .padding()
            .onChange(of: model.searchText) {
                model.search()
            }
    }

    private var emptySearchState: some View {
        VStack(spacing: 12) {
            Text("No matches.")
                .foregroundStyle(.secondary)

            Button("+ Add as custom place") {
                showingCustomPlace = true
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    private func failedSearchState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                model.search()
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    private var searchResultsList: some View {
        List(model.searchResults, id: \.self) { draft in
            Button {
                model.selectMapKit(draft)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: draft.kind.sfSymbol)
                        .foregroundStyle(draft.kind.accentColor)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(draft.name)
                            .font(.roadBeansBody)

                        if let address = draft.address, !address.isEmpty {
                            Text(address)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .listStyle(.plain)
    }
}

private struct CustomPlaceSheet: View {
    let onConfirm: (CustomPlaceDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var kind: PlaceKind = .other
    @State private var address = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)

                Picker("Kind", selection: $kind) {
                    ForEach(PlaceKind.allCases, id: \.self) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }

                TextField("Address (optional)", text: $address)
            }
            .navigationTitle("Custom Place")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onConfirm(
                            CustomPlaceDraft(
                                name: trimmedName,
                                kind: kind,
                                address: trimmedAddress.isEmpty ? nil : trimmedAddress
                            )
                        )
                    }
                    .disabled(trimmedName.isEmpty)
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
}
