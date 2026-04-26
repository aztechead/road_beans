import SwiftUI

struct BackupSettingsView: View {
    @Environment(\.dataExportService) private var exportService
    @State private var exportURL: URL?
    @State private var isExporting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: RoadBeansTheme.Spacing.sm) {
                        Label("Export Road Beans JSON", systemImage: "square.and.arrow.up")
                            .font(.roadBeansHeadline)

                        Text("Creates a versioned backup with places, visits, drinks, tags, and photo metadata. Photo image files are not included yet.")
                            .font(.roadBeansBody)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)

                    Button {
                        Task { await prepareExport() }
                    } label: {
                        if isExporting {
                            ProgressView("Preparing export...")
                        } else {
                            Label("Prepare Export", systemImage: "doc.badge.gearshape")
                        }
                    }
                    .disabled(isExporting)

                    if let exportURL {
                        ShareLink(item: exportURL) {
                            Label("Share Export File", systemImage: "square.and.arrow.up")
                        }
                    }
                } header: {
                    Text("Backup")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Backup")
            .roadBeansScreenBackground()
        }
    }

    private func prepareExport() async {
        isExporting = true
        errorMessage = nil
        defer { isExporting = false }

        do {
            exportURL = try await exportService.writeExportFile()
        } catch {
            exportURL = nil
            errorMessage = "Road Beans could not prepare the export file. Try again."
        }
    }
}

#Preview {
    BackupSettingsView()
}
