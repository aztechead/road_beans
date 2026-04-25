# Road Beans — Design Spec

**Date:** 2026-04-25
**Author:** Christopher Bobrowitz (with Claude)
**Repo:** https://github.com/aztechead/road_beans
**Target:** iOS 26.4+, SwiftUI, SwiftData, CloudKit, MapKit
**Status:** Approved scope; pending plan
**Revision:** 2 — addresses review at `2026-04-25-road-beans-design-review.md`

---

## 1. Purpose

Road Beans is a native iOS app for tracking coffee/drink stops along road-trip routes. It replaces an ad-hoc Notes-app workflow with a structured, fast, visually distinctive app. v1 is single-user and on-device (with CloudKit private-DB sync across the user's own devices). v2 will introduce a central remote database where multiple users' reviews are aggregated; v1 is engineered so that all existing reviews can be uploaded to that backend in one operation when v2 ships.

## 2. Scope

### v1 (this build)
- Single-user. Identity is implicit: the device's iCloud account.
- Track **Places** visited, each with one or more **Visits**, each with one or more **Drinks** rated 0.0–5.0 in 0.1 steps.
- **Place kinds** (fixed picker, drives icon + accent color): Coffee Shop, Truck Stop, Gas Station, Fast Food, Other.
- **Hybrid Place identification**: MapKit local search by default; "+ Custom place" fallback for unknown shops or offline use.
- **Visit-level photos** (one or more, optional; processed and thumbnailed — see §7).
- **Tags** on visits and drinks, with autocomplete from previously used tags. Tags are shared across both surfaces ("burnt" is one tag whether on a visit or a drink).
- **Three Liquid Glass tabs**: List, Map, + (combined add sheet).
- **Storage**: SwiftData with CloudKit private-DB when iCloud is available; local-only fallback when not. Persistence-mode state machine in §6.

### Deferred to v2
- Multi-user sync via central remote DB; aggregated cross-user ratings.
- "Upload all my existing reviews" first-launch flow when v2 onboards.
- Stats tab (favorites, top drinks, trends).
- Trip/route grouping (additive — visits already carry dates).
- Per-drink photos.

### Out of scope (entirely)
- Authentication beyond CloudKit's implicit identity in v1.
- Social features, comments, sharing flows.
- Android, web, watchOS.

## 3. Data Model

Six SwiftData `@Model` entities. **CloudKit constraint: all relationships are optional with empty/nil defaults; no unique constraints; no required inverse.** Domain invariants (e.g., "a visit must have at least one drink") are enforced at the repository layer, not by the persisted shape.

```
Place ──< Visit ──< Drink
              │       │
              │       ├──> Tag (M:N, shared)
              ├──> Tag (M:N, shared)
              └──< VisitPhoto

Tombstone (flat, one row per locally-deleted entity)
```

### Persisted shape vs. domain shape

Each `@Model` is declared with optional relationships and default values to be CloudKit-compatible. A non-persisted `extension` on each model exposes domain accessors (`var place: Place { _place ?? .unknown }` style) so view/repository code reads as if relationships were required. Repositories enforce that domain invariants hold before save.

### Entities

**Place**
- `id: UUID = UUID()`
- `name: String = ""`
- `kind: PlaceKind = .other`
- `source: PlaceSource = .custom` — `.mapKit | .custom`
- `address: String? = nil` — display string
- `mapKitName: String? = nil` — original POI name as returned by MapKit
- `mapKitIdentifier: String? = nil` — POI identifier from `MKMapItem`
- `latitude: Double? = nil`
- `longitude: Double? = nil`
- `phoneNumber: String? = nil`
- `websiteURL: URL? = nil`
- `streetNumber: String? = nil`
- `streetName: String? = nil`
- `city: String? = nil`
- `region: String? = nil`
- `postalCode: String? = nil`
- `country: String? = nil`
- `createdAt: Date = .now`
- `lastModifiedAt: Date = .now`
- `@Relationship(deleteRule: .cascade, inverse: \Visit._place) var _visits: [Visit]? = []`
- *(plus sync metadata, see §5)*
- Convenience: `var visits: [Visit] { _visits ?? [] }`, `var coordinate: CLLocationCoordinate2D?` derived from lat/lng.

**Visit**
- `id: UUID = UUID()`
- `date: Date = .now`
- `@Relationship(inverse: \Place._visits) var _place: Place? = nil`
- `@Relationship(deleteRule: .cascade, inverse: \Drink._visit) var _drinks: [Drink]? = []`
- `@Relationship(inverse: \Tag._visits) var _tags: [Tag]? = []`
- `@Relationship(deleteRule: .cascade, inverse: \VisitPhoto._visit) var _photos: [VisitPhoto]? = []`
- `createdAt: Date = .now`
- `lastModifiedAt: Date = .now`
- *(plus sync metadata, see §5)*
- Domain invariant (enforced in `VisitRepository.save`): `_drinks` non-empty.

**Drink**
- `id: UUID = UUID()`
- `name: String = ""`
- `category: DrinkCategory = .other`
- `rating: Double = 3.0` — clamped to `[0.0, 5.0]`, rounded to nearest 0.1 by repository
- `@Relationship(inverse: \Visit._drinks) var _visit: Visit? = nil`
- `@Relationship(inverse: \Tag._drinks) var _tags: [Tag]? = []`
- `createdAt: Date = .now`
- `lastModifiedAt: Date = .now`
- *(plus sync metadata, see §5)*

**Tag**
- `id: UUID = UUID()`
- `name: String = ""` — normalized (trimmed + lowercased) before insert; lookup-or-create on use
- `@Relationship var _visits: [Visit]? = []`
- `@Relationship var _drinks: [Drink]? = []`
- `createdAt: Date = .now`
- `lastModifiedAt: Date = .now`
- *(plus sync metadata, see §5)*
- **`usageCount` is derived, not stored** — computed at query time as `(_visits?.count ?? 0) + (_drinks?.count ?? 0)`. Autocomplete fetches all tags, sorts by computed count + most-recent use, and slices.

**VisitPhoto**
- `id: UUID = UUID()`
- `@Attribute(.externalStorage) var imageData: Data = Data()` — processed full image (HEIC, ≤2048px long edge)
- `@Attribute(.externalStorage) var thumbnailData: Data = Data()` — generated thumbnail (JPEG, ≤256px long edge)
- `caption: String? = nil`
- `widthPx: Int = 0`
- `heightPx: Int = 0`
- `@Relationship(inverse: \Visit._photos) var _visit: Visit? = nil`
- `createdAt: Date = .now`
- `lastModifiedAt: Date = .now`
- *(plus sync metadata, see §5)*
- See §7 for processing pipeline.

**Tombstone** *(flat, no relationships — for delete-before-sync handling)*
- `id: UUID = UUID()`
- `entityKind: String` — `"place" | "visit" | "drink" | "tag" | "visitPhoto"`
- `entityID: UUID` — local id of the deleted entity
- `remoteID: String? = nil` — set if the entity was already synced when deleted
- `deletedAt: Date = .now`
- `authorIdentifier: String? = nil`
- `syncState: SyncState = .pendingUpload`
- v2 will: send DELETE for each `remoteID != nil`, drop the rest, then delete the tombstone row.

### Enums

- `PlaceKind`: `coffeeShop | truckStop | gasStation | fastFood | other`. Each carries `displayName`, `sfSymbol`, `accentColor`.
- `PlaceSource`: `mapKit | custom`.
- `DrinkCategory`: `drip | latte | cappuccino | coldBrew | espresso | tea | other`. Each carries `displayName`, `sfSymbol`.
- `SyncState`: `pendingUpload | synced | failed` (see §5). v1 entities default to `.pendingUpload` so that v2's first sync naturally enumerates everything.

### Validation rules (in repositories)

- `VisitRepository.save`: visit must have ≥1 drink → throws `VisitValidationError.missingDrinks`.
- Drink rating clamped to `[0.0, 5.0]` and rounded to nearest 0.1 before insert.
- `TagRepository.findOrCreate(name:)`: trim + lowercase; case-insensitive lookup; never duplicate.
- Place dedup at insertion (`PlaceRepository.findOrCreate`):
  - **MapKit result with non-nil `mapKitIdentifier`** → match existing Place with same id; reuse.
  - **MapKit result with nil identifier** → match if existing Place has same case-insensitive `name` AND great-circle distance < 50m on lat/lng; otherwise insert new.
  - **Custom place** → never auto-merge.

## 4. Architecture

**Pattern: MVVM + Repositories + Environment-based DI.**

- **Composition root** in `Road_BeansApp` builds the SwiftData container, instantiates concrete repositories/services, and injects them through SwiftUI `Environment` keyed by protocol.
- **No third-party DI container.** Previews and tests inject in-memory or fake implementations through the same Environment keys.

### Layers

- **Models** — SwiftData `@Model` entities (§3). Live only inside repositories.
- **Read structs** — plain Swift `struct` types like `PlaceSummary`, `PlaceDetail`, `VisitRow`, `VisitDetail`, `DrinkRow`, `TagSuggestion`. Repositories return these to view-models. **View-models and views never see `@Model` instances.**
- **Command structs** — plain Swift `struct` types like `CreateVisitCommand(placeRef: PlaceReference, date: Date, drinks: [DrinkDraft], tags: [String], photos: [PhotoDraft])`, `UpdateVisitCommand`, `DeleteVisitCommand`. Mutations flow view-model → repository as commands.
- **DTOs** — `Codable` structs (see §10) used for the v1 debug "Export JSON" action and as the contract the v2 upload will speak.
- **Repositories (protocols)** — `PlaceRepository`, `VisitRepository`, `TagRepository`, `PhotoRepository`, `TombstoneRepository`. Local implementations wrap `ModelContext`. View-models depend only on protocols. Repositories own all `@Model` ↔ read-struct ↔ DTO mapping.
- **Services (protocols)** — `LocationSearchService`, `LocationPermissionService`, `PhotoProcessingService`, `iCloudAvailabilityService`, `RemoteSyncCoordinator`.
- **View-models** — `@Observable` classes, one per screen. Hold read structs and draft state. Call repositories and services.
- **Views** — SwiftUI, dumb. Read view-model and repositories from `@Environment`. **No `@Query` of `@Model` types in feature views**; lists are driven by view-model state populated from repository fetches. (A small exception: a single `LiveQueryHost` shim may use `@Query` to subscribe to a model context and convert results into read structs before exposing them to a view-model — this keeps SwiftData's auto-update ergonomics without leaking `@Model` types up the stack.)

### File layout

```
Road Beans/                          (app target)
├── App/
│   ├── Road_BeansApp.swift          (composition root)
│   ├── AppEnvironment.swift         (EnvironmentKey definitions)
│   └── Persistence/
│       ├── PersistenceMode.swift
│       └── PersistenceController.swift
├── Models/                          (SwiftData @Model classes + enums)
├── ReadModels/                      (plain structs returned by repositories)
├── Commands/                        (plain structs accepted by repositories)
├── DTOs/                            (Codable upload-envelope types)
├── Repositories/
│   ├── Protocols/
│   └── Local/                       (SwiftData implementations)
├── Services/
│   ├── LocationSearchService.swift
│   ├── LocationPermissionService.swift
│   ├── PhotoProcessingService.swift
│   ├── iCloudAvailabilityService.swift
│   └── RemoteSyncCoordinator.swift  (LocalOnlyRemoteSync in v1)
├── Features/
│   ├── PlaceList/
│   ├── PlaceDetail/
│   ├── VisitDetail/
│   ├── AddVisit/                    (3-page combined sheet)
│   └── Map/
└── DesignSystem/
    ├── BeanSlider/                  (the hero rating component)
    ├── GlassCard.swift
    ├── PlaceKindStyle.swift
    └── Colors+Typography.swift

Road BeansTests/                     (separate test target)
├── RepositoryTests/
├── ViewModelTests/
├── ServiceTests/
├── DTOTests/
└── DesignSystemTests/
```

## 5. Sync Metadata & v2 Readiness

### v2 hooks built into v1 (the "upload all" requirement)

Every model carries these extra attributes from day one:

- `id: UUID` — already stable & portable.
- `remoteID: String? = nil` — server-assigned ID after upload.
- `syncState: SyncState = .pendingUpload` — every newly created v1 entity is born `.pendingUpload`. (No `.local` state — v1 simply has no live coordinator to drain the queue.)
- `authorIdentifier: String? = nil` — back-filled at v2 onboarding when the user claims their account.
- `lastModifiedAt: Date = .now` — see propagation rules below.

### Sync contract

`RemoteSyncCoordinator` ships in v1 as `LocalOnlyRemoteSync` with a no-op `markDirty(_:)`. Repositories already call it on every save/delete, so v2 only swaps the implementation.

**Dirty propagation rules** (applied by repositories, not view-models):
- Saving a Visit marks: the Visit, every Drink in the Visit, every newly-created Tag, every newly-created VisitPhoto, and the Place if it was created in the same transaction. Existing Tags re-used by the Visit are NOT re-dirtied; they're already `.pendingUpload` or `.synced`.
- Editing a Drink marks: the Drink and the parent Visit (because parent's `lastModifiedAt` advances).
- Adding/removing a Tag from a Visit/Drink marks: the parent Visit/Drink. The Tag itself is not re-marked unless its `name` changed.
- `lastModifiedAt` updates on: any persisted-property change, any direct relationship mutation (add/remove drink/tag/photo). It does NOT update purely from a related entity's edit (e.g., editing a Tag's name does not bump every Visit that uses it).
- **Deletes** create a `Tombstone` row (see §3) and delete the entity. v2 enumerates tombstones alongside `syncState != .synced` entities.

### Defaults summary

| When | Entity is set to |
|------|------------------|
| Newly created in v1 | `syncState = .pendingUpload`, `remoteID = nil`, `authorIdentifier = nil` |
| Edited in v1 | `lastModifiedAt = .now` (no change to `syncState` — it remains pending or, in v2+, gets bumped back to pending) |
| Deleted in v1 | `Tombstone` row inserted; entity removed |
| Successfully uploaded by v2 | `syncState = .synced`, `remoteID = "<server id>"` |

### Place merge strategy for v2

- `mapKitIdentifier` is the canonical join key — places with the same MapKit POI ID merge across users automatically.
- MapKit places without an identifier → server uses the same `(name, lat, lng, 50m)` rule v1 uses locally for dedup.
- Custom places (`source == .custom`) prompt the user to resolve duplicates at upload time.
- v1 must populate every available source field (mapKitIdentifier, mapKitName, address components, lat/lng, phone, URL) for any MapKit-sourced Place — these are the merge inputs for v2.

## 6. Persistence Modes

The app runs in one of these modes, decided at launch and re-checked on `NSUbiquityIdentityDidChange`:

- `.localOnly` — no iCloud account; SwiftData writes to local store at `LocalStore.sqlite`.
- `.cloudKitBacked` — iCloud account present; SwiftData writes to a CloudKit-private-DB-backed store at `CloudKitStore.sqlite`.
- `.pendingMigration` — a `LocalStore.sqlite` exists from a previous `.localOnly` session AND iCloud is now available. App shows a one-time prompt: *"Bring your existing road trip data into iCloud? Yes / Keep local only."*
- `.pendingRelaunch` — the iCloud identity changed mid-session. App shows an overlay: *"Your iCloud account changed. Relaunch Road Beans to continue."* No further reads/writes happen until relaunch.

### Mode transitions

- **First launch with iCloud available** → `.cloudKitBacked`.
- **First launch without iCloud** → `.localOnly`.
- **Later launch, iCloud now available, local data exists** → `.pendingMigration`.
  - User taps *Yes* → `PersistenceController.migrateLocalToCloudKit()` copies all entities from `LocalStore.sqlite` into the CloudKit-backed store within a single transaction; on success, deletes the local store, transitions to `.cloudKitBacked`. On failure, surfaces an error and remains in `.pendingMigration` so the user can retry.
  - User taps *Keep local only* → app stores a `migrationDeferred = true` flag and stays in `.localOnly`. The prompt is not re-shown until the user explicitly chooses *Settings → Move data to iCloud*.
- **Identity change mid-session** → `.pendingRelaunch` immediately. No automatic container rebuild. (Container rebuild during a live session has too many in-flight `ModelContext`/`@Observable` lifetimes to manage safely; relaunch is the conservative, correct choice.)
- **Sign-out detected at launch (was `.cloudKitBacked`, now no iCloud)** → continue in `.cloudKitBacked` against the local cache that SwiftData maintains. Writes accumulate locally and re-sync when iCloud returns.

`PersistenceController` is a single `@Observable` object that owns the `ModelContainer`, exposes the current `PersistenceMode`, and is injected via `@Environment`. View-models that need to react to mode changes observe it.

## 7. Photos

### Pipeline (in `PhotoProcessingService`)

When the user picks photos via `PhotosPicker`:

1. Load each pick as `Data`.
2. Decode → resize so the long edge is ≤ 2048px (preserving aspect).
3. Re-encode as HEIC (fallback to JPEG quality 0.85 on platforms without HEIC encode).
4. Generate a 256px-long-edge JPEG (quality 0.7) thumbnail.
5. Store both blobs and pixel dimensions on `VisitPhoto`.
6. **Discard the original picker data.** v1 does not retain originals.

### Constraints

- Max 8 photos per visit (UI enforces; repository validates).
- Both `imageData` and `thumbnailData` use `@Attribute(.externalStorage)`, which CloudKit handles via `CKAsset`-style external blobs.
- All processing is off the main actor (`Task.detached`).

### UI

- List/grid views render `thumbnailData` only.
- Visit Detail's photo pager renders `imageData`.
- Tap a photo → full-screen presentation with pinch-to-zoom (read-only in v1).

## 8. Location & Map Permissions

### Permission timing

- **Never requested at launch.**
- Requested only when the user opens the **Map** tab or toggles **"Stops near me"** in the List tab. Both call `LocationPermissionService.requestWhenInUse()`.

### Permission states & UI

| State | Behavior |
|-------|----------|
| `.notDetermined` | Show inline rationale ("Road Beans uses your location to show stops near you") with an "Allow" button that triggers the system prompt. |
| `.denied` / `.restricted` | Show empty state: "Location is off. Open Settings to enable nearby stops." Button deep-links to `UIApplication.openSettingsURLString`. Map tab remains usable; just no user-location pin and no "near me." |
| `.authorizedWhenInUse` / `.authorizedAlways` | Full functionality. |

### Search & offline behavior

- MapKit local search runs on every keystroke (debounced 250ms).
- **Search failure (offline / network error)** → search results area shows: *"Can't search right now. Try again or add a custom place."* with a *+ Custom place* button.
- **Empty results** → *"No matches. Add it as a custom place?"* with a *+ Custom place* button.
- The "+ Custom place" path always works regardless of network or location permission.

## 9. The Bean Slider (hero component)

Custom `View`, **not** a wrapped `Slider`.

### Visual / behavior

- Horizontal track with 51 tick stops (0.0 → 5.0 by 0.1).
- Above the thumb, a 16-bit pixel-art glyph rendered from a SwiftUI `Canvas` — a coffee-cup outline that contains 0–5 beans.
- **Whole-number thresholds** (1.0, 2.0, 3.0, 4.0, 5.0) trigger:
  - Bean pop-in via `withAnimation(.spring(response: 0.25, dampingFraction: 0.55))` scaling 0 → 1.
  - `UIImpactFeedbackGenerator(style: .medium)` haptic.
- **Sub-whole drags** trigger a softer `UISelectionFeedbackGenerator` tick at every 0.1.
- Thumb is a glass capsule showing the current numeric value ("3.6").
- Track gradient shifts hue subtly as value rises (cool → warm coffee tones).
- Accepts `@Binding<Double>` plus `range`/`step`. Reusable in Add and any future edit screens.
- Pixel rendering uses no anti-aliasing so the bean reads as crisp 16-bit against the surrounding glassy material.
- A `BeanRating` static variant (no interaction) renders the same bean glyph at a given value, used by Place Detail's average display.

### Accessibility contract (required, part of the component itself)

- `.accessibilityLabel("Drink rating")`.
- `.accessibilityValue("\(value, specifier: \"%.1f\") of 5")`.
- `.accessibilityAdjustableAction { direction in increment/decrement by 0.1 }`.
- Minimum hit target 44pt for the thumb area; track itself accepts taps to jump value.
- Numeric label uses `.title2` and respects Dynamic Type up to AX5; bean glyph scales proportionally.
- Honors `@Environment(\.accessibilityReduceMotion)` — replaces spring pop-in with a 120ms crossfade.
- Honors `@Environment(\.accessibilityReduceTransparency)` — thumb capsule swaps glass material for a solid background tinted by the current Place kind.
- Honors the system "Allow Haptics" preference (haptics call sites guarded by `UIDevice.current.value(forKey: "_feedbackSupportLevel")`-style check; if unsure, gated behind `@AppStorage("hapticsEnabled")` defaulting to true so user can disable in Settings).
- Color contrast: thumb numeric label uses `Color.primary` over a glass material; passes WCAG AA when `accessibilityReduceTransparency` swaps to solid background.

## 10. DTO Contract

DTOs are flat `Codable` structs that reference each other by stable `UUID`. **No nested entity graphs.** This makes round-trip tests deterministic and prevents accidental cycles (Place → Visit → Drink → Tag → Visit).

```swift
struct UploadEnvelope: Codable {
    let schemaVersion: Int                // bump on breaking DTO changes
    let exportedAt: Date
    let authorIdentifier: String?         // nil in v1; populated at v2 onboarding
    let places: [PlaceDTO]
    let visits: [VisitDTO]
    let drinks: [DrinkDTO]
    let tags: [TagDTO]
    let visitPhotos: [VisitPhotoDTO]
    let visitTagAssignments: [TagAssignmentDTO]
    let drinkTagAssignments: [TagAssignmentDTO]
    let tombstones: [TombstoneDTO]
}

struct PlaceDTO: Codable {
    let id: UUID
    let remoteID: String?
    let lastModifiedAt: Date
    let name: String
    let kind: String                      // raw value of PlaceKind
    let source: String                    // raw value of PlaceSource
    let mapKitIdentifier: String?
    let mapKitName: String?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let phoneNumber: String?
    let websiteURL: URL?
    let streetNumber: String?
    let streetName: String?
    let city: String?
    let region: String?
    let postalCode: String?
    let country: String?
    let createdAt: Date
}

struct VisitDTO: Codable {
    let id: UUID
    let remoteID: String?
    let placeID: UUID                     // FK
    let date: Date
    let lastModifiedAt: Date
    let createdAt: Date
}

struct DrinkDTO: Codable {
    let id: UUID
    let remoteID: String?
    let visitID: UUID                     // FK
    let name: String
    let category: String
    let rating: Double
    let lastModifiedAt: Date
    let createdAt: Date
}

struct TagDTO: Codable {
    let id: UUID
    let remoteID: String?
    let name: String                      // normalized
    let lastModifiedAt: Date
    let createdAt: Date
    // usageCount intentionally omitted — derived
}

struct VisitPhotoDTO: Codable {
    let id: UUID
    let remoteID: String?
    let visitID: UUID                     // FK
    let caption: String?
    let widthPx: Int
    let heightPx: Int
    let assetReference: String            // path or external blob token; image data uploaded separately
    let lastModifiedAt: Date
    let createdAt: Date
}

struct TagAssignmentDTO: Codable {
    let tagID: UUID
    let entityID: UUID                    // visit or drink id
    // entity kind is implicit by which array it lives in (visitTagAssignments vs drinkTagAssignments)
}

struct TombstoneDTO: Codable {
    let id: UUID
    let entityKind: String
    let entityID: UUID
    let remoteID: String?
    let deletedAt: Date
}
```

DTO round-trip tests assert: `Model -> DTO -> JSON -> DTO -> Model` reproduces field-equivalent objects across the full graph.

## 11. Navigation & Screens

### Tab bar (Liquid Glass)

Three tabs, native `TabView` styled with the iOS 26 glass material:

1. **List (default)** — Section toggle: *By Place* (grouped, latest visit's avg rating shown next to Place name) or *Recent Visits* (flat reverse-chrono). Search field at top searches Place names, drink names, tags. Filter chips: kind, tag, rating range.
2. **Map** — `MapKit` `Map` view with custom annotations. Annotation glyph = Place kind's SF Symbol; tint = kind accent color. Tap → glass card sheet with Place summary + "View visits" button. "Stops near me" toggle (governed by §8).
3. **+** — opens the Add sheet (full-screen cover).

### Add sheet (combined flow, single sheet, paged)

- **Page 1 — Place.** MapKit local-search field (debounced). Results list with map preview. "+ Custom place" button at bottom → manual name + kind + optional address. Picking a known Place skips this page.
- **Page 2 — Visit.** Date (defaults to now), photos (`PhotosPicker`, multi-select, max 8), visit-level tags (token field with autocomplete from `TagRepository.suggestions(prefix:)`).
- **Page 3 — Drinks.** A list you can append to (≥1 required to enable Save). Each drink row: category segmented control, name field, tag tokens, and the **Bean Slider** (§9).
- **Save** → validates → posts a `CreateVisitCommand` to `VisitRepository.save(...)` → dismisses → transient toast overlay "Added to *Loves – Cordes Junction*."

### Place Detail screen

Header with kind icon, name, kind chip, address, "Open in Maps" button. Below: average rating displayed as a large numeric value alongside a static `BeanRating` (the non-interactive Bean Slider variant) positioned at that average. Then a chronological list of Visits; each row expands to show drinks with their bean-rated ratings.

### Visit Detail screen

Date, photos (horizontal pager rendering full-resolution `imageData`), tag chips, drinks list (each with category icon + name + bean rating). Edit/Delete in toolbar. Delete writes a `Tombstone` (§3).

## 12. Liquid Glass Visual System

- Tab bar, navigation bars, and floating cards use the iOS 26 `Material` with `.glassEffect()`-style tint per Place-kind context.
- Place-kind accent colors:
  - **Coffee Shop** — espresso brown
  - **Truck Stop** — highway amber
  - **Gas Station** — fuel teal
  - **Fast Food** — burger red
  - **Other** — neutral slate
- Type: SF Pro Rounded for headlines (playful), SF Pro for body.
- Motion: spring-based, never linear; the rating bean uses a retro pixel transform (no AA) to feel 16-bit against the glassy surroundings.
- **Dark mode is first-class** — the modern/fun aesthetic pops harder against dark glass.
- All `.glassEffect()`-style modifiers are wrapped in a `GlassCard` / `glassBackground()` design-system helper. If a specific iOS 26 modifier turns out to be unavailable on the bundled SDK during implementation, the helper centralizes the fallback to `.thinMaterial` / `.regularMaterial` with custom tinting — feature views don't change.

## 13. Testing

Swift Testing framework (`@Test`).

- **Repository tests** — in-memory `ModelContainer`. Cover place dedup (mapKitIdentifier path + nil-id name+50m path + custom never-merge), tag normalize/lookup-or-create, visit-must-have-drinks validation, rating clamp/round-to-0.1, cascade deletes, tombstone insertion, dirty propagation rules.
- **View-model tests** — fake repositories conforming to the protocols. Cover add-flow state machine (cannot save with 0 drinks; validation surfaces correctly), tag autocomplete sorting by derived usage count, search/filter behavior on List view-model.
- **Service tests** — `PhotoProcessingService` (resize/encode/thumbnail produce expected dimensions and formats), `LocationPermissionService` state mapping.
- **DTO round-trip tests** — the full `UploadEnvelope` round-trips through JSON without loss; FKs resolve; tombstones survive.
- **Persistence-mode tests** — `PersistenceController` transitions: localOnly → pendingMigration → cloudKitBacked; identity change → pendingRelaunch; deferred migration is honored.
- **Bean Slider tests** — value-to-beans mapping (0.0 → 0 beans, 0.99 → 0, 1.0 → 1, 4.99 → 4, 5.0 → 5); accessibilityValue formatting; adjustableAction increment/decrement clamps at bounds.
- **No UI tests in v1.** Manual checklist for the visual layer.

## 14. Implementation Prerequisites

The current repo is the default Xcode SwiftUI/SwiftData template. Step 0 of the implementation plan must:

- Remove the template `Item` model and any references.
- Replace `ContentView` with the real root view (a `TabView`).
- Strip the template `ModelContainer` setup from `Road_BeansApp` and replace with `PersistenceController` from §6.
- Add a `Road BeansTests` Xcode test target (Swift Testing). Create the `RepositoryTests`, `ViewModelTests`, `ServiceTests`, `DTOTests`, `DesignSystemTests` subfolders.
- Create the `App/`, `Models/`, `ReadModels/`, `Commands/`, `DTOs/`, `Repositories/`, `Services/`, `Features/`, `DesignSystem/` folders per §4 layout.
- Verify the bundled Xcode SDK exposes the `glassEffect`-style APIs the design assumes; if any are missing, populate `GlassCard` / `glassBackground()` fallback before any feature view consumes them.

## 15. Risks & Open Questions

- **CloudKit + SwiftData edge cases.** Optional-relationships modeling avoids the schema-rejection failure mode, but actual CloudKit sync behavior under real-world identity changes, network flakes, and large photo blobs has surprises. Mitigation: persistence-mode tests + manual sign-out/sign-in QA before each TestFlight build.
- **MapKit POI identifier coverage.** Not all results carry one; the `(name, lat, lng, 50m)` fallback is best-effort. Document when a user-visible "looks like a duplicate?" UI may be needed in v2.
- **v2 backend technology** (REST vs GraphQL vs Firebase vs custom) is undecided. The DTO envelope insulates v1 from this choice.
- **HEIC encode availability.** All shipping iOS 26.4 devices support HEIC encode; the JPEG fallback in `PhotoProcessingService` is defensive.

## 16. v2 Roadmap (deferred but unlocked)

- Backend API accepting `UploadEnvelope` payloads.
- `BackendRemoteSync` implementation of `RemoteSyncCoordinator`.
- First-launch v2 onboarding: Sign in with Apple → claims an account → back-fills `authorIdentifier` on all local entities + tombstones → enqueues full upload of every entity with `syncState != .synced` and every tombstone.
- Custom-place duplicate resolution flow before upload.
- Stats tab driven by the now-aggregate dataset.
- Trip/route grouping over existing visit dates.
