# iCloud Sync — Design Spec

**Date:** 2026-04-26
**Scope:** Activate SwiftData's built-in CloudKit sync so data persists across reinstalls. No custom sync engine. No migration implementation (fresh start).

---

## Background

`PersistenceController` already routes fresh installs with iCloud signed in to `.cloudKitBacked` mode, which creates an `NSPersistentCloudKitContainer` backed by `iCloud.brainmeld.Road-Beans`. SwiftData handles all sync automatically from there. The only thing blocking this from working is a missing container identifier in the entitlements and an unhandled migration prompt dead-end.

---

## 1. Entitlements Fix

**File:** `Road Beans/Road_Beans.entitlements`

`com.apple.developer.icloud-container-identifiers` is currently an empty array. Add the container identifier:

```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.brainmeld.Road-Beans</string>
</array>
```

`Road_Beans.Local.entitlements` (used for personal-team local-device builds) remains empty — no CloudKit for that path.

**Acceptance criteria:**
- `Road_Beans.entitlements` contains `iCloud.brainmeld.Road-Beans` in the container identifiers array
- `Road_Beans.Local.entitlements` is unchanged
- App builds clean in both configurations

---

## 2. Migration Prompt — Graceful Dead-End

**File:** `Road Beans/App/MigrationPromptView.swift`

`migrateLocalToCloudKit()` throws `notYetImplemented` and the caller silently swallows the error via `try?`, leaving the user stuck with no feedback. Fix: disable the "Yes, migrate" button and explain why.

Updated view shows:
- Info note at top: *"Automatic migration is not yet supported. Export your data, then reinstall to start fresh with iCloud sync."*
- **"Export Backup"** button — opens a `ShareLink` for the export flow (reuses `DataExportService` already injected at root via environment)
- **"Keep Local Only"** button — calls `keepLocalOnly` (`deferMigration()`), routes app to `.localOnly` mode as before
- "Yes, migrate" button removed entirely

**Acceptance criteria:**
- No button silently does nothing
- User can reach the export flow directly from the migration prompt
- `deferMigration()` path still functional
- `DataExportService` accessed via environment on `MigrationPromptView` (already available at root level)

---

## 3. iCloud Sync Status in Backup Tab

**File:** `Road Beans/Features/Backup/BackupSettingsView.swift`

Add a new `Section("iCloud")` above the existing Backup section. Reads `PersistenceController` from the SwiftUI environment (already injected at root).

Status rows by `persistence.mode`:

| Mode | Icon | Label |
|------|------|-------|
| `.cloudKitBacked` | `checkmark.icloud.fill` (green) | "iCloud Sync Active" |
| `.localOnly` | `icloud.slash` (secondary) | "iCloud Sync Off" |
| `.pendingMigration` | `icloud.and.arrow.up` (orange) | "iCloud Ready — local data pending" |
| `.pendingRelaunch` | `exclamationmark.icloud` (orange) | "iCloud Account Changed — restart required" |

No new services or state needed — `persistence.mode` is already `@Observable`.

**Acceptance criteria:**
- Backup tab shows iCloud status row
- Row updates reactively when `persistence.mode` changes
- No new environment keys or services introduced

---

## Manual Developer Steps (not code)

These must be done by the developer in Xcode and Apple portals before the entitlements fix will work on a real device:

1. **Apple Developer Portal** → Identifiers → `brainmeld.Road-Beans` → Capabilities → enable iCloud → add container `iCloud.brainmeld.Road-Beans`
2. **App Store Connect** (or Developer Portal) → CloudKit Dashboard → create the `iCloud.brainmeld.Road-Beans` container if it doesn't already exist
3. **Xcode** → Target → Signing & Capabilities → `+` Capability → iCloud → tick CloudKit → select `iCloud.brainmeld.Road-Beans`
4. **Regenerate provisioning profile** — Xcode automatic signing handles this; or manually regenerate in the portal

---

## Files Changed

| File | Change |
|------|--------|
| `Road Beans/Road_Beans.entitlements` | Add container identifier |
| `Road Beans/App/MigrationPromptView.swift` | Replace dead-end migrate button with clear guidance |
| `Road Beans/Features/Backup/BackupSettingsView.swift` | Add iCloud status section |

---

## Out of Scope

- `migrateLocalToCloudKit()` implementation — deferred
- Conflict resolution or multi-device merge logic — handled automatically by CloudKit
- CloudKit push notifications for real-time sync — handled automatically by NSPersistentCloudKitContainer
- Photo binary sync to CloudKit — `VisitPhoto` stores `imageData: Data` which CloudKit will sync, but large assets may hit CloudKit record size limits; treat as a follow-up
