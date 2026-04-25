# Road Beans — Design Spec

**Date:** 2026-04-25
**Author:** Christopher Bobrowitz (with Claude)
**Repo:** https://github.com/aztechead/road_beans
**Target:** iOS 26.4+, SwiftUI, SwiftData, CloudKit, MapKit
**Status:** Approved scope; pending plan

---

## 1. Purpose

Road Beans is a native iOS app for tracking coffee/drink stops along road-trip routes. It replaces an ad-hoc Notes-app workflow with a structured, fast, visually distinctive app. v1 is single-user and on-device (with CloudKit private-DB sync across the user's own devices). v2 will introduce a central remote database where multiple users' reviews are aggregated; v1 is engineered so that all existing reviews can be uploaded to that backend in one operation when v2 ships.

## 2. Scope

### v1 (this build)
- Single-user. Identity is implicit: the device's iCloud account.
- Track **Places** visited, each with one or more **Visits**, each with one or more **Drinks** rated 0.0–5.0 in 0.1 steps.
- **Place kinds** (fixed picker, drives icon + accent color): Coffee Shop, Truck Stop, Gas Station, Fast Food, Other.
- **Hybrid Place identification**: MapKit local search by default; "+ Custom place" fallback for unknown shops or offline use.
- **Visit-level photos** (one or more, optional).
- **Tags** on visits and drinks, with autocomplete from previously used tags. Tags are shared across both surfaces ("burnt" is one tag whether on a visit or a drink).
- **Three Liquid Glass tabs**: List, Map, + (combined add sheet).
- **Storage**: SwiftData with CloudKit private-DB when iCloud is available; local-only fallback when not. Single code path.

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

Five SwiftData `@Model` entities. CloudKit-compatible: every relationship optional with default, no unique constraints, photos via `@Attribute(.externalStorage)`.

```
Place ──< Visit ──< Drink
              │       │
              │       ├──> Tag (M:N, shared)
              ├──> Tag (M:N, shared)
              └──< VisitPhoto
```

### Entities

**Place**
- `id: UUID`
- `name: String`
- `kind: PlaceKind`
- `address: String?`
- `latitude: Double?`
- `longitude: Double?`
- `mapKitIdentifier: String?` — POI identifier from `MKMapItem` when available
- `isCustom: Bool` — true if user added without MapKit
- `createdAt: Date`
- `visits: [Visit]` — cascade delete
- *(plus sync metadata, see §5)*

**Visit**
- `id: UUID`
- `date: Date`
- `place: Place`
- `drinks: [Drink]` — cascade delete; **must have ≥1 drink** (validated in repository)
- `tags: [Tag]`
- `photos: [VisitPhoto]` — cascade delete
- `createdAt: Date`
- *(plus sync metadata, see §5)*

**Drink**
- `id: UUID`
- `name: String`
- `category: DrinkCategory`
- `rating: Double` — clamped to `[0.0, 5.0]`, rounded to nearest 0.1
- `visit: Visit`
- `tags: [Tag]`
- `createdAt: Date`
- *(plus sync metadata, see §5)*

**Tag**
- `id: UUID`
- `name: String` — normalized (trimmed + lowercased) for de-dup; lookup-or-create on insert
- `usageCount: Int` — autocomplete suggestions sort by frequency
- `visits: [Visit]` (back-relation)
- `drinks: [Drink]` (back-relation)
- `createdAt: Date`
- *(plus sync metadata, see §5)*

**VisitPhoto**
- `id: UUID`
- `imageData: Data` — `@Attribute(.externalStorage)`
- `caption: String?`
- `visit: Visit`
- `createdAt: Date`
- *(plus sync metadata, see §5)*

### Enums

`PlaceKind`: `coffeeShop | truckStop | gasStation | fastFood | other`. Each carries `displayName`, `sfSymbol`, `accentColor`.

`DrinkCategory`: `drip | latte | cappuccino | coldBrew | espresso | tea | other`. Each carries `displayName`, `sfSymbol`.

`SyncState`: `local | pendingUpload | synced | failed` (see §5).

### Validation rules (enforced in `VisitRepository.save`)
- Visit must have ≥1 drink → throws `VisitValidationError.missingDrinks`.
- Drink rating clamped to `[0.0, 5.0]` and rounded to nearest 0.1.
- Tag name normalized; duplicates impossible (lookup-or-create).
- Place de-dup: same `mapKitIdentifier` reuses existing Place; custom places never auto-merge.

## 4. Architecture

**Pattern: MVVM + Repositories + Environment-based DI.**

- **Composition root** in `Road_BeansApp` builds the SwiftData container, instantiates concrete repositories/services, and injects them through SwiftUI `Environment` keyed by protocol.
- **No third-party DI container.** Previews and tests inject in-memory or fake implementations through the same Environment keys.

### Layers

- **Models** — SwiftData `@Model` entities (§3).
- **DTOs** — `Codable` structs (`PlaceDTO`, `VisitDTO`, `DrinkDTO`, `TagDTO`, `VisitPhotoDTO`) separate from models. Built in v1; used immediately for a hidden debug "Export JSON" action and as the contract the v2 upload will speak.
- **Repositories (protocols)** — `PlaceRepository`, `VisitRepository`, `TagRepository`. Local implementations wrap `ModelContext`. View-models depend only on protocols.
- **Services (protocols)** — `LocationSearchService` (MapKit wrapper), `PhotoStorageService`, `iCloudAvailabilityService`, `RemoteSyncCoordinator`.
- **View-models** — `@Observable` classes, one per screen. No SwiftData imports inside view-models — only repository calls.
- **Views** — SwiftUI, dumb. Read view-model and repositories from `@Environment`.

### File layout

```
Road Beans/
├── App/
│   ├── Road_BeansApp.swift        (composition root)
│   └── AppEnvironment.swift       (EnvironmentKey definitions)
├── Models/                         (SwiftData @Model classes + enums)
├── DTOs/                           (Codable transfer types)
├── Repositories/
│   ├── Protocols/
│   └── Local/                      (SwiftData implementations)
├── Services/
│   ├── LocationSearchService.swift
│   ├── PhotoStorageService.swift
│   ├── iCloudAvailabilityService.swift
│   └── RemoteSyncCoordinator.swift (LocalOnlyRemoteSync in v1)
├── Features/
│   ├── PlaceList/
│   ├── PlaceDetail/
│   ├── VisitDetail/
│   ├── AddVisit/                   (3-page combined sheet)
│   └── Map/
├── DesignSystem/
│   ├── BeanSlider/                 (the hero rating component)
│   ├── GlassCard.swift
│   ├── PlaceKindStyle.swift
│   └── Colors+Typography.swift

Road BeansTests/                    (separate Xcode test target)
├── RepositoryTests/
├── ViewModelTests/
└── DTOTests/
```

## 5. Storage, Sync, and v2 Readiness

### v1 on-device sync

SwiftData with `ModelConfiguration(cloudKitDatabase: .private(...))` when iCloud is available; local-only fallback when not. `iCloudAvailabilityService` checks `FileManager.default.ubiquityIdentityToken` at launch and rebuilds the container on identity change.

### v2 hooks built into v1 (the "upload all" requirement)

Every model carries five extra attributes from day one:

- `id: UUID` — already stable & portable.
- `remoteId: String?` — server-assigned ID after upload; nil in v1.
- `syncState: SyncState` — `.local | .pendingUpload | .synced | .failed`; defaults to `.local`.
- `authorIdentifier: String?` — back-filled at v2 onboarding when the user claims their account.
- `lastModifiedAt: Date` — for delta sync later.

`RemoteSyncCoordinator` ships in v1 as a no-op `LocalOnlyRemoteSync` that logs and returns. View-models already call it on save (`coordinator.markDirty(visit)`), so v2 only swaps the implementation. The eventual `BackendRemoteSync`:

1. Enumerates all entities with `syncState != .synced`.
2. Transforms via DTOs.
3. POSTs in batches.
4. Sets `remoteId` + `syncState = .synced` on success.

**Place merge strategy** for v2 is pre-decided:
- `mapKitIdentifier` is the canonical join key — places with the same MapKit POI ID merge across users automatically.
- Custom places (`isCustom == true`) prompt the user to resolve duplicates at upload time.

This means **v1 must populate `mapKitIdentifier` whenever the user picks a MapKit result** — it is the single most important piece of data for clean v2 aggregation.

## 6. Navigation & Screens

### Tab bar (Liquid Glass)

Three tabs, native `TabView` styled with the iOS 26 glass material:

1. **List (default)** — Section toggle: *By Place* (grouped, latest visit's avg rating shown next to Place name) or *Recent Visits* (flat reverse-chrono). Search field at top searches Place names, drink names, tags. Filter chips: kind, tag, rating range.
2. **Map** — `MapKit` `Map` view with custom annotations. Annotation glyph = Place kind's SF Symbol; tint = kind accent color. Tap → glass card sheet with Place summary + "View visits" button. "Stops near me" toggle.
3. **+** — opens the Add sheet (full-screen cover).

### Add sheet (combined flow, single sheet, paged)

- **Page 1 — Place.** MapKit local-search field (debounced). Results list with map preview. "+ Custom place" button at bottom → manual name + kind + optional address. Picking a known Place skips this page.
- **Page 2 — Visit.** Date (defaults to now), photos (`PhotosPicker`, multi-select), visit-level tags (token field with autocomplete from `TagRepository.suggestions(prefix:)`).
- **Page 3 — Drinks.** A list you can append to (≥1 required to enable Save). Each drink row: category segmented control, name field, tag tokens, and the **Bean Slider** (§7).
- **Save** → validates → writes via `VisitRepository.save(...)` → dismisses → transient toast overlay "Added to *Loves – Cordes Junction*."

### Place Detail screen

Header with kind icon, name, kind chip, address, "Open in Maps" button. Below: average rating displayed as a large numeric value alongside a static (non-interactive) Bean Slider rendering positioned at that average. Then a chronological list of Visits; each row expands to show drinks with their bean-rated ratings.

### Visit Detail screen

Date, photos (horizontal pager), tag chips, drinks list (each with category icon + name + bean rating). Edit/Delete in toolbar.

## 7. The Bean Slider (hero component)

Custom `View`, **not** a wrapped `Slider`.

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

## 8. Liquid Glass Visual System

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

## 9. Testing

Swift Testing framework (`@Test`).

- **Repository tests** — in-memory `ModelContainer`. Cover place dedup by `mapKitIdentifier`, tag normalize/lookup-or-create, visit-must-have-drinks validation, rating clamp/round-to-0.1, cascade deletes.
- **View-model tests** — fake repositories conforming to the protocols. Cover add-flow state machine (cannot save with 0 drinks; validation surfaces correctly), tag autocomplete sorting by `usageCount`, search/filter behavior on List view-model.
- **DTO round-trip tests** — model → DTO → JSON → DTO → model produces equivalent objects. Critical for v2 upload integrity.
- **Bean Slider tests** — value-to-beans mapping (0.0 → 0 beans, 0.99 → 0, 1.0 → 1, 4.99 → 4, 5.0 → 5). Haptic/animation behavior excluded from automated tests.
- **No UI tests in v1.** Manual checklist for the visual layer.

## 10. Risks & Open Questions

- **Liquid Glass APIs** — the project targets iOS 26.4 and the design assumes the iOS 26 `glassEffect`-style materials are available. If any specific modifier used during implementation turns out to be unavailable on the bundled SDK, fall back to `.thinMaterial` / `.regularMaterial` with custom tinting.
- **MapKit POI identifiers** are not always populated for every result; the design accepts `nil` and falls back to lat/long-based proximity matching for v2 dedup of MapKit-sourced places without IDs.
- **CloudKit + SwiftData constraints** require all relationships optional with defaults — every model must be written with this in mind from the first commit.
- **v2 backend technology** (REST vs GraphQL vs Firebase vs custom) is undecided. The DTO layer insulates v1 from this choice.

## 11. v2 Roadmap (deferred but unlocked)

- Backend API accepting `*DTO` payloads.
- `BackendRemoteSync` implementation of `RemoteSyncCoordinator`.
- First-launch v2 onboarding: Sign in with Apple → claims an account → back-fills `authorIdentifier` on all local entities → enqueues full upload of every entity with `syncState != .synced`.
- Custom-place duplicate resolution flow before upload.
- Stats tab driven by the now-aggregate dataset.
- Trip/route grouping over existing visit dates.
