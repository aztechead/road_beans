# Review: Road Beans Design Spec

**Reviewed:** 2026-04-25  
**Source:** `docs/superpowers/specs/2026-04-25-road-beans-design.md`

## Summary

The spec is strong as a product and implementation direction document. The main risks are not scope clarity; they are SwiftData/CloudKit modeling details, iCloud fallback behavior, v2 sync state semantics, and a few UI/accessibility details that need to be pinned down before implementation to avoid rework.

The current project baseline is still the default SwiftUI/SwiftData template, and the Xcode project already targets iOS 26.4, so there is no meaningful implementation conflict yet.

## Findings

### High: CloudKit-compatible relationships conflict with the entity definitions

The spec correctly states that CloudKit-compatible SwiftData relationships should be optional with defaults, but the entity list later describes required relationships such as `Visit.place`, `Drink.visit`, and `VisitPhoto.visit`, plus non-optional arrays such as `Place.visits`, `Visit.drinks`, `Visit.tags`, and `Tag.visits`.

References: source lines 41, 63, 69-72, 81-82, 90-99, 264.

This should be resolved in the spec before model implementation. A practical implementation can still expose non-optional domain accessors, but the persisted `@Model` storage should be explicitly documented as CloudKit-safe, for example optional relationship properties with empty-array defaults where supported and repository-level validation for required domain invariants.

### High: CloudKit fallback/rebuild behavior can create migration and data-split risk

The spec says the app should use CloudKit private DB when iCloud is available and local-only fallback when not, then rebuild the container on identity changes.

Reference: source lines 25 and 172.

That decision needs a precise data behavior. If a user starts local-only, adds visits, then later signs into iCloud, the implementation must define whether local data is migrated into the CloudKit-backed store, kept separate, or requires a one-time merge. Rebuilding a SwiftData container at runtime also affects view/model-context lifetimes and can invalidate repositories and view-model state.

Recommended spec change: define a `PersistenceMode` state machine and explicit local-to-iCloud migration behavior before coding repositories.

### High: v2 sync state semantics are internally ambiguous

The spec says every model defaults to `syncState = .local`, view-models call `coordinator.markDirty(visit)` on save, and v2 uploads entities where `syncState != .synced`.

References: source lines 176-189.

This leaves several questions that affect v1 data correctness:

- Should newly created v1 entities remain `.local`, or become `.pendingUpload` after save?
- Does `markDirty(visit)` update only the visit, or also related place, drinks, tags, and photos?
- How are deletes represented for v2 upload if an entity is deleted locally before ever syncing?
- Does `lastModifiedAt` update for relationship changes, tag usage changes, and photo edits?

Recommended spec change: define a small sync contract now, even if the implementation remains no-op in v1. At minimum, specify dirty propagation and whether tombstones are in or out of v1 scope.

### Medium: Place identity strategy needs more than `mapKitIdentifier`

The spec makes `mapKitIdentifier` the canonical v2 join key and says nil falls back to lat/long proximity later.

References: source lines 60, 115, 191-195, 263.

That is reasonable, but v1 should persist enough source metadata to support the fallback. Latitude/longitude alone can produce bad merges for malls, plazas, airports, truck stops, and businesses that move. Consider adding `source: PlaceSource`, `mapKitName`, `phoneNumber`, `url`, `postalAddressComponents`, or a normalized address field if available from `MKMapItem`.

At minimum, the spec should define the local dedup rule for MapKit results with nil identifiers. Currently it only states custom places never auto-merge.

### Medium: Tag `usageCount` can drift from relationships

The spec stores `usageCount` and uses it for autocomplete sorting.

References: source lines 88-89, 114, 210, 255.

Because tags are many-to-many and editable, a stored counter can become stale unless every insert, edit, delete, and relationship mutation updates it transactionally. Either define `usageCount` as derived at query time, or define the repository operations responsible for maintaining it.

If v2 aggregation is expected later, also define whether `usageCount` is local-only metadata or included in DTO upload.

### Medium: DTO round-trip requirement is underspecified for object graphs

The spec requires model-to-DTO-to-JSON-to-DTO-to-model equivalence.

References: source lines 126-128 and 256.

That can accidentally imply full graph reconstruction with cycles: `Place -> Visit -> Drink -> Tag -> Visit`. DTOs should instead use stable IDs and separate payload arrays, or a bounded aggregate root format. The spec should define DTO shape before implementation so tests validate the intended contract instead of a convenient but non-uploadable object graph.

### Medium: Photo storage needs size, compression, and CloudKit budget rules

The spec stores visit photos as external SwiftData `Data`.

References: source lines 22, 72, 95-99, 210.

This is implementable, but it needs constraints. Multi-select full-resolution photos can quickly create large local stores and CloudKit sync pressure. Specify max image dimensions, compression format/quality, thumbnail strategy, and whether original images are retained.

Recommended default: store compressed app-managed JPEG/HEIC plus generated thumbnail data, not raw picker data.

### Medium: Map and search flows need permissions/offline behavior

The spec includes MapKit search, map annotations, and a "Stops near me" toggle.

References: source lines 21, 203-204, 209.

It should define location permission behavior. Local search can work without precise user location, but "near me" cannot. Add acceptance criteria for denied location, approximate location, offline search failure, and empty-result states.

### Medium: Bean Slider accessibility is not specified

The Bean Slider is custom, haptic-heavy, and explicitly not a wrapped `Slider`.

References: source lines 222-235 and 257.

A custom control must define accessibility behavior: label, value, adjustable actions, VoiceOver increment/decrement step, reduced motion behavior, haptic opt-out via system settings, minimum hit target, Dynamic Type handling, and contrast against glass backgrounds.

This should be part of the component contract, not left to visual implementation.

### Low: "No SwiftData imports inside view-models" may be too rigid

The architecture says view-models depend only on repository protocols and import no SwiftData.

Reference: source line 130.

That is a good default. The spec should also state whether models themselves may cross the repository boundary. If view-models receive SwiftData `@Model` objects, they effectively depend on persistence semantics even without importing SwiftData. Prefer separate read models or DTO-like view state for list/detail screens if testability is the goal.

### Low: Current source tree does not match the planned file layout

The planned file layout is clean, but the app currently contains the default `Item`, `ContentView`, and template `Road_BeansApp` model container.

References: source lines 133-165.

This is not a blocker, but the implementation plan should include a first cleanup step: remove template `Item`, replace `ContentView`, add the test target if it does not exist, and move app composition into the planned `App/` folder.

## Recommended Spec Edits Before Implementation

1. Rewrite the entity section with exact SwiftData persistence shapes, including optional relationships/defaults and delete rules.
2. Add a persistence-mode section for local-only, CloudKit-backed, iCloud sign-in, sign-out, and identity-change behavior.
3. Define the v1 sync metadata contract: dirty propagation, defaults, last-modified updates, and delete/tombstone policy.
4. Define DTO graph shape using stable IDs rather than cyclic nested models.
5. Add photo processing constraints: max dimensions, compression, thumbnails, and CloudKit considerations.
6. Add accessibility requirements for Bean Slider and glass UI contrast.
7. Add MapKit/location permission states and offline/error handling.

## Implementation Readiness

The spec is ready to drive a first implementation plan after the high-priority modeling and persistence decisions are tightened. Without those changes, the most likely rework will be in the SwiftData models, repository APIs, and CloudKit migration behavior.
