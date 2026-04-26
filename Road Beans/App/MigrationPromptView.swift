import SwiftUI

struct MigrationPromptView: View {
    let keepLocalOnly: () -> Void

    @Environment(\.dataExportService) private var exportService
    @State private var exportURL: URL?
    @State private var isExporting = false
    @State private var exportError: String?

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "icloud.and.arrow.up.fill")
                .font(.largeTitle)

            Text("Bring your existing road trip data into iCloud?")
                .font(.roadBeansHeadline)
                .multilineTextAlignment(.center)

            Text("Automatic migration is not yet supported. Export your data, then reinstall to start fresh with iCloud sync.")
                .font(.roadBeansBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task { await prepareExport() }
            } label: {
                if isExporting {
                    Label("Preparing…", systemImage: "arrow.clockwise")
                } else {
                    Label("Export Backup", systemImage: "square.and.arrow.up")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isExporting)

            if let exportURL {
                ShareLink(item: exportURL) {
                    Label("Share Export File", systemImage: "square.and.arrow.up")
                }
            }

            if let exportError {
                Text(exportError)
                    .font(.roadBeansBody)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button("Keep Local Only", action: keepLocalOnly)
                .buttonStyle(.bordered)
        }
        .padding()
    }

    private func prepareExport() async {
        isExporting = true
        exportError = nil
        exportURL = nil
        defer { isExporting = false }
        do {
            exportURL = try await exportService.writeExportFile()
        } catch {
            exportError = "Export failed. Please try again."
        }
    }
}

#Preview {
    MigrationPromptView(keepLocalOnly: {})
}
