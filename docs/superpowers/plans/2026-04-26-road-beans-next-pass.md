# Road Beans Next-Pass Plan

> **For agentic workers:** implement one task at a time. Each task should end with tests/build verification, then a focused commit. Do not bundle unrelated polish with functional fixes.

**Goal:** Move Road Beans from “feature-complete v1 scaffold” to a more installable, polished, and user-validatable iOS 26 app. This plan focuses on correctness, iPhone install readiness, current-location behavior, MapKit/AppIntents cleanup, usability, and visual polish.

**Baseline:** As of commit `0ea176e`, simulator builds/tests pass, current-location sourcing is wired for near-me, and known command-line code warnings are cleared. Physical iPhone install is still blocked by signing/capability configuration when using a personal Apple team with iCloud and Push entitlements enabled.

**Repo conventions:**
- App source root: `Road Beans/`
- Tests root: `Road BeansTests/`
- Project: `Road Beans.xcodeproj`
- Scheme: `Road Beans`
- Test style: Swift Testing (`import Testing`, `@Test`, `#expect`)
- Verify build: `xcodebuild -project "Road Beans.xcodeproj" -scheme "Road Beans" -destination 'generic/platform=iOS Simulator' build`
- Verify tests: `xcodebuild -project "Road Beans.xcodeproj" -scheme "Road Beans" -destination 'platform=iOS Simulator,name=iPhone 17' test`

---

## Dependency Order

1. Task 1 unblocks reliable local device installs.
2. Tasks 2 and 3 remove Xcode issue-noise and modernize iOS 26 integration.
3. Tasks 4 through 8 improve core product functionality.
4. Tasks 9 through 12 improve polish, QA, and maintainability.

---

## Task 1: Add Explicit Local-Device Capability Mode

**Status:** Completed in implementation pass after this plan was created.

**Goal:** Make the app installable on a personal-team iPhone without disabling core local functionality. Keep CloudKit/Push-capable configuration available for a paid Developer Program team.

**Rationale:** Current physical-device builds fail because a personal team cannot provision iCloud and Push capabilities for bundle `brainmeld.Road-Beans`. This is not an app compiler problem; it is a signing/capability mode problem.

**Files:**
- Modify: `Road Beans.xcodeproj/project.pbxproj`
- Modify/Create: `Road Beans/Road_Beans.entitlements`
- Create: `Road Beans/Road_Beans.Local.entitlements`
- Modify: `Road Beans/App/Persistence/PersistenceController.swift`
- Modify: `Road Beans/Road_BeansApp.swift`
- Create tests in `Road BeansTests/ServiceTests/` or `Road BeansTests/PersistenceTests/`

**Implementation Notes:**
- Add a Debug-local build setting or configuration flag such as `ROAD_BEANS_LOCAL_DEVICE=1`.
- Local-device mode should remove `aps-environment`, CloudKit services, and iCloud container identifiers from the active entitlements.
- Local-device mode should force local-only persistence even if iCloud is signed in.
- Keep the CloudKit-capable path for paid-team builds.
- Do not delete the CloudKit code. Make capability selection explicit.

**Acceptance Criteria:**
- `xcodebuild ... -destination 'generic/platform=iOS Simulator' build` succeeds.
- `xcodebuild ... -destination 'generic/platform=iOS' build` no longer fails because of iCloud/Push capabilities when local-device mode is selected.
- The app can run with local SwiftData persistence and no iCloud entitlement.
- The README or QA checklist tells the developer which mode to use for personal-team iPhone installs.

**Verify:**
```bash
xcodebuild -project "Road Beans.xcodeproj" -scheme "Road Beans" -destination 'generic/platform=iOS Simulator' build
xcodebuild -project "Road Beans.xcodeproj" -scheme "Road Beans" -destination 'generic/platform=iOS' build
```

---

## Task 2: Implement the Real iOS 26 MapKit Address Fix

**Status:** Completed in implementation pass after this plan was created.

**Goal:** Fully remove deprecated `MKPlacemark`/`MKMapItem.placemark` assumptions and preserve useful address display with iOS 26 MapKit APIs.

**Rationale:** The quick deprecation cleanup uses `MKMapItem.location`, `address`, and `addressRepresentations`, but the model still has older structured fields like street number, street name, region, and postal code. iOS 26 MapKit no longer exposes those through `MKMapItem` directly. The real fix is to adjust the app’s MapKit import/read-model path to store what the modern API reliably provides.

**Files:**
- Modify: `Road Beans/Services/LocationSearchService.swift`
- Modify: `Road Beans/Commands/` place reference types if needed
- Modify: `Road Beans/Models/Place.swift` only if the existing schema forces deprecated address granularity
- Modify: `Road Beans/Repositories/Local/LocalPlaceRepository.swift`
- Modify tests: `Road BeansTests/ServiceTests/LocationSearchServiceTests.swift`
- Add tests for address formatting and missing structured fields

**Implementation Notes:**
- Use `MKMapItem.location.coordinate` for coordinates.
- Use `MKMapItem.address?.shortAddress`, `MKMapItem.address?.fullAddress`, and `MKMapItem.addressRepresentations?.fullAddress(includingRegion:singleLine:)` for display address.
- Use `addressRepresentations.cityName` and `regionName` only for UI/context fields.
- Do not reintroduce `item.placemark` or `MKPlacemark`.
- If granular fields are still necessary for v2 upload, add a separate enrichment step later using CoreLocation geocoding; do not block MapKit search on deprecated fields.

**Acceptance Criteria:**
- `rg "placemark|MKPlacemark" "Road Beans"` returns no app source usage.
- Location search tests cover `MKMapItem` conversion behavior through a seam or mapper, not live network search.
- Place detail and list screens display a human-readable address after MapKit selection.
- Clean build has no MapKit deprecation warnings.

**Verify:**
```bash
rg "placemark|MKPlacemark" "Road Beans"
xcodebuild -project "Road Beans.xcodeproj" -scheme "Road Beans" -destination 'generic/platform=iOS Simulator' clean build
```

---

## Task 3: Replace the AppIntents Metadata Warning With Useful App Intents

**Status:** Completed in implementation pass after this plan was created.

**Goal:** Add a small real AppIntents surface so Xcode’s AppIntents metadata step is meaningful and the warning is removed for the right reason.

**Rationale:** The current warning says metadata extraction was skipped because there is no AppIntents dependency. Suppressing the build phase would hide the warning, but Road Beans has useful shortcuts candidates. The better fix is to add AppIntents intentionally.

**Files:**
- Create: `Road Beans/App/Intents/RoadBeansShortcuts.swift`
- Create: `Road Beans/App/Intents/OpenAddVisitIntent.swift`
- Create: `Road Beans/App/Intents/OpenRecentVisitsIntent.swift`
- Modify: `Road Beans/Road_BeansApp.swift`
- Modify: app navigation/root routing files as needed
- Add tests if routing is pure/testable

**Implementation Notes:**
- Add `import AppIntents` in new intent files.
- Add an `AppShortcutsProvider` with phrases like:
  - “Add a stop in Road Beans”
  - “Open recent visits in Road Beans”
  - “Show my road beans”
- Intents should return `.result(opensIntent:)` or open the app via a lightweight route/deep-link mechanism.
- Add an internal route enum such as `AppRoute.addVisit` and `AppRoute.recentVisits`.
- If deep-link handling is needed, use URL routes such as `roadbeans://add-visit` and `roadbeans://recent`.

**Acceptance Criteria:**
- Clean build no longer emits `Metadata extraction skipped. No AppIntents.framework dependency found.`
- App launches correctly from normal tap.
- App route handling can navigate to Add Visit and Recent/List.
- Shortcuts are visible to the system on a simulator/device that supports App Shortcuts indexing.

**Verify:**
```bash
xcodebuild -project "Road Beans.xcodeproj" -scheme "Road Beans" -destination 'generic/platform=iOS Simulator' clean build 2>&1 | rg "AppIntents|warning:"
```

---

## Task 4: Improve Current Location UX and Map Behavior

**Status:** Completed in implementation pass after this plan was created.

**Goal:** Make near-me feel product-grade instead of a binary toggle with a blank/failure state.

**Files:**
- Modify: `Road Beans/Features/Map/MapTabView.swift`
- Modify: `Road Beans/Features/Map/MapTabViewModel.swift`
- Modify: `Road Beans/Services/CurrentLocationProvider.swift`
- Add tests: `Road BeansTests/ViewModelTests/MapTabViewModelTests.swift`

**Implementation Notes:**
- Add loading state while requesting location.
- Add last-known coordinate fallback with age/accuracy threshold.
- Add retry action in the “Current Location Unavailable” state.
- Center map camera on current coordinate when near-me succeeds.
- Show the user location marker or a clear “search radius” visual if supported by current SwiftUI Map APIs.

**Acceptance Criteria:**
- Toggle near-me shows progress while fetching location.
- If location fails, the user sees retry and settings guidance.
- If location succeeds, map camera centers near the current coordinate and annotations are filtered.
- Tests cover success, denied, unavailable, and retry.

**Verify:**
```bash
xcodebuild -project "Road Beans.xcodeproj" -scheme "Road Beans" -destination 'platform=iOS Simulator,name=iPhone 17' test -only-testing:"Road BeansTests/MapTabViewModelTests"
```

---

## Task 5: Add Empty, Error, and Loading States Across Core Screens

**Status:** Completed in implementation pass after this plan was created.

**Goal:** Ensure the app is understandable with no data, failed repository operations, or slow operations.

**Files:**
- Modify: `Road Beans/Features/PlaceList/`
- Modify: `Road Beans/Features/PlaceDetail/`
- Modify: `Road Beans/Features/VisitDetail/`
- Modify: `Road Beans/Features/AddVisit/`
- Modify: `Road Beans/Features/Map/`
- Add view-model tests for each state

**Implementation Notes:**
- Standardize screen state enum: `.idle`, `.loading`, `.loaded`, `.empty`, `.failed(message)`.
- Prefer user-actionable copy over raw error text.
- Empty states should guide first action: “Add your first stop”.
- Error states should include retry where the action is safe.

**Acceptance Criteria:**
- No screen remains indefinitely as `ProgressView()` after an error.
- Empty app state clearly explains what to do next.
- Repository failure tests assert view-model state transitions.

---

## Task 6: Add First-Run Onboarding and Permission Priming

**Status:** Completed in implementation pass after this plan was created.

**Goal:** Explain what Road Beans does, when location is used, and why iCloud may be requested before system prompts appear.

**Files:**
- Create: `Road Beans/Features/Onboarding/`
- Modify: `Road Beans/ContentView.swift`
- Modify: app storage/user defaults service if present
- Add tests for onboarding completion state

**Implementation Notes:**
- Keep onboarding short: 3 cards max.
- Explain location as “find stops near you”; do not request permission until the user turns on near-me or explicitly taps “Enable”.
- Explain iCloud as optional sync/backup if CloudKit mode is active.
- Add “Skip for now”.

**Acceptance Criteria:**
- First launch shows onboarding.
- Completed onboarding is persisted.
- Permission prompts are not shown automatically on app launch.

---

## Task 7: Add Edit Visit and Edit Place Flows

**Status:** Completed in implementation pass after this plan was created.

**Goal:** Complete the basic CRUD loop so mistaken entries can be corrected.

**Files:**
- Modify: `Road Beans/Features/VisitDetail/`
- Modify: `Road Beans/Features/PlaceDetail/`
- Modify: `Road Beans/Features/AddVisit/` or create shared edit flow
- Modify repositories if update methods need richer commands
- Add tests for update commands

**Implementation Notes:**
- Reuse Add Visit form components where possible.
- Support editing rating, date, drinks, tags, notes, and photos.
- Place edit should support kind and custom display name at minimum.
- Preserve tombstone/sync dirty behavior.

**Acceptance Criteria:**
- Existing visit can be edited and saved.
- Updated values appear in Recent, Place Detail, and Map after save.
- Tests cover repository update and view-model save success/failure.

---

## Task 8: Improve Search and Filtering

**Status:** Completed in implementation pass after this plan was created.

**Goal:** Make list search useful for real road-trip recall.

**Files:**
- Modify: `Road Beans/Features/PlaceList/`
- Modify read models if needed
- Add tests in `Road BeansTests/ViewModelTests/PlaceListViewModelTests.swift`

**Implementation Notes:**
- Add filters for place kind, rating range, tags, and date range.
- Support combined filters.
- Preserve selected mode/search when navigating away and back.
- Add clear-filter affordance.

**Acceptance Criteria:**
- Search works by place, drink, tag, and notes if notes exist.
- Filters can be combined and cleared.
- Tests cover combined filters and stable state.

---

## Task 9: Design-System Polish Pass

**Status:** Completed in implementation pass after this plan was created.

**Goal:** Make Road Beans look intentional and consistent across screens.

**Files:**
- Modify: `Road Beans/DesignSystem/`
- Modify major feature views
- Update manual QA screenshots/checklist if present

**Implementation Notes:**
- Define spacing, corner radius, typography, tint, and card rules in one place.
- Audit Liquid Glass usage for readability and contrast.
- Add a distinct map annotation style for each `PlaceKind`.
- Improve Bean Slider touch target, haptics, and accessibility labels.
- Verify dynamic type and landscape.

**Acceptance Criteria:**
- Screens share consistent spacing/type/card treatment.
- Dynamic Type does not clip on primary flows.
- VoiceOver labels are meaningful for rating, map markers, add/edit actions.

---

## Task 10: Add Lightweight UI Smoke Tests or Screenshot QA Harness

**Status:** Completed in implementation pass after this plan was created.

**Goal:** Catch broken navigation and blank screens before manual testing.

**Files:**
- Create UI test target if appropriate, or a preview/screenshot harness under tests
- Add seed-data factory usable by previews/tests

**Implementation Notes:**
- Keep UI coverage small: launch, add visit start, list empty state, map tab, detail navigation.
- Prefer deterministic local-only mode.
- Avoid depending on live MapKit search.

**Acceptance Criteria:**
- A single command exercises primary navigation without network.
- Seed data can populate previews and tests consistently.

---

## Task 11: Add Data Export and Backup Safety

**Goal:** Reduce user risk before CloudKit migration is fully implemented.

**Files:**
- Create export service
- Add UI entry in Settings or Profile screen
- Add DTO tests

**Implementation Notes:**
- Export visits, places, drinks, tags, and photo metadata as JSON.
- Photo binary export can be a follow-up; do not block JSON export.
- Share via system share sheet.

**Acceptance Criteria:**
- User can export local data to a JSON file.
- Export schema is versioned.
- Tests verify round-trip encoding of exported data.

---

## Task 12: Update Manual QA and Release Readiness Docs

**Goal:** Make the repo clear for the next developer or agent.

**Files:**
- Modify: `docs/superpowers/qa/2026-04-25-manual-qa-checklist.md`
- Create: `docs/superpowers/qa/2026-04-26-install-and-release-checklist.md`
- Modify: `docs/superpowers/plans/2026-04-25-road-beans.md` only if a known limitation is now obsolete

**Implementation Notes:**
- Document simulator run.
- Document personal-team iPhone run.
- Document paid-team CloudKit run.
- Include known limitations and exact Xcode build destinations.

**Acceptance Criteria:**
- A new developer can choose the correct signing mode.
- QA checklist covers onboarding, add visit, map near-me, edit/delete, export, and iCloud mode.
- Known limitations are accurate.

---

## Recommended Agent Split

- **Agent A:** Task 1, signing/capability mode.
- **Agent B:** Task 2, MapKit model/search cleanup.
- **Agent C:** Task 3, AppIntents and route handling.
- **Agent D:** Task 4, current-location UX.
- **Agent E:** Tasks 5 and 6, empty states and onboarding.
- **Agent F:** Tasks 7 and 8, edit/search functionality.
- **Agent G:** Tasks 9 through 12, design polish, smoke QA, export, release docs.

Do not run Agents A, B, and C against the same project file simultaneously unless their write scopes are explicitly coordinated.
