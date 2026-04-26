# iCloud Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:subagent-driven-development (recommended) or superpowers-extended-cc:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Activate SwiftData's built-in CloudKit sync by fixing the entitlements, replacing the dead migration prompt, and surfacing iCloud status in the Backup tab.

**Architecture:** Three independent file changes with no shared state. The entitlements fix is pure XML. The MigrationPromptView overhaul removes a dead code path and wires in the existing `DataExportService` environment value. The BackupSettingsView adds a status section that reads the already-observable `PersistenceController` from the SwiftUI environment.

**Tech Stack:** SwiftUI, SwiftData, CloudKit, `@Observable` (`PersistenceController`), environment keys (`DataExportService`)

---

## File Structure

| File | Change |
|------|--------|
| `Road Beans/Road_Beans.entitlements` | Add `iCloud.brainmeld.Road-Beans` to container identifiers array |
| `Road Beans/App/MigrationPromptView.swift` | Remove `migrate` param + dead button; add info note, Export Backup flow, Keep Local Only |
| `Road Beans/App/RootView.swift` | Remove `migrate:` argument from `MigrationPromptView` call site |
| `Road Beans/Features/Backup/BackupSettingsView.swift` | Add `@Environment(PersistenceController.self)` and `Section("iCloud")` status row |

---

### Task 1: Entitlements — Add iCloud Container Identifier

**Goal:** Add `iCloud.brainmeld.Road-Beans` to `Road_Beans.entitlements` so `NSPersistentCloudKitContainer` can connect to the right container.

**Files:**
- Modify: `Road Beans/Road_Beans.entitlements`

**Acceptance Criteria:**
- [ ] `com.apple.developer.icloud-container-identifiers` array contains `iCloud.brainmeld.Road-Beans`
- [ ] `Road_Beans.Local.entitlements` is unchanged
- [ ] App builds clean

**Verify:** `xcodebuild -project "Road Beans.xcodeproj" -scheme "Road Beans" -destination 'generic/platform=iOS Simulator' build` → `BUILD SUCCEEDED`

**Steps:**

- [ ] **Step 1: Edit the entitlements file**

Open `Road Beans/Road_Beans.entitlements`. The file currently reads:

```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array/>
```

Replace that empty array with:

```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.brainmeld.Road-Beans</string>
</array>
```

The full file after the change:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>aps-environment</key>
	<string>development</string>
	<key>com.apple.developer.icloud-container-identifiers</key>
	<array>
		<string>iCloud.brainmeld.Road-Beans</string>
	</array>
	<key>com.apple.developer.icloud-services</key>
	<array>
		<string>CloudKit</string>
	</array>
</dict>
</plist>
```

- [ ] **Step 2: Build to confirm no errors**

Run: `xcodebuild -project "Road Beans.xcodeproj" -scheme "Road Beans" -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -5`

Expected: last line contains `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add "Road Beans/Road_Beans.entitlements"
git commit -m "feat: add iCloud container identifier to entitlements"
```

---

### Task 2: MigrationPromptView — Replace Dead Migrate Button

**Goal:** Remove the silently-failing "Yes, migrate" button and replace it with a clear info note, an Export Backup flow, and a Keep Local Only button.

**Files:**
- Modify: `Road Beans/App/MigrationPromptView.swift`
- Modify: `Road Beans/App/RootView.swift`

**Acceptance Criteria:**
- [ ] `MigrationPromptView` no longer has a `migrate` parameter
- [ ] Info note explains migration is not yet supported
- [ ] "Export Backup" button triggers `exportService.writeExportFile()` then shows a `ShareLink`
- [ ] "Keep Local Only" button calls `keepLocalOnly` (maps to `persistence.deferMigration()`)
- [ ] `RootView` call site compiles without the removed `migrate:` argument
- [ ] App builds clean

**Verify:** `xcodebuild -project "Road Beans.xcodeproj" -scheme "Road Beans" -destination 'generic/platform=iOS Simulator' build` → `BUILD SUCCEEDED`

**Steps:**

- [ ] **Step 1: Rewrite `MigrationPromptView.swift`**

Replace the entire file contents with:

```swift
import SwiftUI

struct MigrationPromptView: View {
    let keepLocalOnly: () -> Void

    @Environment(\.dataExportService) private var exportService
    @State private var exportURL: URL?
    @State private var isExporting = false

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

            Button("Keep Local Only", action: keepLocalOnly)
                .buttonStyle(.bordered)
        }
        .padding()
    }

    private func prepareExport() async {
        isExporting = true
        defer { isExporting = false }
        exportURL = try? await exportService.writeExportFile()
    }
}

#Preview {
    MigrationPromptView(keepLocalOnly: {})
}
```

- [ ] **Step 2: Update the call site in `RootView.swift`**

Current code at line 14–19 in `Road Beans/App/RootView.swift`:

```swift
case .pendingMigration:
    MigrationPromptView(
        keepLocalOnly: persistence.deferMigration,
        migrate: {
            try? await persistence.migrateLocalToCloudKit()
        }
    )
```

Replace with:

```swift
case .pendingMigration:
    MigrationPromptView(keepLocalOnly: persistence.deferMigration)
```

- [ ] **Step 3: Build to confirm no errors**

Run: `xcodebuild -project "Road Beans.xcodeproj" -scheme "Road Beans" -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -5`

Expected: last line contains `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add "Road Beans/App/MigrationPromptView.swift" "Road Beans/App/RootView.swift"
git commit -m "feat: replace dead migrate button with export guidance in MigrationPromptView"
```

---

### Task 3: BackupSettingsView — iCloud Status Section

**Goal:** Add a `Section("iCloud")` above the existing Backup section that reactively displays the current `PersistenceController.mode`.

**Files:**
- Modify: `Road Beans/Features/Backup/BackupSettingsView.swift`

**Acceptance Criteria:**
- [ ] `BackupSettingsView` reads `PersistenceController` via `@Environment(PersistenceController.self)`
- [ ] `Section("iCloud")` appears above the existing `Section("Backup")`
- [ ] Each of the four `PersistenceMode` cases shows the correct icon, color, and label from the spec
- [ ] No new environment keys or services introduced
- [ ] App builds clean

**Verify:** `xcodebuild -project "Road Beans.xcodeproj" -scheme "Road Beans" -destination 'generic/platform=iOS Simulator' build` → `BUILD SUCCEEDED`

**Steps:**

- [ ] **Step 1: Add environment property to `BackupSettingsView`**

Open `Road Beans/Features/Backup/BackupSettingsView.swift`.

After line 3 (`@Environment(\.dataExportService) private var exportService`), add:

```swift
@Environment(PersistenceController.self) private var persistence
```

So the top of the struct reads:

```swift
struct BackupSettingsView: View {
    @Environment(\.dataExportService) private var exportService
    @Environment(PersistenceController.self) private var persistence
    @State private var exportURL: URL?
    @State private var isExporting = false
    @State private var errorMessage: String?
```

- [ ] **Step 2: Add the iCloud section above the existing Backup section**

In `body`, before the existing `Section { … } header: { Text("Backup") }` block, insert:

```swift
Section("iCloud") {
    switch persistence.mode {
    case .cloudKitBacked:
        Label("iCloud Sync Active", systemImage: "checkmark.icloud.fill")
            .foregroundStyle(.green)
    case .localOnly:
        Label("iCloud Sync Off", systemImage: "icloud.slash")
            .foregroundStyle(.secondary)
    case .pendingMigration:
        Label("iCloud Ready — local data pending", systemImage: "icloud.and.arrow.up")
            .foregroundStyle(.orange)
    case .pendingRelaunch:
        Label("iCloud Account Changed — restart required", systemImage: "exclamationmark.icloud")
            .foregroundStyle(.orange)
    }
}
```

The full `body` after both changes:

```swift
var body: some View {
    NavigationStack {
        List {
            Section("iCloud") {
                switch persistence.mode {
                case .cloudKitBacked:
                    Label("iCloud Sync Active", systemImage: "checkmark.icloud.fill")
                        .foregroundStyle(.green)
                case .localOnly:
                    Label("iCloud Sync Off", systemImage: "icloud.slash")
                        .foregroundStyle(.secondary)
                case .pendingMigration:
                    Label("iCloud Ready — local data pending", systemImage: "icloud.and.arrow.up")
                        .foregroundStyle(.orange)
                case .pendingRelaunch:
                    Label("iCloud Account Changed — restart required", systemImage: "exclamationmark.icloud")
                        .foregroundStyle(.orange)
                }
            }

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
```

- [ ] **Step 3: Build to confirm no errors**

Run: `xcodebuild -project "Road Beans.xcodeproj" -scheme "Road Beans" -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -5`

Expected: last line contains `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add "Road Beans/Features/Backup/BackupSettingsView.swift"
git commit -m "feat: add iCloud sync status section to BackupSettingsView"
```
