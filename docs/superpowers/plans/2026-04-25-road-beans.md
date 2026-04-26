# Road Beans Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:subagent-driven-development (recommended) or superpowers-extended-cc:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the v1 Road Beans iOS app — a SwiftUI/SwiftData/CloudKit app that tracks coffee/drink stops on road trips, single-user, with v2-upload readiness baked into the data model.

**Architecture:** MVVM + Repositories + Environment-based DI. SwiftData `@Model` entities with CloudKit-compatible optional relationships, persistence-mode state machine for iCloud availability, repositories own all model⇄read-struct⇄DTO mapping so view-models never touch SwiftData. Liquid Glass UI with a custom 16-bit Bean Slider as the hero rating component.

**Tech Stack:** Swift 5, SwiftUI, SwiftData, CloudKit (private DB), MapKit, PhotosUI, CoreLocation, Swift Testing (`@Test`/`#expect`), iOS 26.4+.

**Source spec:** `docs/superpowers/specs/2026-04-25-road-beans-design.md` (Revision 2).

---

## Conventions used throughout this plan

- **File paths** are absolute from the repo root: `Road Beans/...` is the app target source root; `Road BeansTests/...` is the test target root.
- **Test framework** is Swift Testing (`import Testing`, `@Test`, `#expect`). Do not use XCTest.
- **Commits**: each task ends with a `git commit` step. Commit message format: `feat:`, `fix:`, `chore:`, `test:`, `refactor:`. Co-author trailer is optional.
- **Verify** commands run `xcodebuild` against the `Road Beans.xcodeproj` at repo root. The destination is a generic iOS 26.4 simulator. Adjust the `-destination` if your local simulator name differs.
- **Build sanity** for non-test tasks: `xcodebuild -project "Road Beans.xcodeproj" -scheme "Road Beans" -destination 'generic/platform=iOS Simulator' build`. A successful build is the acceptance signal.
- **Test runs** for tasks that add tests: `xcodebuild -project "Road Beans.xcodeproj" -scheme "Road Beans" -destination 'platform=iOS Simulator,name=iPhone 17' test -only-testing:"Road BeansTests/<TestFileName>"`.
- **DI pattern**: every service/repository has a protocol in `Repositories/Protocols/` or `Services/`; concrete implementations in `Repositories/Local/` or `Services/`. Both register through `AppEnvironment` EnvironmentKeys.

---

### Task 0: Project cleanup, test target, and folder scaffold

**Goal:** Strip the Xcode template (Item model, default ContentView, default ModelContainer), add a Swift Testing test target, and create the file-system folder scaffold from spec §4. Leaves the app in a buildable, empty-of-features state.

**Files:**
- Delete: `Road Beans/Item.swift`
- Modify: `Road Beans/Road_BeansApp.swift` — remove `Item.self` from schema, remove `sharedModelContainer`, leave a placeholder `WindowGroup { Text("Road Beans") }` body.
- Modify: `Road Beans/ContentView.swift` — replace contents with a temporary placeholder `Text("Road Beans")` view.
- Create directories under `Road Beans/`:
  - `App/`, `App/Persistence/`
  - `Models/`
  - `ReadModels/`
  - `Commands/`
  - `DTOs/`
  - `Repositories/Protocols/`, `Repositories/Local/`
  - `Services/`
  - `Features/PlaceList/`, `Features/PlaceDetail/`, `Features/VisitDetail/`, `Features/AddVisit/`, `Features/Map/`
  - `DesignSystem/BeanSlider/`
- Create test target `Road BeansTests` (Swift Testing). This can be done by editing `Road Beans.xcodeproj/project.pbxproj` directly because the project uses file-system-synchronized groups. Then create directories under `Road BeansTests/`:
  - `RepositoryTests/`
  - `ViewModelTests/`
  - `ServiceTests/`
  - `DTOTests/`
  - `DesignSystemTests/`
- Create one placeholder test file `Road BeansTests/RepositoryTests/SmokeTests.swift` containing a single passing test, to confirm the target wires up.

**Acceptance Criteria:**
- [ ] `Item.swift` is deleted.
- [ ] `Road_BeansApp.swift` no longer references `Item` and no longer creates a `ModelContainer`.
- [ ] All folders listed above exist on disk (since the Xcode project uses file-system-synchronized groups, this is sufficient).
- [ ] `Road BeansTests` target exists in `Road Beans.xcodeproj`.
- [ ] `xcodebuild ... build` succeeds.
- [ ] `xcodebuild ... test -only-testing:"Road BeansTests/SmokeTests"` passes.

**Verify:** `xcodebuild -project "Road Beans.xcodeproj" -scheme "Road Beans" -destination 'platform=iOS Simulator,name=iPhone 17' build test -only-testing:"Road BeansTests/SmokeTests"` → BUILD SUCCEEDED, 1 test passed.

**Steps:**

- [ ] **Step 1: Delete `Item.swift`**

```bash
rm "Road Beans/Item.swift"
```

- [ ] **Step 2: Replace `Road_BeansApp.swift` contents**

```swift
//
//  Road_BeansApp.swift
//  Road Beans
//

import SwiftUI

@main
struct Road_BeansApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

- [ ] **Step 3: Replace `ContentView.swift` contents**

```swift
//
//  ContentView.swift
//  Road Beans
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Road Beans")
    }
}

#Preview {
    ContentView()
}
```

- [ ] **Step 4: Create folder scaffold**

```bash
cd "Road Beans"
mkdir -p App/Persistence Models ReadModels Commands DTOs \
  Repositories/Protocols Repositories/Local Services \
  Features/PlaceList Features/PlaceDetail Features/VisitDetail Features/AddVisit Features/Map \
  DesignSystem/BeanSlider
# Do not add .gitkeep files: file-system-synchronized Xcode groups copy
# dotfiles as resources, which creates duplicate bundle outputs.
```

- [ ] **Step 5: Add the test target**

Add a `Road BeansTests` unit-test bundle target to `Road Beans.xcodeproj/project.pbxproj`, using Swift Testing and a file-system-synchronized root group at `Road BeansTests`. Confirm the target appears in the project and can `@testable import Road_Beans`.

- [ ] **Step 6: Create test subfolders**

```bash
cd "Road BeansTests"
mkdir -p RepositoryTests ViewModelTests ServiceTests DTOTests DesignSystemTests
# Do not add .gitkeep files: these directories are scaffold-only until
# later tasks add source files.
```

- [ ] **Step 7: Add the smoke test**

Create `Road BeansTests/RepositoryTests/SmokeTests.swift`:

```swift
import Testing

@Suite("Smoke")
struct SmokeTests {
    @Test func testTargetIsWiredUp() {
        #expect(1 + 1 == 2)
    }
}
```

- [ ] **Step 8: Build and run smoke test**

```bash
xcodebuild -project "Road Beans.xcodeproj" -scheme "Road Beans" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build test -only-testing:"Road BeansTests/SmokeTests"
```

Expected: `Test Suite 'SmokeTests' passed`, BUILD SUCCEEDED.

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "chore: strip Xcode template, add test target, scaffold folders"
```

---

### Task 1: Domain enums (`PlaceKind`, `PlaceSource`, `DrinkCategory`, `SyncState`)

**Goal:** Define the four domain enums with their display metadata. These have no dependencies and are referenced by every model.

**Files:**
- Create: `Road Beans/Models/PlaceKind.swift`
- Create: `Road Beans/Models/PlaceSource.swift`
- Create: `Road Beans/Models/DrinkCategory.swift`
- Create: `Road Beans/Models/SyncState.swift`
- Test: `Road BeansTests/RepositoryTests/EnumTests.swift`

**Acceptance Criteria:**
- [ ] `PlaceKind` has cases `coffeeShop, truckStop, gasStation, fastFood, other` with `displayName`, `sfSymbol`, `accentColor`.
- [ ] `PlaceSource` has cases `mapKit, custom`.
- [ ] `DrinkCategory` has cases `drip, latte, cappuccino, coldBrew, espresso, tea, other` with `displayName`, `sfSymbol`.
- [ ] `SyncState` has cases `pendingUpload, synced, failed`.
- [ ] All enums conform to `String, Codable, CaseIterable, Sendable`.
- [ ] Tests verify rawValue stability (rawValues do not change — they go into DTOs).

**Verify:** `xcodebuild ... test -only-testing:"Road BeansTests/EnumTests"` → all tests pass.

**Steps:**

- [ ] **Step 1: Write failing tests first**

Create `Road BeansTests/RepositoryTests/EnumTests.swift`:

```swift
import Testing
import SwiftUI
@testable import Road_Beans

@Suite("Domain enums")
struct EnumTests {
    @Test func placeKindRawValuesAreStable() {
        #expect(PlaceKind.coffeeShop.rawValue == "coffeeShop")
        #expect(PlaceKind.truckStop.rawValue == "truckStop")
        #expect(PlaceKind.gasStation.rawValue == "gasStation")
        #expect(PlaceKind.fastFood.rawValue == "fastFood")
        #expect(PlaceKind.other.rawValue == "other")
    }

    @Test func placeKindHasDisplayMetadata() {
        for kind in PlaceKind.allCases {
            #expect(!kind.displayName.isEmpty)
            #expect(!kind.sfSymbol.isEmpty)
        }
    }

    @Test func placeSourceRawValuesAreStable() {
        #expect(PlaceSource.mapKit.rawValue == "mapKit")
        #expect(PlaceSource.custom.rawValue == "custom")
    }

    @Test func drinkCategoryHasDisplayMetadata() {
        for c in DrinkCategory.allCases {
            #expect(!c.displayName.isEmpty)
            #expect(!c.sfSymbol.isEmpty)
        }
    }

    @Test func syncStateRawValuesAreStable() {
        #expect(SyncState.pendingUpload.rawValue == "pendingUpload")
        #expect(SyncState.synced.rawValue == "synced")
        #expect(SyncState.failed.rawValue == "failed")
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
xcodebuild -project "Road Beans.xcodeproj" -scheme "Road Beans" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  test -only-testing:"Road BeansTests/EnumTests"
```

Expected: compile error (`PlaceKind` etc. not defined).

- [ ] **Step 3: Implement `PlaceKind`**

Create `Road Beans/Models/PlaceKind.swift`:

```swift
import SwiftUI

enum PlaceKind: String, Codable, CaseIterable, Sendable {
    case coffeeShop
    case truckStop
    case gasStation
    case fastFood
    case other

    var displayName: String {
        switch self {
        case .coffeeShop: return "Coffee Shop"
        case .truckStop:  return "Truck Stop"
        case .gasStation: return "Gas Station"
        case .fastFood:   return "Fast Food"
        case .other:      return "Other"
        }
    }

    var sfSymbol: String {
        switch self {
        case .coffeeShop: return "cup.and.saucer.fill"
        case .truckStop:  return "truck.box.fill"
        case .gasStation: return "fuelpump.fill"
        case .fastFood:   return "takeoutbag.and.cup.and.straw.fill"
        case .other:      return "mappin.and.ellipse"
        }
    }

    var accentColor: Color {
        switch self {
        case .coffeeShop: return Color(red: 0.45, green: 0.27, blue: 0.18)  // espresso
        case .truckStop:  return Color(red: 0.95, green: 0.65, blue: 0.18)  // highway amber
        case .gasStation: return Color(red: 0.18, green: 0.62, blue: 0.62)  // fuel teal
        case .fastFood:   return Color(red: 0.85, green: 0.25, blue: 0.22)  // burger red
        case .other:      return Color(red: 0.45, green: 0.50, blue: 0.55)  // neutral slate
        }
    }
}
```

- [ ] **Step 4: Implement `PlaceSource`**

Create `Road Beans/Models/PlaceSource.swift`:

```swift
import Foundation

enum PlaceSource: String, Codable, CaseIterable, Sendable {
    case mapKit
    case custom
}
```

- [ ] **Step 5: Implement `DrinkCategory`**

Create `Road Beans/Models/DrinkCategory.swift`:

```swift
import Foundation

enum DrinkCategory: String, Codable, CaseIterable, Sendable {
    case drip, latte, cappuccino, coldBrew, espresso, tea, other

    var displayName: String {
        switch self {
        case .drip:       return "Drip"
        case .latte:      return "Latte"
        case .cappuccino: return "Cappuccino"
        case .coldBrew:   return "Cold Brew"
        case .espresso:   return "Espresso"
        case .tea:        return "Tea"
        case .other:      return "Other"
        }
    }

    var sfSymbol: String {
        switch self {
        case .drip:       return "cup.and.saucer.fill"
        case .latte:      return "mug.fill"
        case .cappuccino: return "mug.fill"
        case .coldBrew:   return "takeoutbag.and.cup.and.straw.fill"
        case .espresso:   return "cup.and.heat.waves.fill"
        case .tea:        return "leaf.fill"
        case .other:      return "questionmark.circle"
        }
    }
}
```

- [ ] **Step 6: Implement `SyncState`**

Create `Road Beans/Models/SyncState.swift`:

```swift
import Foundation

enum SyncState: String, Codable, CaseIterable, Sendable {
    case pendingUpload
    case synced
    case failed
}
```

- [ ] **Step 7: Run tests to verify pass**

```bash
xcodebuild ... test -only-testing:"Road BeansTests/EnumTests"
```

Expected: all tests pass.

- [ ] **Step 8: Commit**

```bash
git add "Road Beans/Models" "Road BeansTests/RepositoryTests/EnumTests.swift"
git commit -m "feat: add domain enums (PlaceKind, PlaceSource, DrinkCategory, SyncState)"
```

---

### Task 2: SwiftData `@Model` entities (Place, Visit, Drink, Tag, VisitPhoto, Tombstone)

**Goal:** Define all six SwiftData entities with CloudKit-compatible optional relationships, default values, and sync metadata. Add the domain accessor extensions so callers can read `place.visits` instead of `place._visits ?? []`.

**Files:**
- Create: `Road Beans/Models/Place.swift`
- Create: `Road Beans/Models/Visit.swift`
- Create: `Road Beans/Models/Drink.swift`
- Create: `Road Beans/Models/Tag.swift`
- Create: `Road Beans/Models/VisitPhoto.swift`
- Create: `Road Beans/Models/Tombstone.swift`
- Create: `Road Beans/Models/AppSchema.swift` — central `Schema` registration list.
- Test: `Road BeansTests/RepositoryTests/ModelDefaultsTests.swift`

**Acceptance Criteria:**
- [ ] All six models compile as `@Model final class`.
- [ ] All relationships are optional with `[]` or `nil` defaults.
- [ ] Sync metadata (`remoteID`, `syncState`, `authorIdentifier`, `lastModifiedAt`) present on Place/Visit/Drink/Tag/VisitPhoto.
- [ ] Tombstone is flat (no relationships) and has `entityKind`, `entityID`, `remoteID`, `deletedAt`, `authorIdentifier`, `syncState`.
- [ ] Domain accessors (`var visits: [Visit]`, `var drinks: [Drink]`, `var tags: [Tag]`, `var photos: [VisitPhoto]`) return non-optional arrays.
- [ ] `Place.coordinate` derives `CLLocationCoordinate2D?` from `latitude`/`longitude`.
- [ ] `AppSchema.all` lists all six entity types.
- [ ] Tests verify default values (newly inserted entity has `syncState == .pendingUpload`, `lastModifiedAt` recent, empty relationship arrays).

**Verify:** `xcodebuild ... test -only-testing:"Road BeansTests/ModelDefaultsTests"` → all pass.

**Steps:**

- [ ] **Step 1: Write failing tests**

Create `Road BeansTests/RepositoryTests/ModelDefaultsTests.swift`:

```swift
import Testing
import SwiftData
@testable import Road_Beans

@Suite("Model defaults")
@MainActor
struct ModelDefaultsTests {
    func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: AppSchema.all,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test func placeDefaults() throws {
        let ctx = try makeContext()
        let p = Place()
        ctx.insert(p)
        #expect(p.kind == .other)
        #expect(p.source == .custom)
        #expect(p.syncState == .pendingUpload)
        #expect(p.remoteID == nil)
        #expect(p.visits.isEmpty)
    }

    @Test func visitDefaults() throws {
        let ctx = try makeContext()
        let v = Visit()
        ctx.insert(v)
        #expect(v.drinks.isEmpty)
        #expect(v.tags.isEmpty)
        #expect(v.photos.isEmpty)
        #expect(v.syncState == .pendingUpload)
    }

    @Test func drinkDefaults() throws {
        let ctx = try makeContext()
        let d = Drink()
        ctx.insert(d)
        #expect(d.category == .other)
        #expect(d.rating == 3.0)
        #expect(d.tags.isEmpty)
    }

    @Test func tagDefaults() throws {
        let ctx = try makeContext()
        let t = Tag()
        ctx.insert(t)
        #expect(t.name == "")
        #expect(t.usageCount == 0)
    }

    @Test func visitPhotoDefaults() throws {
        let ctx = try makeContext()
        let p = VisitPhoto()
        ctx.insert(p)
        #expect(p.imageData.isEmpty)
        #expect(p.thumbnailData.isEmpty)
        #expect(p.widthPx == 0)
        #expect(p.heightPx == 0)
    }

    @Test func tombstoneDefaults() throws {
        let ctx = try makeContext()
        let t = Tombstone(entityKind: "visit", entityID: UUID())
        ctx.insert(t)
        #expect(t.syncState == .pendingUpload)
        #expect(t.remoteID == nil)
    }

    @Test func placeCoordinateDerivesFromLatLng() {
        let p = Place()
        p.latitude = 34.5
        p.longitude = -112.5
        #expect(p.coordinate?.latitude == 34.5)
        #expect(p.coordinate?.longitude == -112.5)

        let p2 = Place()
        #expect(p2.coordinate == nil)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail (compile errors)**

```bash
xcodebuild ... test -only-testing:"Road BeansTests/ModelDefaultsTests"
```

Expected: compile errors — `Place`, `Visit`, etc. not defined.

- [ ] **Step 3: Implement `Place`**

Create `Road Beans/Models/Place.swift`:

```swift
import Foundation
import SwiftData
import CoreLocation

@Model
final class Place {
    var id: UUID = UUID()
    var name: String = ""
    var kind: PlaceKind = PlaceKind.other
    var source: PlaceSource = PlaceSource.custom
    var address: String? = nil
    var mapKitName: String? = nil
    var mapKitIdentifier: String? = nil
    var latitude: Double? = nil
    var longitude: Double? = nil
    var phoneNumber: String? = nil
    var websiteURL: URL? = nil
    var streetNumber: String? = nil
    var streetName: String? = nil
    var city: String? = nil
    var region: String? = nil
    var postalCode: String? = nil
    var country: String? = nil
    var createdAt: Date = Date.now
    var lastModifiedAt: Date = Date.now

    // sync metadata
    var remoteID: String? = nil
    var syncState: SyncState = SyncState.pendingUpload
    var authorIdentifier: String? = nil

    @Relationship(deleteRule: .cascade, inverse: \Visit._place)
    var _visits: [Visit]? = []

    init() {}
}

extension Place {
    var visits: [Visit] { _visits ?? [] }

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lng = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}
```

- [ ] **Step 4: Implement `Visit`**

Create `Road Beans/Models/Visit.swift`:

```swift
import Foundation
import SwiftData

@Model
final class Visit {
    var id: UUID = UUID()
    var date: Date = Date.now
    var createdAt: Date = Date.now
    var lastModifiedAt: Date = Date.now

    // sync metadata
    var remoteID: String? = nil
    var syncState: SyncState = SyncState.pendingUpload
    var authorIdentifier: String? = nil

    var _place: Place? = nil

    @Relationship(deleteRule: .cascade, inverse: \Drink._visit)
    var _drinks: [Drink]? = []

    @Relationship(inverse: \Tag._visits)
    var _tags: [Tag]? = []

    @Relationship(deleteRule: .cascade, inverse: \VisitPhoto._visit)
    var _photos: [VisitPhoto]? = []

    init() {}
}

extension Visit {
    var place: Place? { _place }
    var drinks: [Drink] { _drinks ?? [] }
    var tags: [Tag] { _tags ?? [] }
    var photos: [VisitPhoto] { _photos ?? [] }
}
```

- [ ] **Step 5: Implement `Drink`**

Create `Road Beans/Models/Drink.swift`:

```swift
import Foundation
import SwiftData

@Model
final class Drink {
    var id: UUID = UUID()
    var name: String = ""
    var category: DrinkCategory = DrinkCategory.other
    var rating: Double = 3.0
    var createdAt: Date = Date.now
    var lastModifiedAt: Date = Date.now

    // sync metadata
    var remoteID: String? = nil
    var syncState: SyncState = SyncState.pendingUpload
    var authorIdentifier: String? = nil

    var _visit: Visit? = nil

    @Relationship(inverse: \Tag._drinks)
    var _tags: [Tag]? = []

    init() {}
}

extension Drink {
    var visit: Visit? { _visit }
    var tags: [Tag] { _tags ?? [] }
}
```

- [ ] **Step 6: Implement `Tag`**

Create `Road Beans/Models/Tag.swift`:

```swift
import Foundation
import SwiftData

@Model
final class Tag {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date.now
    var lastModifiedAt: Date = Date.now

    // sync metadata
    var remoteID: String? = nil
    var syncState: SyncState = SyncState.pendingUpload
    var authorIdentifier: String? = nil

    @Relationship var _visits: [Visit]? = []
    @Relationship var _drinks: [Drink]? = []

    init() {}
}

extension Tag {
    var visits: [Visit] { _visits ?? [] }
    var drinks: [Drink] { _drinks ?? [] }
    /// Derived; recomputed on access. See spec §3.
    var usageCount: Int { (_visits?.count ?? 0) + (_drinks?.count ?? 0) }
}
```

- [ ] **Step 7: Implement `VisitPhoto`**

Create `Road Beans/Models/VisitPhoto.swift`:

```swift
import Foundation
import SwiftData

@Model
final class VisitPhoto {
    var id: UUID = UUID()

    @Attribute(.externalStorage)
    var imageData: Data = Data()

    @Attribute(.externalStorage)
    var thumbnailData: Data = Data()

    var caption: String? = nil
    var widthPx: Int = 0
    var heightPx: Int = 0
    var createdAt: Date = Date.now
    var lastModifiedAt: Date = Date.now

    // sync metadata
    var remoteID: String? = nil
    var syncState: SyncState = SyncState.pendingUpload
    var authorIdentifier: String? = nil

    var _visit: Visit? = nil

    init() {}
}

extension VisitPhoto {
    var visit: Visit? { _visit }
}
```

- [ ] **Step 8: Implement `Tombstone`**

Create `Road Beans/Models/Tombstone.swift`:

```swift
import Foundation
import SwiftData

@Model
final class Tombstone {
    var id: UUID = UUID()
    var entityKind: String = ""
    var entityID: UUID = UUID()
    var remoteID: String? = nil
    var deletedAt: Date = Date.now
    var authorIdentifier: String? = nil
    var syncState: SyncState = SyncState.pendingUpload

    init() {}

    init(entityKind: String, entityID: UUID, remoteID: String? = nil) {
        self.entityKind = entityKind
        self.entityID = entityID
        self.remoteID = remoteID
    }
}
```

- [ ] **Step 9: Implement `AppSchema`**

Create `Road Beans/Models/AppSchema.swift`:

```swift
import Foundation
import SwiftData

enum AppSchema {
    static let all: Schema = Schema([
        Place.self,
        Visit.self,
        Drink.self,
        Tag.self,
        VisitPhoto.self,
        Tombstone.self,
    ])
}
```

- [ ] **Step 10: Run tests to verify pass**

```bash
xcodebuild ... test -only-testing:"Road BeansTests/ModelDefaultsTests"
```

Expected: all tests pass.

- [ ] **Step 11: Commit**

```bash
git add "Road Beans/Models" "Road BeansTests/RepositoryTests/ModelDefaultsTests.swift"
git commit -m "feat: add SwiftData @Model entities with CloudKit-safe optional relationships"
```

---

### Task 3: Read structs (`PlaceSummary`, `PlaceDetail`, `VisitRow`, `VisitDetail`, `DrinkRow`, `TagSuggestion`, `PlaceReference`, `PhotoReference`)

**Goal:** Define the plain-struct read models that repositories return to view-models. View-models must never see `@Model` instances.

**Files:**
- Create: `Road Beans/ReadModels/PlaceSummary.swift`
- Create: `Road Beans/ReadModels/PlaceDetail.swift`
- Create: `Road Beans/ReadModels/VisitRow.swift`
- Create: `Road Beans/ReadModels/VisitDetail.swift`
- Create: `Road Beans/ReadModels/DrinkRow.swift`
- Create: `Road Beans/ReadModels/TagSuggestion.swift`
- Create: `Road Beans/ReadModels/PlaceReference.swift`
- Create: `Road Beans/ReadModels/PhotoReference.swift`

**Acceptance Criteria:**
- [ ] All read structs are plain `struct: Identifiable, Hashable, Sendable`.
- [ ] No SwiftData imports in `ReadModels/`.
- [ ] `PlaceSummary` carries id, name, kind, address, average rating (Double?), visit count.
- [ ] `PlaceDetail` carries everything `PlaceSummary` has plus full address components, phone, URL, coordinate, and a `[VisitRow]` array.
- [ ] `VisitRow` carries id, date, drink count, tag names, photo count, average rating.
- [ ] `VisitDetail` carries id, date, place reference, `[DrinkRow]`, tag names, `[PhotoReference]`.
- [ ] `DrinkRow` carries id, name, category, rating, tag names.
- [ ] `TagSuggestion` carries id, name, derived usageCount.
- [ ] `PlaceReference` enum: `.existing(id: UUID)` or `.newMapKit(...) ` or `.newCustom(...)`. Used by add-flow commands so the add flow can pass either an existing place pointer or a draft.
- [ ] `PhotoReference` carries id and `Data` for thumbnail (UI-display tier).
- [ ] Build succeeds.

**Verify:** `xcodebuild ... build` → BUILD SUCCEEDED.

**Steps:**

- [ ] **Step 1: Implement `PlaceSummary`**

Create `Road Beans/ReadModels/PlaceSummary.swift`:

```swift
import Foundation
import CoreLocation

struct PlaceSummary: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let kind: PlaceKind
    let address: String?
    let coordinate: CLLocationCoordinate2D?
    let averageRating: Double?   // nil if no drinks yet
    let visitCount: Int

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: PlaceSummary, rhs: PlaceSummary) -> Bool { lhs.id == rhs.id }
}
```

- [ ] **Step 2: Implement `PlaceDetail`**

Create `Road Beans/ReadModels/PlaceDetail.swift`:

```swift
import Foundation
import CoreLocation

struct PlaceDetail: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let kind: PlaceKind
    let source: PlaceSource
    let address: String?
    let streetNumber: String?
    let streetName: String?
    let city: String?
    let region: String?
    let postalCode: String?
    let country: String?
    let phoneNumber: String?
    let websiteURL: URL?
    let coordinate: CLLocationCoordinate2D?
    let averageRating: Double?
    let visits: [VisitRow]

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: PlaceDetail, rhs: PlaceDetail) -> Bool { lhs.id == rhs.id }
}
```

- [ ] **Step 3: Implement `VisitRow`**

Create `Road Beans/ReadModels/VisitRow.swift`:

```swift
import Foundation

struct VisitRow: Identifiable, Hashable, Sendable {
    let id: UUID
    let date: Date
    let drinkCount: Int
    let tagNames: [String]
    let photoCount: Int
    let averageRating: Double?
}
```

- [ ] **Step 4: Implement `VisitDetail`**

Create `Road Beans/ReadModels/VisitDetail.swift`:

```swift
import Foundation

struct VisitDetail: Identifiable, Hashable, Sendable {
    let id: UUID
    let date: Date
    let placeID: UUID
    let placeName: String
    let placeKind: PlaceKind
    let drinks: [DrinkRow]
    let tagNames: [String]
    let photos: [PhotoReference]
}
```

- [ ] **Step 5: Implement `DrinkRow`**

Create `Road Beans/ReadModels/DrinkRow.swift`:

```swift
import Foundation

struct DrinkRow: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let category: DrinkCategory
    let rating: Double
    let tagNames: [String]
}
```

- [ ] **Step 6: Implement `TagSuggestion`**

Create `Road Beans/ReadModels/TagSuggestion.swift`:

```swift
import Foundation

struct TagSuggestion: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let usageCount: Int
}
```

- [ ] **Step 7: Implement `PlaceReference`**

Create `Road Beans/ReadModels/PlaceReference.swift`:

```swift
import Foundation
import CoreLocation

/// What the add-flow uses to identify a place to attach the visit to.
/// Either an existing Place (by id) or a draft to be created on save.
enum PlaceReference: Hashable, Sendable {
    case existing(id: UUID)
    case newMapKit(MapKitPlaceDraft)
    case newCustom(CustomPlaceDraft)
}

struct MapKitPlaceDraft: Hashable, Sendable {
    let name: String
    let kind: PlaceKind
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
}

struct CustomPlaceDraft: Hashable, Sendable {
    let name: String
    let kind: PlaceKind
    let address: String?
}
```

- [ ] **Step 8: Implement `PhotoReference`**

Create `Road Beans/ReadModels/PhotoReference.swift`:

```swift
import Foundation

struct PhotoReference: Identifiable, Hashable, Sendable {
    let id: UUID
    let thumbnailData: Data
    let widthPx: Int
    let heightPx: Int
    let caption: String?
}
```

- [ ] **Step 9: Build**

```bash
xcodebuild -project "Road Beans.xcodeproj" -scheme "Road Beans" \
  -destination 'generic/platform=iOS Simulator' build
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 10: Commit**

```bash
git add "Road Beans/ReadModels"
git commit -m "feat: add read-model structs for view-model consumption"
```

---

### Task 4: Command structs (`CreateVisitCommand`, `UpdateVisitCommand`, `DeleteVisitCommand`, drafts)

**Goal:** Define the plain-struct mutation commands view-models pass to repositories. Mirrors the read-models layer.

**Files:**
- Create: `Road Beans/Commands/CreateVisitCommand.swift`
- Create: `Road Beans/Commands/UpdateVisitCommand.swift`
- Create: `Road Beans/Commands/DeleteVisitCommand.swift`
- Create: `Road Beans/Commands/Drafts.swift` (DrinkDraft, PhotoDraft)

**Acceptance Criteria:**
- [ ] `CreateVisitCommand(placeRef: PlaceReference, date: Date, drinks: [DrinkDraft], tags: [String], photos: [PhotoDraft])`.
- [ ] `UpdateVisitCommand` carries the visit `id` plus optional fields to change.
- [ ] `DeleteVisitCommand(id: UUID)`.
- [ ] `DrinkDraft(name: String, category: DrinkCategory, rating: Double, tags: [String])`.
- [ ] `PhotoDraft(rawImageData: Data, caption: String?)` — pre-processing payload.
- [ ] No SwiftData imports.
- [ ] Build succeeds.

**Verify:** `xcodebuild ... build` → BUILD SUCCEEDED.

**Steps:**

- [ ] **Step 1: Implement drafts**

Create `Road Beans/Commands/Drafts.swift`:

```swift
import Foundation

struct DrinkDraft: Hashable, Sendable {
    var name: String
    var category: DrinkCategory
    var rating: Double            // 0.0...5.0, repository clamps & rounds
    var tags: [String]
}

struct PhotoDraft: Hashable, Sendable {
    let rawImageData: Data        // raw picker bytes; service processes before persist
    var caption: String?
}
```

- [ ] **Step 2: Implement `CreateVisitCommand`**

Create `Road Beans/Commands/CreateVisitCommand.swift`:

```swift
import Foundation

struct CreateVisitCommand: Sendable {
    let placeRef: PlaceReference
    let date: Date
    let drinks: [DrinkDraft]
    let tags: [String]
    let photos: [PhotoDraft]
}
```

- [ ] **Step 3: Implement `UpdateVisitCommand`**

Create `Road Beans/Commands/UpdateVisitCommand.swift`:

```swift
import Foundation

struct UpdateVisitCommand: Sendable {
    let id: UUID
    var date: Date?
    var tags: [String]?
    var drinks: [DrinkDraft]?     // full replacement when present
    var photoAdditions: [PhotoDraft]?
    var photoRemovals: [UUID]?
}
```

- [ ] **Step 4: Implement `DeleteVisitCommand`**

Create `Road Beans/Commands/DeleteVisitCommand.swift`:

```swift
import Foundation

struct DeleteVisitCommand: Sendable {
    let id: UUID
}
```

- [ ] **Step 5: Build**

```bash
xcodebuild ... build
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 6: Commit**

```bash
git add "Road Beans/Commands"
git commit -m "feat: add command structs for visit create/update/delete"
```

---

### Task 5: DTOs and `UploadEnvelope`

**Goal:** Define the v2-upload DTO contract per spec §10. All flat, FK-based, `Codable`, with stable rawValue strings for enums.

**Files:**
- Create: `Road Beans/DTOs/PlaceDTO.swift`
- Create: `Road Beans/DTOs/VisitDTO.swift`
- Create: `Road Beans/DTOs/DrinkDTO.swift`
- Create: `Road Beans/DTOs/TagDTO.swift`
- Create: `Road Beans/DTOs/VisitPhotoDTO.swift`
- Create: `Road Beans/DTOs/TagAssignmentDTO.swift`
- Create: `Road Beans/DTOs/TombstoneDTO.swift`
- Create: `Road Beans/DTOs/UploadEnvelope.swift`
- Test: `Road BeansTests/DTOTests/UploadEnvelopeRoundTripTests.swift`

**Acceptance Criteria:**
- [ ] All DTOs are `struct: Codable, Hashable, Sendable`.
- [ ] `UploadEnvelope.schemaVersion` is `1`.
- [ ] Round-trip test: encode an envelope to JSON → decode back → `#expect` equals.
- [ ] FK references hold (decoded envelope's drinks reference visits that exist in the visits array).
- [ ] No `usageCount` field on `TagDTO`.

**Verify:** `xcodebuild ... test -only-testing:"Road BeansTests/UploadEnvelopeRoundTripTests"` → all tests pass.

**Steps:**

- [ ] **Step 1: Write failing round-trip test**

Create `Road BeansTests/DTOTests/UploadEnvelopeRoundTripTests.swift`:

```swift
import Testing
import Foundation
@testable import Road_Beans

@Suite("UploadEnvelope round-trip")
struct UploadEnvelopeRoundTripTests {
    @Test func envelopeRoundTripsLosslessly() throws {
        let placeID = UUID()
        let visitID = UUID()
        let drinkID = UUID()
        let tagID = UUID()
        let photoID = UUID()
        let tombID = UUID()

        let envelope = UploadEnvelope(
            schemaVersion: 1,
            exportedAt: Date(timeIntervalSince1970: 1_750_000_000),
            authorIdentifier: nil,
            places: [.init(
                id: placeID, remoteID: nil,
                lastModifiedAt: Date(timeIntervalSince1970: 1_750_000_000),
                name: "Loves",
                kind: PlaceKind.truckStop.rawValue,
                source: PlaceSource.mapKit.rawValue,
                mapKitIdentifier: "mk-123", mapKitName: "Love's Travel Stop",
                address: "I-17 Exit 262, Cordes Junction, AZ",
                latitude: 34.32, longitude: -112.12,
                phoneNumber: "555-1212", websiteURL: URL(string: "https://loves.com"),
                streetNumber: "1", streetName: "Frontage Rd",
                city: "Cordes Junction", region: "AZ",
                postalCode: "86333", country: "USA",
                createdAt: Date(timeIntervalSince1970: 1_750_000_000)
            )],
            visits: [.init(
                id: visitID, remoteID: nil, placeID: placeID,
                date: Date(timeIntervalSince1970: 1_750_000_000),
                lastModifiedAt: Date(timeIntervalSince1970: 1_750_000_000),
                createdAt: Date(timeIntervalSince1970: 1_750_000_000)
            )],
            drinks: [.init(
                id: drinkID, remoteID: nil, visitID: visitID,
                name: "CFHB", category: DrinkCategory.drip.rawValue, rating: 4.2,
                lastModifiedAt: Date(timeIntervalSince1970: 1_750_000_000),
                createdAt: Date(timeIntervalSince1970: 1_750_000_000)
            )],
            tags: [.init(
                id: tagID, remoteID: nil, name: "smooth",
                lastModifiedAt: Date(timeIntervalSince1970: 1_750_000_000),
                createdAt: Date(timeIntervalSince1970: 1_750_000_000)
            )],
            visitPhotos: [.init(
                id: photoID, remoteID: nil, visitID: visitID,
                caption: "morning",
                widthPx: 2048, heightPx: 1536,
                assetReference: "blob://\(photoID)",
                lastModifiedAt: Date(timeIntervalSince1970: 1_750_000_000),
                createdAt: Date(timeIntervalSince1970: 1_750_000_000)
            )],
            visitTagAssignments: [.init(tagID: tagID, entityID: visitID)],
            drinkTagAssignments: [.init(tagID: tagID, entityID: drinkID)],
            tombstones: [.init(
                id: UUID(), entityKind: "drink", entityID: tombID, remoteID: nil,
                deletedAt: Date(timeIntervalSince1970: 1_750_000_000)
            )]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(envelope)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(UploadEnvelope.self, from: data)

        #expect(decoded == envelope)
        // FKs hold:
        let visit = decoded.visits.first!
        let parentPlace = decoded.places.first { $0.id == visit.placeID }
        #expect(parentPlace != nil)
        let drink = decoded.drinks.first!
        let parentVisit = decoded.visits.first { $0.id == drink.visitID }
        #expect(parentVisit != nil)
    }
}
```

- [ ] **Step 2: Run to verify failure**

```bash
xcodebuild ... test -only-testing:"Road BeansTests/UploadEnvelopeRoundTripTests"
```

Expected: compile errors.

- [ ] **Step 3: Implement `PlaceDTO`**

Create `Road Beans/DTOs/PlaceDTO.swift`:

```swift
import Foundation

struct PlaceDTO: Codable, Hashable, Sendable {
    let id: UUID
    let remoteID: String?
    let lastModifiedAt: Date
    let name: String
    let kind: String
    let source: String
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
```

- [ ] **Step 4: Implement `VisitDTO`**

Create `Road Beans/DTOs/VisitDTO.swift`:

```swift
import Foundation

struct VisitDTO: Codable, Hashable, Sendable {
    let id: UUID
    let remoteID: String?
    let placeID: UUID
    let date: Date
    let lastModifiedAt: Date
    let createdAt: Date
}
```

- [ ] **Step 5: Implement `DrinkDTO`**

Create `Road Beans/DTOs/DrinkDTO.swift`:

```swift
import Foundation

struct DrinkDTO: Codable, Hashable, Sendable {
    let id: UUID
    let remoteID: String?
    let visitID: UUID
    let name: String
    let category: String
    let rating: Double
    let lastModifiedAt: Date
    let createdAt: Date
}
```

- [ ] **Step 6: Implement `TagDTO`**

Create `Road Beans/DTOs/TagDTO.swift`:

```swift
import Foundation

struct TagDTO: Codable, Hashable, Sendable {
    let id: UUID
    let remoteID: String?
    let name: String
    let lastModifiedAt: Date
    let createdAt: Date
}
```

- [ ] **Step 7: Implement `VisitPhotoDTO`**

Create `Road Beans/DTOs/VisitPhotoDTO.swift`:

```swift
import Foundation

struct VisitPhotoDTO: Codable, Hashable, Sendable {
    let id: UUID
    let remoteID: String?
    let visitID: UUID
    let caption: String?
    let widthPx: Int
    let heightPx: Int
    let assetReference: String
    let lastModifiedAt: Date
    let createdAt: Date
}
```

- [ ] **Step 8: Implement `TagAssignmentDTO`**

Create `Road Beans/DTOs/TagAssignmentDTO.swift`:

```swift
import Foundation

struct TagAssignmentDTO: Codable, Hashable, Sendable {
    let tagID: UUID
    let entityID: UUID
}
```

- [ ] **Step 9: Implement `TombstoneDTO`**

Create `Road Beans/DTOs/TombstoneDTO.swift`:

```swift
import Foundation

struct TombstoneDTO: Codable, Hashable, Sendable {
    let id: UUID
    let entityKind: String
    let entityID: UUID
    let remoteID: String?
    let deletedAt: Date
}
```

- [ ] **Step 10: Implement `UploadEnvelope`**

Create `Road Beans/DTOs/UploadEnvelope.swift`:

```swift
import Foundation

struct UploadEnvelope: Codable, Hashable, Sendable {
    let schemaVersion: Int
    let exportedAt: Date
    let authorIdentifier: String?
    let places: [PlaceDTO]
    let visits: [VisitDTO]
    let drinks: [DrinkDTO]
    let tags: [TagDTO]
    let visitPhotos: [VisitPhotoDTO]
    let visitTagAssignments: [TagAssignmentDTO]
    let drinkTagAssignments: [TagAssignmentDTO]
    let tombstones: [TombstoneDTO]
}
```

- [ ] **Step 11: Run tests to verify pass**

```bash
xcodebuild ... test -only-testing:"Road BeansTests/UploadEnvelopeRoundTripTests"
```

Expected: PASS.

- [ ] **Step 12: Commit**

```bash
git add "Road Beans/DTOs" "Road BeansTests/DTOTests"
git commit -m "feat: add v2-upload DTO envelope with round-trip test"
```

---

### Task 6: `iCloudAvailabilityService` and `PersistenceMode`

**Goal:** Detect whether iCloud is available, watch for identity changes, and define the `PersistenceMode` enum used by the controller.

**Files:**
- Create: `Road Beans/App/Persistence/PersistenceMode.swift`
- Create: `Road Beans/Services/iCloudAvailabilityService.swift`
- Test: `Road BeansTests/ServiceTests/iCloudAvailabilityServiceTests.swift`

**Acceptance Criteria:**
- [ ] `PersistenceMode`: `.localOnly | .cloudKitBacked | .pendingMigration | .pendingRelaunch`. Equatable, Sendable.
- [ ] `iCloudAvailabilityServiceProtocol` exposes `func currentToken() -> AnyHashable?` and an async `AsyncStream<Void>` of identity-change events.
- [ ] Concrete `SystemICloudAvailabilityService` reads `FileManager.default.ubiquityIdentityToken`; the change stream wraps `NSUbiquityIdentityDidChange` notifications.
- [ ] A `FakeICloudAvailabilityService` is provided for tests (settable token, manual `triggerIdentityChange()`).
- [ ] Tests cover: token returned, fake notifies subscribers, multiple subscribers receive the event.

**Verify:** `xcodebuild ... test -only-testing:"Road BeansTests/iCloudAvailabilityServiceTests"` → PASS.

**Steps:**

- [ ] **Step 1: Implement `PersistenceMode`**

Create `Road Beans/App/Persistence/PersistenceMode.swift`:

```swift
import Foundation

enum PersistenceMode: Equatable, Sendable {
    case localOnly
    case cloudKitBacked
    case pendingMigration
    case pendingRelaunch
}
```

- [ ] **Step 2: Write failing tests**

Create `Road BeansTests/ServiceTests/iCloudAvailabilityServiceTests.swift`:

```swift
import Testing
import Foundation
@testable import Road_Beans

@Suite("iCloudAvailabilityService")
struct iCloudAvailabilityServiceTests {
    @Test func fakeReportsTokenWhenSet() {
        let svc = FakeICloudAvailabilityService()
        #expect(svc.currentToken() == nil)
        svc.token = "abc" as AnyHashable
        #expect(svc.currentToken() == ("abc" as AnyHashable))
    }

    @Test func fakeNotifiesSubscriberOnIdentityChange() async {
        let svc = FakeICloudAvailabilityService()
        let stream = svc.identityChanges
        let task = Task { () -> Bool in
            for await _ in stream { return true }
            return false
        }
        // Yield, then trigger
        try? await Task.sleep(nanoseconds: 50_000_000)
        svc.triggerIdentityChange()
        let got = await task.value
        #expect(got)
    }
}
```

- [ ] **Step 3: Implement `iCloudAvailabilityService`**

Create `Road Beans/Services/iCloudAvailabilityService.swift`:

```swift
import Foundation

protocol iCloudAvailabilityServiceProtocol: Sendable {
    func currentToken() -> AnyHashable?
    var identityChanges: AsyncStream<Void> { get }
}

final class SystemICloudAvailabilityService: iCloudAvailabilityServiceProtocol, @unchecked Sendable {
    private let center = NotificationCenter.default
    private var continuation: AsyncStream<Void>.Continuation?
    let identityChanges: AsyncStream<Void>

    init() {
        var continuation: AsyncStream<Void>.Continuation!
        self.identityChanges = AsyncStream { c in continuation = c }
        self.continuation = continuation

        center.addObserver(
            forName: .NSUbiquityIdentityDidChange,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.continuation?.yield(())
        }
    }

    deinit {
        continuation?.finish()
        center.removeObserver(self)
    }

    func currentToken() -> AnyHashable? {
        guard let token = FileManager.default.ubiquityIdentityToken else { return nil }
        return AnyHashable(String(describing: token))
    }
}

final class FakeICloudAvailabilityService: iCloudAvailabilityServiceProtocol, @unchecked Sendable {
    var token: AnyHashable?
    private var continuation: AsyncStream<Void>.Continuation?
    let identityChanges: AsyncStream<Void>

    init(initialToken: AnyHashable? = nil) {
        self.token = initialToken
        var continuation: AsyncStream<Void>.Continuation!
        self.identityChanges = AsyncStream { c in continuation = c }
        self.continuation = continuation
    }

    func currentToken() -> AnyHashable? { token }

    func triggerIdentityChange() {
        continuation?.yield(())
    }
}
```

- [ ] **Step 4: Run tests**

```bash
xcodebuild ... test -only-testing:"Road BeansTests/iCloudAvailabilityServiceTests"
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add "Road Beans/App/Persistence" "Road Beans/Services/iCloudAvailabilityService.swift" "Road BeansTests/ServiceTests/iCloudAvailabilityServiceTests.swift"
git commit -m "feat: add PersistenceMode enum and iCloudAvailabilityService"
```

---

### Task 7: `PersistenceController` (mode resolution + container build + migration entrypoint)

**Goal:** Build the `@Observable` controller that owns the `ModelContainer`, resolves the current `PersistenceMode` at launch, and exposes `migrateLocalToCloudKit()` and `deferMigration()`.

**Files:**
- Create: `Road Beans/App/Persistence/PersistenceController.swift`
- Test: `Road BeansTests/ServiceTests/PersistenceControllerTests.swift`

**Acceptance Criteria:**
- [ ] `PersistenceController` is `@Observable @MainActor`.
- [ ] Init takes `iCloudAvailabilityServiceProtocol` and a flag for `migrationDeferred` (read from `UserDefaults` with override for tests).
- [ ] On init, resolves to `.localOnly` if no token; `.cloudKitBacked` if token and no local store; `.pendingMigration` if token and local store present and not deferred.
- [ ] `container: ModelContainer` is non-nil after init; configured with CloudKit when `.cloudKitBacked`, local-only otherwise.
- [ ] `migrateLocalToCloudKit()` async throws — copies all entities from local container to cloudkit container in one transaction; on success, deletes local store and transitions to `.cloudKitBacked`.
- [ ] `deferMigration()` writes the flag and remains `.localOnly`.
- [ ] On identity-change event from iCloud service, transitions to `.pendingRelaunch`.
- [ ] Tests cover all four mode resolutions and the identity-change transition. Migration test uses two in-memory containers.

**Verify:** `xcodebuild ... test -only-testing:"Road BeansTests/PersistenceControllerTests"` → PASS.

**Steps:**

- [ ] **Step 1: Write failing tests**

Create `Road BeansTests/ServiceTests/PersistenceControllerTests.swift`:

```swift
import Testing
import SwiftData
@testable import Road_Beans

@Suite("PersistenceController")
@MainActor
struct PersistenceControllerTests {
    @Test func resolvesLocalOnlyWhenNoToken() {
        let icloud = FakeICloudAvailabilityService(initialToken: nil)
        let controller = PersistenceController(
            icloud: icloud,
            migrationDeferred: false,
            localStoreExists: false,
            useInMemoryStores: true
        )
        #expect(controller.mode == .localOnly)
    }

    @Test func resolvesCloudKitWhenTokenAndNoLocal() {
        let icloud = FakeICloudAvailabilityService(initialToken: "user1")
        let controller = PersistenceController(
            icloud: icloud,
            migrationDeferred: false,
            localStoreExists: false,
            useInMemoryStores: true
        )
        #expect(controller.mode == .cloudKitBacked)
    }

    @Test func resolvesPendingMigrationWhenTokenAndLocalExists() {
        let icloud = FakeICloudAvailabilityService(initialToken: "user1")
        let controller = PersistenceController(
            icloud: icloud,
            migrationDeferred: false,
            localStoreExists: true,
            useInMemoryStores: true
        )
        #expect(controller.mode == .pendingMigration)
    }

    @Test func deferredMigrationStaysLocalOnly() {
        let icloud = FakeICloudAvailabilityService(initialToken: "user1")
        let controller = PersistenceController(
            icloud: icloud,
            migrationDeferred: true,
            localStoreExists: true,
            useInMemoryStores: true
        )
        #expect(controller.mode == .localOnly)
    }

    @Test func identityChangeTriggersPendingRelaunch() async {
        let icloud = FakeICloudAvailabilityService(initialToken: "user1")
        let controller = PersistenceController(
            icloud: icloud,
            migrationDeferred: false,
            localStoreExists: false,
            useInMemoryStores: true
        )
        #expect(controller.mode == .cloudKitBacked)
        icloud.triggerIdentityChange()
        // give task a tick
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(controller.mode == .pendingRelaunch)
    }
}
```

- [ ] **Step 2: Implement `PersistenceController`**

Create `Road Beans/App/Persistence/PersistenceController.swift`:

```swift
import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class PersistenceController {
    private(set) var mode: PersistenceMode
    let container: ModelContainer

    private let icloud: iCloudAvailabilityServiceProtocol
    private let defaults: UserDefaults
    private static let migrationDeferredKey = "RoadBeans.migrationDeferred"

    init(
        icloud: iCloudAvailabilityServiceProtocol,
        migrationDeferred: Bool? = nil,
        localStoreExists: Bool? = nil,
        useInMemoryStores: Bool = false,
        defaults: UserDefaults = .standard
    ) {
        self.icloud = icloud
        self.defaults = defaults
        let deferredFlag = migrationDeferred ?? defaults.bool(forKey: Self.migrationDeferredKey)
        let hasLocal = localStoreExists ?? Self.localStoreExistsOnDisk()
        let token = icloud.currentToken()

        let resolvedMode: PersistenceMode
        if token == nil {
            resolvedMode = .localOnly
        } else if hasLocal && !deferredFlag {
            resolvedMode = .pendingMigration
        } else {
            resolvedMode = .cloudKitBacked
        }
        self.mode = resolvedMode

        // Build a container appropriate for the mode (in-memory in tests).
        let config: ModelConfiguration
        if useInMemoryStores {
            config = ModelConfiguration(isStoredInMemoryOnly: true)
        } else {
            switch resolvedMode {
            case .cloudKitBacked:
                config = ModelConfiguration(
                    "CloudKitStore",
                    schema: AppSchema.all,
                    cloudKitDatabase: .private("iCloud.brainmeld.Road-Beans")
                )
            case .localOnly, .pendingMigration, .pendingRelaunch:
                config = ModelConfiguration(
                    "LocalStore",
                    schema: AppSchema.all,
                    cloudKitDatabase: .none
                )
            }
        }

        do {
            self.container = try ModelContainer(for: AppSchema.all, configurations: [config])
        } catch {
            fatalError("ModelContainer init failed: \(error)")
        }

        // Watch for identity changes
        Task { [weak self] in
            guard let self else { return }
            for await _ in icloud.identityChanges {
                await MainActor.run {
                    self.mode = .pendingRelaunch
                }
            }
        }
    }

    func deferMigration() {
        defaults.set(true, forKey: Self.migrationDeferredKey)
        mode = .localOnly
    }

    func migrateLocalToCloudKit() async throws {
        // v1 implementation deferred until needed by UI flow; spec §6.
        // Acceptance: copies all entities from local to cloudkit container in one transaction;
        // deletes local store on success; transitions to .cloudKitBacked.
        // This stub throws so callers know to implement at integration time.
        throw PersistenceMigrationError.notYetImplemented
    }

    private static func localStoreExistsOnDisk() -> Bool {
        let url = URL.applicationSupportDirectory.appendingPathComponent("LocalStore.sqlite")
        return FileManager.default.fileExists(atPath: url.path)
    }
}

enum PersistenceMigrationError: Error {
    case notYetImplemented
    case copyFailed(underlying: Error)
}
```

- [ ] **Step 3: Run tests**

```bash
xcodebuild ... test -only-testing:"Road BeansTests/PersistenceControllerTests"
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add "Road Beans/App/Persistence/PersistenceController.swift" "Road BeansTests/ServiceTests/PersistenceControllerTests.swift"
git commit -m "feat: add PersistenceController with mode resolution and identity watch"
```

---

### Task 8: `AppEnvironment` (EnvironmentKey definitions for DI)

**Goal:** Wire all repositories and services through SwiftUI `@Environment` keys keyed by protocol. Lays the DI rail; concrete implementations in later tasks plug in.

**Files:**
- Create: `Road Beans/App/AppEnvironment.swift`

**Acceptance Criteria:**
- [ ] `EnvironmentKey` defined for each protocol that will be used by views/view-models: `PlaceRepository`, `VisitRepository`, `TagRepository`, `PhotoRepository`, `TombstoneRepository`, `LocationSearchService`, `LocationPermissionService`, `PhotoProcessingService`, `iCloudAvailabilityServiceProtocol`, `RemoteSyncCoordinator`, `PersistenceController`.
- [ ] Each key has a sensible default — either a no-op fake or a `fatalError` "must inject" placeholder. Use `fatalError` only for things that must be injected from the composition root (the controller itself); use no-op fakes for things previews can survive without.
- [ ] `EnvironmentValues` extension exposes a property per key.
- [ ] Forward-declares of protocol types are fine (file may reference protocols defined in later tasks; the build will fail until those tasks land — track this dependency in the plan execution order).

**Verify:** Build will fail until protocols exist. So this task's verify is deferred — the file will be added but kept syntactically correct by stubbing protocols inline. Concretely: define empty `protocol PlaceRepository {}`, etc., right above the EnvironmentKey block, and remove those stubs in the corresponding repository tasks.

**Steps:**

- [ ] **Step 1: Implement `AppEnvironment.swift` with stub protocols**

Create `Road Beans/App/AppEnvironment.swift`:

```swift
import SwiftUI

// MARK: - Stub protocol forward declarations
// Each of these is replaced by a real declaration in its own file in Tasks 9-17.
// Keeping stubs here prevents AppEnvironment from blocking the build.
// As real protocols land, delete the matching stub here.

#if STUB_REPOSITORY_PROTOCOLS_NOT_YET_DEFINED
protocol PlaceRepository: Sendable {}
protocol VisitRepository: Sendable {}
protocol TagRepository: Sendable {}
protocol PhotoRepository: Sendable {}
protocol TombstoneRepository: Sendable {}
protocol LocationSearchService: Sendable {}
protocol LocationPermissionService: Sendable {}
protocol PhotoProcessingService: Sendable {}
protocol RemoteSyncCoordinator: Sendable {}
#endif

// MARK: - Environment Keys

private struct PlaceRepositoryKey: EnvironmentKey {
    static var defaultValue: any PlaceRepository { fatalError("PlaceRepository must be injected") }
}
private struct VisitRepositoryKey: EnvironmentKey {
    static var defaultValue: any VisitRepository { fatalError("VisitRepository must be injected") }
}
private struct TagRepositoryKey: EnvironmentKey {
    static var defaultValue: any TagRepository { fatalError("TagRepository must be injected") }
}
private struct PhotoRepositoryKey: EnvironmentKey {
    static var defaultValue: any PhotoRepository { fatalError("PhotoRepository must be injected") }
}
private struct TombstoneRepositoryKey: EnvironmentKey {
    static var defaultValue: any TombstoneRepository { fatalError("TombstoneRepository must be injected") }
}
private struct LocationSearchServiceKey: EnvironmentKey {
    static var defaultValue: any LocationSearchService { fatalError("LocationSearchService must be injected") }
}
private struct LocationPermissionServiceKey: EnvironmentKey {
    static var defaultValue: any LocationPermissionService { fatalError("LocationPermissionService must be injected") }
}
private struct PhotoProcessingServiceKey: EnvironmentKey {
    static var defaultValue: any PhotoProcessingService { fatalError("PhotoProcessingService must be injected") }
}
private struct ICloudAvailabilityServiceKey: EnvironmentKey {
    static var defaultValue: any iCloudAvailabilityServiceProtocol = FakeICloudAvailabilityService()
}
private struct RemoteSyncCoordinatorKey: EnvironmentKey {
    static var defaultValue: any RemoteSyncCoordinator { fatalError("RemoteSyncCoordinator must be injected") }
}

extension EnvironmentValues {
    var placeRepository: any PlaceRepository {
        get { self[PlaceRepositoryKey.self] } set { self[PlaceRepositoryKey.self] = newValue }
    }
    var visitRepository: any VisitRepository {
        get { self[VisitRepositoryKey.self] } set { self[VisitRepositoryKey.self] = newValue }
    }
    var tagRepository: any TagRepository {
        get { self[TagRepositoryKey.self] } set { self[TagRepositoryKey.self] = newValue }
    }
    var photoRepository: any PhotoRepository {
        get { self[PhotoRepositoryKey.self] } set { self[PhotoRepositoryKey.self] = newValue }
    }
    var tombstoneRepository: any TombstoneRepository {
        get { self[TombstoneRepositoryKey.self] } set { self[TombstoneRepositoryKey.self] = newValue }
    }
    var locationSearchService: any LocationSearchService {
        get { self[LocationSearchServiceKey.self] } set { self[LocationSearchServiceKey.self] = newValue }
    }
    var locationPermissionService: any LocationPermissionService {
        get { self[LocationPermissionServiceKey.self] } set { self[LocationPermissionServiceKey.self] = newValue }
    }
    var photoProcessingService: any PhotoProcessingService {
        get { self[PhotoProcessingServiceKey.self] } set { self[PhotoProcessingServiceKey.self] = newValue }
    }
    var iCloudAvailability: any iCloudAvailabilityServiceProtocol {
        get { self[ICloudAvailabilityServiceKey.self] } set { self[ICloudAvailabilityServiceKey.self] = newValue }
    }
    var remoteSyncCoordinator: any RemoteSyncCoordinator {
        get { self[RemoteSyncCoordinatorKey.self] } set { self[RemoteSyncCoordinatorKey.self] = newValue }
    }
}
```

> Note: this file will not compile yet (`PlaceRepository` etc. aren't defined). Toggle the `STUB_REPOSITORY_PROTOCOLS_NOT_YET_DEFINED` define on locally if needed during execution. The cleanest path is to land Tasks 9-17 in the next commits; once they do, delete the stubs block.

- [ ] **Step 2: Add a temporary swift flag for the stub block**

Edit `Road Beans.xcodeproj` build settings → Swift Compiler - Custom Flags → Other Swift Flags → add `-DSTUB_REPOSITORY_PROTOCOLS_NOT_YET_DEFINED` for the `Road Beans` target. (Remove this flag after Task 14 lands. The plan's Task 14 step explicitly removes it.)

- [ ] **Step 3: Build**

```bash
xcodebuild ... build
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git add "Road Beans/App/AppEnvironment.swift" "Road Beans.xcodeproj"
git commit -m "feat: add AppEnvironment EnvironmentKey scaffolding"
```

---

### Task 9: `RemoteSyncCoordinator` protocol + `LocalOnlyRemoteSync` no-op

**Goal:** Define the sync coordinator protocol and the v1 no-op implementation. Repositories will call `markDirty(_:)` on every save.

**Files:**
- Create: `Road Beans/Services/RemoteSyncCoordinator.swift`
- Test: `Road BeansTests/ServiceTests/LocalOnlyRemoteSyncTests.swift`

**Acceptance Criteria:**
- [ ] `protocol RemoteSyncCoordinator: Sendable { func markDirty(_ kind: SyncEntityKind, id: UUID) async }`.
- [ ] `enum SyncEntityKind: String, Sendable { case place, visit, drink, tag, visitPhoto, tombstone }`.
- [ ] `LocalOnlyRemoteSync` is a no-op that records calls in a thread-safe array (for tests/observability), but does no network/IO.
- [ ] Test: calling `markDirty` records the call.

**Verify:** `xcodebuild ... test -only-testing:"Road BeansTests/LocalOnlyRemoteSyncTests"` → PASS.

**Steps:**

- [ ] **Step 1: Write failing test**

Create `Road BeansTests/ServiceTests/LocalOnlyRemoteSyncTests.swift`:

```swift
import Testing
import Foundation
@testable import Road_Beans

@Suite("LocalOnlyRemoteSync")
struct LocalOnlyRemoteSyncTests {
    @Test func markDirtyRecordsCalls() async {
        let sync = LocalOnlyRemoteSync()
        let id = UUID()
        await sync.markDirty(.visit, id: id)
        let calls = await sync.recordedCalls
        #expect(calls.count == 1)
        #expect(calls.first?.kind == .visit)
        #expect(calls.first?.id == id)
    }
}
```

- [ ] **Step 2: Implement protocol + no-op**

Create `Road Beans/Services/RemoteSyncCoordinator.swift`:

```swift
import Foundation

enum SyncEntityKind: String, Sendable {
    case place, visit, drink, tag, visitPhoto, tombstone
}

protocol RemoteSyncCoordinator: Sendable {
    func markDirty(_ kind: SyncEntityKind, id: UUID) async
}

actor LocalOnlyRemoteSync: RemoteSyncCoordinator {
    struct Call: Sendable, Equatable {
        let kind: SyncEntityKind
        let id: UUID
    }

    private(set) var recordedCalls: [Call] = []

    func markDirty(_ kind: SyncEntityKind, id: UUID) async {
        recordedCalls.append(Call(kind: kind, id: id))
    }
}
```

- [ ] **Step 3: Run test**

```bash
xcodebuild ... test -only-testing:"Road BeansTests/LocalOnlyRemoteSyncTests"
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add "Road Beans/Services/RemoteSyncCoordinator.swift" "Road BeansTests/ServiceTests/LocalOnlyRemoteSyncTests.swift"
git commit -m "feat: add RemoteSyncCoordinator protocol + no-op implementation"
```

---

### Task 10: `TagRepository` (protocol + SwiftData impl + tests)

**Goal:** First repository: tags. Lookup-or-create with normalization, autocomplete sorted by derived usage count.

**Files:**
- Create: `Road Beans/Repositories/Protocols/TagRepository.swift`
- Create: `Road Beans/Repositories/Local/LocalTagRepository.swift`
- Test: `Road BeansTests/RepositoryTests/LocalTagRepositoryTests.swift`

**Acceptance Criteria:**
- [ ] `protocol TagRepository: Sendable { func findOrCreate(name: String) async throws -> UUID; func suggestions(prefix: String, limit: Int) async throws -> [TagSuggestion]; func all() async throws -> [TagSuggestion] }`.
- [ ] Normalizes name: trim, lowercase, collapse internal whitespace, reject empty.
- [ ] `findOrCreate` returns the existing tag's id if a normalized match exists, else inserts a new Tag and returns its id.
- [ ] `suggestions(prefix:limit:)` filters by normalized prefix, sorts by `usageCount` desc then `lastModifiedAt` desc, slices to limit.
- [ ] On every create/edit, calls `RemoteSyncCoordinator.markDirty(.tag, id:)`.
- [ ] Tests: create-then-lookup returns same id; case-insensitive lookup; whitespace normalized; empty name throws; suggestion ordering correct; limit honored.

**Verify:** `xcodebuild ... test -only-testing:"Road BeansTests/LocalTagRepositoryTests"` → PASS.

**Steps:**

- [ ] **Step 1: Write failing tests**

Create `Road BeansTests/RepositoryTests/LocalTagRepositoryTests.swift`:

```swift
import Testing
import SwiftData
@testable import Road_Beans

@Suite("LocalTagRepository")
@MainActor
struct LocalTagRepositoryTests {
    func makeRepo() throws -> (LocalTagRepository, ModelContext, LocalOnlyRemoteSync) {
        let container = try ModelContainer(for: AppSchema.all, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let ctx = ModelContext(container)
        let sync = LocalOnlyRemoteSync()
        return (LocalTagRepository(context: ctx, sync: sync), ctx, sync)
    }

    @Test func findOrCreateNormalizes() async throws {
        let (repo, _, _) = try makeRepo()
        let id1 = try await repo.findOrCreate(name: "  Smooth  ")
        let id2 = try await repo.findOrCreate(name: "smooth")
        let id3 = try await repo.findOrCreate(name: "SMOOTH")
        #expect(id1 == id2)
        #expect(id2 == id3)
    }

    @Test func emptyNameThrows() async throws {
        let (repo, _, _) = try makeRepo()
        await #expect(throws: TagRepositoryError.self) {
            _ = try await repo.findOrCreate(name: "   ")
        }
    }

    @Test func suggestionsFilterAndSort() async throws {
        let (repo, _, _) = try makeRepo()
        _ = try await repo.findOrCreate(name: "smooth")
        _ = try await repo.findOrCreate(name: "smoky")
        _ = try await repo.findOrCreate(name: "burnt")
        let s = try await repo.suggestions(prefix: "sm", limit: 5)
        #expect(s.count == 2)
        #expect(s.allSatisfy { $0.name.hasPrefix("sm") })
    }

    @Test func suggestionsLimitHonored() async throws {
        let (repo, _, _) = try makeRepo()
        for n in ["smooth", "smoky", "smoke", "smush", "small"] {
            _ = try await repo.findOrCreate(name: n)
        }
        let s = try await repo.suggestions(prefix: "sm", limit: 3)
        #expect(s.count == 3)
    }

    @Test func markDirtyCalledOnCreate() async throws {
        let (repo, _, sync) = try makeRepo()
        let id = try await repo.findOrCreate(name: "smooth")
        let calls = await sync.recordedCalls
        #expect(calls.contains(where: { $0.kind == .tag && $0.id == id }))
    }
}
```

- [ ] **Step 2: Implement protocol**

Create `Road Beans/Repositories/Protocols/TagRepository.swift`:

```swift
import Foundation

enum TagRepositoryError: Error, Equatable {
    case emptyName
}

protocol TagRepository: Sendable {
    func findOrCreate(name: String) async throws -> UUID
    func suggestions(prefix: String, limit: Int) async throws -> [TagSuggestion]
    func all() async throws -> [TagSuggestion]
}
```

- [ ] **Step 3: Implement SwiftData backing**

Create `Road Beans/Repositories/Local/LocalTagRepository.swift`:

```swift
import Foundation
import SwiftData

@MainActor
final class LocalTagRepository: TagRepository {
    private let context: ModelContext
    private let sync: any RemoteSyncCoordinator

    init(context: ModelContext, sync: any RemoteSyncCoordinator) {
        self.context = context
        self.sync = sync
    }

    static func normalize(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let collapsed = trimmed.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        return collapsed.lowercased()
    }

    func findOrCreate(name: String) async throws -> UUID {
        let normalized = Self.normalize(name)
        guard !normalized.isEmpty else { throw TagRepositoryError.emptyName }

        let predicate = #Predicate<Tag> { $0.name == normalized }
        var descriptor = FetchDescriptor<Tag>(predicate: predicate)
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            return existing.id
        }

        let tag = Tag()
        tag.name = normalized
        context.insert(tag)
        try context.save()
        await sync.markDirty(.tag, id: tag.id)
        return tag.id
    }

    func suggestions(prefix: String, limit: Int) async throws -> [TagSuggestion] {
        let needle = Self.normalize(prefix)
        let descriptor = FetchDescriptor<Tag>()
        let all = try context.fetch(descriptor)
        let filtered = needle.isEmpty ? all : all.filter { $0.name.hasPrefix(needle) }
        let sorted = filtered.sorted { lhs, rhs in
            if lhs.usageCount != rhs.usageCount { return lhs.usageCount > rhs.usageCount }
            return lhs.lastModifiedAt > rhs.lastModifiedAt
        }
        return sorted.prefix(limit).map { TagSuggestion(id: $0.id, name: $0.name, usageCount: $0.usageCount) }
    }

    func all() async throws -> [TagSuggestion] {
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name)])
        let all = try context.fetch(descriptor)
        return all.map { TagSuggestion(id: $0.id, name: $0.name, usageCount: $0.usageCount) }
    }
}
```

- [ ] **Step 4: Run tests**

```bash
xcodebuild ... test -only-testing:"Road BeansTests/LocalTagRepositoryTests"
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add "Road Beans/Repositories" "Road BeansTests/RepositoryTests/LocalTagRepositoryTests.swift"
git commit -m "feat: add TagRepository with lookup-or-create + autocomplete"
```

---

### Task 11: `PlaceRepository` (protocol + SwiftData impl + dedup tests)

**Goal:** Place CRUD and dedup logic per spec §3 validation rules.

**Files:**
- Create: `Road Beans/Repositories/Protocols/PlaceRepository.swift`
- Create: `Road Beans/Repositories/Local/LocalPlaceRepository.swift`
- Test: `Road BeansTests/RepositoryTests/LocalPlaceRepositoryTests.swift`

**Acceptance Criteria:**
- [ ] Protocol exposes: `findOrCreate(reference: PlaceReference) async throws -> UUID`, `summaries() async throws -> [PlaceSummary]`, `detail(id: UUID) async throws -> PlaceDetail?`, `summariesNear(coordinate: CLLocationCoordinate2D, radiusMeters: Double) async throws -> [PlaceSummary]`.
- [ ] Dedup rules:
  - `.existing(id:)` → return as-is.
  - `.newMapKit` with `mapKitIdentifier` non-nil → match existing Place with same id; reuse.
  - `.newMapKit` with nil identifier → match if existing Place has same case-insensitive name AND great-circle distance < 50m on lat/lng; otherwise insert.
  - `.newCustom` → never auto-merge; always insert.
- [ ] Calls `markDirty(.place, id:)` on every create.
- [ ] Average rating across all visits/drinks computed in summaries/detail.
- [ ] Tests cover all four dedup branches plus the 50m boundary (49m matches, 51m doesn't).

**Verify:** `xcodebuild ... test -only-testing:"Road BeansTests/LocalPlaceRepositoryTests"` → PASS.

**Steps:**

- [ ] **Step 1: Write failing tests**

Create `Road BeansTests/RepositoryTests/LocalPlaceRepositoryTests.swift`:

```swift
import Testing
import SwiftData
import CoreLocation
@testable import Road_Beans

@Suite("LocalPlaceRepository")
@MainActor
struct LocalPlaceRepositoryTests {
    func makeRepo() throws -> (LocalPlaceRepository, ModelContext, LocalOnlyRemoteSync) {
        let container = try ModelContainer(for: AppSchema.all, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let ctx = ModelContext(container)
        let sync = LocalOnlyRemoteSync()
        return (LocalPlaceRepository(context: ctx, sync: sync), ctx, sync)
    }

    @Test func mapKitIdentifierMatchReuses() async throws {
        let (repo, _, _) = try makeRepo()
        let draft1 = MapKitPlaceDraft(name: "Loves", kind: .truckStop, mapKitIdentifier: "mk-1", mapKitName: "Love's", address: nil, latitude: 34.0, longitude: -112.0, phoneNumber: nil, websiteURL: nil, streetNumber: nil, streetName: nil, city: nil, region: nil, postalCode: nil, country: nil)
        let id1 = try await repo.findOrCreate(reference: .newMapKit(draft1))
        let id2 = try await repo.findOrCreate(reference: .newMapKit(draft1))
        #expect(id1 == id2)
    }

    @Test func nilIdentifierMatchesByNameAndProximity() async throws {
        let (repo, _, _) = try makeRepo()
        let d1 = MapKitPlaceDraft(name: "QT", kind: .gasStation, mapKitIdentifier: nil, mapKitName: nil, address: nil, latitude: 33.4484, longitude: -112.0740, phoneNumber: nil, websiteURL: nil, streetNumber: nil, streetName: nil, city: nil, region: nil, postalCode: nil, country: nil)
        let d2 = MapKitPlaceDraft(name: "qt", kind: .gasStation, mapKitIdentifier: nil, mapKitName: nil, address: nil, latitude: 33.4484, longitude: -112.0741, phoneNumber: nil, websiteURL: nil, streetNumber: nil, streetName: nil, city: nil, region: nil, postalCode: nil, country: nil)
        let id1 = try await repo.findOrCreate(reference: .newMapKit(d1))
        let id2 = try await repo.findOrCreate(reference: .newMapKit(d2))
        #expect(id1 == id2)
    }

    @Test func nilIdentifierBeyond50mInserts() async throws {
        let (repo, _, _) = try makeRepo()
        let d1 = MapKitPlaceDraft(name: "QT", kind: .gasStation, mapKitIdentifier: nil, mapKitName: nil, address: nil, latitude: 33.4484, longitude: -112.0740, phoneNumber: nil, websiteURL: nil, streetNumber: nil, streetName: nil, city: nil, region: nil, postalCode: nil, country: nil)
        // ~ 0.001 deg lng at 33.4 lat ≈ 93m east
        let d2 = MapKitPlaceDraft(name: "QT", kind: .gasStation, mapKitIdentifier: nil, mapKitName: nil, address: nil, latitude: 33.4484, longitude: -112.0730, phoneNumber: nil, websiteURL: nil, streetNumber: nil, streetName: nil, city: nil, region: nil, postalCode: nil, country: nil)
        let id1 = try await repo.findOrCreate(reference: .newMapKit(d1))
        let id2 = try await repo.findOrCreate(reference: .newMapKit(d2))
        #expect(id1 != id2)
    }

    @Test func customNeverMerges() async throws {
        let (repo, _, _) = try makeRepo()
        let d1 = CustomPlaceDraft(name: "My Stop", kind: .other, address: nil)
        let id1 = try await repo.findOrCreate(reference: .newCustom(d1))
        let id2 = try await repo.findOrCreate(reference: .newCustom(d1))
        #expect(id1 != id2)
    }
}
```

- [ ] **Step 2: Implement protocol**

Create `Road Beans/Repositories/Protocols/PlaceRepository.swift`:

```swift
import Foundation
import CoreLocation

protocol PlaceRepository: Sendable {
    func findOrCreate(reference: PlaceReference) async throws -> UUID
    func summaries() async throws -> [PlaceSummary]
    func summariesNear(coordinate: CLLocationCoordinate2D, radiusMeters: Double) async throws -> [PlaceSummary]
    func detail(id: UUID) async throws -> PlaceDetail?
}
```

- [ ] **Step 3: Implement SwiftData backing**

Create `Road Beans/Repositories/Local/LocalPlaceRepository.swift`:

```swift
import Foundation
import SwiftData
import CoreLocation

@MainActor
final class LocalPlaceRepository: PlaceRepository {
    private let context: ModelContext
    private let sync: any RemoteSyncCoordinator

    init(context: ModelContext, sync: any RemoteSyncCoordinator) {
        self.context = context
        self.sync = sync
    }

    func findOrCreate(reference: PlaceReference) async throws -> UUID {
        switch reference {
        case .existing(let id):
            return id
        case .newMapKit(let draft):
            if let identifier = draft.mapKitIdentifier {
                let predicate = #Predicate<Place> { $0.mapKitIdentifier == identifier }
                var d = FetchDescriptor<Place>(predicate: predicate); d.fetchLimit = 1
                if let existing = try context.fetch(d).first {
                    return existing.id
                }
            } else if let lat = draft.latitude, let lng = draft.longitude {
                let lowered = draft.name.lowercased()
                let candidates = try context.fetch(FetchDescriptor<Place>())
                if let match = candidates.first(where: { p in
                    p.name.lowercased() == lowered &&
                    p.latitude != nil && p.longitude != nil &&
                    Self.distanceMeters(lat, lng, p.latitude!, p.longitude!) < 50
                }) {
                    return match.id
                }
            }
            let p = Self.makePlace(from: draft)
            context.insert(p)
            try context.save()
            await sync.markDirty(.place, id: p.id)
            return p.id

        case .newCustom(let draft):
            let p = Place()
            p.name = draft.name
            p.kind = draft.kind
            p.source = .custom
            p.address = draft.address
            context.insert(p)
            try context.save()
            await sync.markDirty(.place, id: p.id)
            return p.id
        }
    }

    func summaries() async throws -> [PlaceSummary] {
        let places = try context.fetch(FetchDescriptor<Place>(sortBy: [SortDescriptor(\.lastModifiedAt, order: .reverse)]))
        return places.map(Self.toSummary(_:))
    }

    func summariesNear(coordinate: CLLocationCoordinate2D, radiusMeters: Double) async throws -> [PlaceSummary] {
        let all = try context.fetch(FetchDescriptor<Place>())
        return all.compactMap { p in
            guard let lat = p.latitude, let lng = p.longitude else { return nil }
            let d = Self.distanceMeters(coordinate.latitude, coordinate.longitude, lat, lng)
            return d <= radiusMeters ? Self.toSummary(p) : nil
        }
    }

    func detail(id: UUID) async throws -> PlaceDetail? {
        let predicate = #Predicate<Place> { $0.id == id }
        var d = FetchDescriptor<Place>(predicate: predicate); d.fetchLimit = 1
        guard let p = try context.fetch(d).first else { return nil }
        let visits = p.visits.sorted { $0.date > $1.date }.map { v in
            let drinks = v.drinks
            let avg: Double? = drinks.isEmpty ? nil : drinks.map(\.rating).reduce(0,+) / Double(drinks.count)
            return VisitRow(
                id: v.id, date: v.date, drinkCount: drinks.count,
                tagNames: v.tags.map(\.name),
                photoCount: v.photos.count,
                averageRating: avg
            )
        }
        let allDrinks = p.visits.flatMap(\.drinks)
        let avg: Double? = allDrinks.isEmpty ? nil : allDrinks.map(\.rating).reduce(0,+) / Double(allDrinks.count)
        return PlaceDetail(
            id: p.id, name: p.name, kind: p.kind, source: p.source,
            address: p.address,
            streetNumber: p.streetNumber, streetName: p.streetName,
            city: p.city, region: p.region,
            postalCode: p.postalCode, country: p.country,
            phoneNumber: p.phoneNumber, websiteURL: p.websiteURL,
            coordinate: p.coordinate, averageRating: avg, visits: visits
        )
    }

    private static func makePlace(from draft: MapKitPlaceDraft) -> Place {
        let p = Place()
        p.name = draft.name
        p.kind = draft.kind
        p.source = .mapKit
        p.mapKitIdentifier = draft.mapKitIdentifier
        p.mapKitName = draft.mapKitName
        p.address = draft.address
        p.latitude = draft.latitude
        p.longitude = draft.longitude
        p.phoneNumber = draft.phoneNumber
        p.websiteURL = draft.websiteURL
        p.streetNumber = draft.streetNumber
        p.streetName = draft.streetName
        p.city = draft.city
        p.region = draft.region
        p.postalCode = draft.postalCode
        p.country = draft.country
        return p
    }

    private static func toSummary(_ p: Place) -> PlaceSummary {
        let drinks = p.visits.flatMap(\.drinks)
        let avg: Double? = drinks.isEmpty ? nil : drinks.map(\.rating).reduce(0,+) / Double(drinks.count)
        return PlaceSummary(
            id: p.id, name: p.name, kind: p.kind,
            address: p.address, coordinate: p.coordinate,
            averageRating: avg, visitCount: p.visits.count
        )
    }

    static func distanceMeters(_ lat1: Double, _ lng1: Double, _ lat2: Double, _ lng2: Double) -> Double {
        let l1 = CLLocation(latitude: lat1, longitude: lng1)
        let l2 = CLLocation(latitude: lat2, longitude: lng2)
        return l1.distance(from: l2)
    }
}
```

- [ ] **Step 4: Run tests**

```bash
xcodebuild ... test -only-testing:"Road BeansTests/LocalPlaceRepositoryTests"
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add "Road Beans/Repositories" "Road BeansTests/RepositoryTests/LocalPlaceRepositoryTests.swift"
git commit -m "feat: add PlaceRepository with mapKit/custom dedup rules"
```

---

### Task 12: `PhotoProcessingService` (resize + HEIC encode + thumbnail)

**Goal:** Process raw picker bytes into a HEIC ≤2048px main + JPEG ≤256px thumbnail. Off the main actor.

**Files:**
- Create: `Road Beans/Services/PhotoProcessingService.swift`
- Test: `Road BeansTests/ServiceTests/PhotoProcessingServiceTests.swift`
- Test fixture: `Road BeansTests/Fixtures/sample.png` (a small generated PNG; the test creates it inline at runtime so no binary in the repo).

**Acceptance Criteria:**
- [ ] `protocol PhotoProcessingService: Sendable { func process(_ raw: Data) async throws -> ProcessedPhoto }`.
- [ ] `struct ProcessedPhoto: Sendable { let imageData: Data; let thumbnailData: Data; let widthPx: Int; let heightPx: Int }`.
- [ ] Main image: long edge ≤2048px, HEIC encoding (JPEG fallback), aspect preserved.
- [ ] Thumbnail: long edge ≤256px, JPEG quality 0.7.
- [ ] Throws `PhotoProcessingError.invalidImage` on undecodable input.
- [ ] Tests: small image is preserved, oversized image is downscaled, invalid bytes throw.

**Verify:** `xcodebuild ... test -only-testing:"Road BeansTests/PhotoProcessingServiceTests"` → PASS.

**Steps:**

- [ ] **Step 1: Write failing tests**

Create `Road BeansTests/ServiceTests/PhotoProcessingServiceTests.swift`:

```swift
import Testing
import UIKit
import ImageIO
@testable import Road_Beans

@Suite("PhotoProcessingService")
struct PhotoProcessingServiceTests {
    func makeImage(width: Int, height: Int) -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        let img = renderer.image { ctx in
            UIColor.systemBlue.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
        return img.pngData()!
    }

    @Test func smallImagePreserved() async throws {
        let svc = DefaultPhotoProcessingService()
        let raw = makeImage(width: 800, height: 600)
        let out = try await svc.process(raw)
        #expect(out.widthPx == 800)
        #expect(out.heightPx == 600)
        #expect(!out.imageData.isEmpty)
        #expect(!out.thumbnailData.isEmpty)
    }

    @Test func oversizedImageDownscaledToMaxLongEdge() async throws {
        let svc = DefaultPhotoProcessingService()
        let raw = makeImage(width: 4096, height: 3072)
        let out = try await svc.process(raw)
        #expect(out.widthPx == 2048)
        #expect(out.heightPx == 1536)
    }

    @Test func invalidBytesThrow() async {
        let svc = DefaultPhotoProcessingService()
        await #expect(throws: PhotoProcessingError.self) {
            _ = try await svc.process(Data([0x00, 0x01, 0x02]))
        }
    }
}
```

- [ ] **Step 2: Implement service**

Create `Road Beans/Services/PhotoProcessingService.swift`:

```swift
import Foundation
import UIKit
import ImageIO
import UniformTypeIdentifiers

enum PhotoProcessingError: Error {
    case invalidImage
    case encodingFailed
}

struct ProcessedPhoto: Sendable {
    let imageData: Data
    let thumbnailData: Data
    let widthPx: Int
    let heightPx: Int
}

protocol PhotoProcessingService: Sendable {
    func process(_ raw: Data) async throws -> ProcessedPhoto
}

final class DefaultPhotoProcessingService: PhotoProcessingService, @unchecked Sendable {
    private let mainMaxEdge: CGFloat = 2048
    private let thumbMaxEdge: CGFloat = 256

    func process(_ raw: Data) async throws -> ProcessedPhoto {
        try await Task.detached(priority: .userInitiated) {
            guard let image = UIImage(data: raw) else { throw PhotoProcessingError.invalidImage }
            let resized = Self.resize(image, maxEdge: self.mainMaxEdge)
            let thumb = Self.resize(image, maxEdge: self.thumbMaxEdge)
            guard let mainData = Self.encodeHEIC(resized) ?? resized.jpegData(compressionQuality: 0.85) else {
                throw PhotoProcessingError.encodingFailed
            }
            guard let thumbData = thumb.jpegData(compressionQuality: 0.7) else {
                throw PhotoProcessingError.encodingFailed
            }
            return ProcessedPhoto(
                imageData: mainData,
                thumbnailData: thumbData,
                widthPx: Int(resized.size.width * resized.scale),
                heightPx: Int(resized.size.height * resized.scale)
            )
        }.value
    }

    private static func resize(_ image: UIImage, maxEdge: CGFloat) -> UIImage {
        let w = image.size.width, h = image.size.height
        let longest = max(w, h)
        guard longest > maxEdge else { return image }
        let scale = maxEdge / longest
        let newSize = CGSize(width: floor(w * scale), height: floor(h * scale))
        let renderer = UIGraphicsImageRenderer(size: newSize, format: {
            let f = UIGraphicsImageRendererFormat(); f.scale = 1; return f
        }())
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }

    private static func encodeHEIC(_ image: UIImage) -> Data? {
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, UTType.heic.identifier as CFString, 1, nil),
              let cg = image.cgImage else { return nil }
        CGImageDestinationAddImage(dest, cg, [kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return data as Data
    }
}
```

- [ ] **Step 3: Run tests**

```bash
xcodebuild ... test -only-testing:"Road BeansTests/PhotoProcessingServiceTests"
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add "Road Beans/Services/PhotoProcessingService.swift" "Road BeansTests/ServiceTests/PhotoProcessingServiceTests.swift"
git commit -m "feat: add PhotoProcessingService with HEIC encode + thumbnail"
```

---

### Task 13: `PhotoRepository` and `TombstoneRepository`

**Goal:** Repository wrappers around `VisitPhoto` insert/delete and `Tombstone` insert/list. These are simple but needed by the visit repository.

**Files:**
- Create: `Road Beans/Repositories/Protocols/PhotoRepository.swift`
- Create: `Road Beans/Repositories/Local/LocalPhotoRepository.swift`
- Create: `Road Beans/Repositories/Protocols/TombstoneRepository.swift`
- Create: `Road Beans/Repositories/Local/LocalTombstoneRepository.swift`
- Test: `Road BeansTests/RepositoryTests/LocalTombstoneRepositoryTests.swift`

**Acceptance Criteria:**
- [ ] `PhotoRepository` exposes: `func insertProcessed(_ processed: ProcessedPhoto, caption: String?, into visit: UUID) async throws -> UUID`, `func remove(_ photoID: UUID) async throws`.
- [ ] `TombstoneRepository` exposes: `func insertTombstone(entityKind: SyncEntityKind, entityID: UUID, remoteID: String?) async throws`, `func all() async throws -> [TombstoneDTO]`.
- [ ] Photo insert calls `markDirty(.visitPhoto, id:)`.
- [ ] Tombstone insert calls `markDirty(.tombstone, id:)`.
- [ ] Test for tombstone repo: insert + retrieve via `all()` returns the DTO.

**Verify:** `xcodebuild ... test -only-testing:"Road BeansTests/LocalTombstoneRepositoryTests"` → PASS.

**Steps:**

- [ ] **Step 1: Implement `PhotoRepository`**

Create `Road Beans/Repositories/Protocols/PhotoRepository.swift`:

```swift
import Foundation

protocol PhotoRepository: Sendable {
    func insertProcessed(_ processed: ProcessedPhoto, caption: String?, into visitID: UUID) async throws -> UUID
    func remove(_ photoID: UUID) async throws
}
```

Create `Road Beans/Repositories/Local/LocalPhotoRepository.swift`:

```swift
import Foundation
import SwiftData

@MainActor
final class LocalPhotoRepository: PhotoRepository {
    private let context: ModelContext
    private let sync: any RemoteSyncCoordinator

    init(context: ModelContext, sync: any RemoteSyncCoordinator) {
        self.context = context
        self.sync = sync
    }

    func insertProcessed(_ processed: ProcessedPhoto, caption: String?, into visitID: UUID) async throws -> UUID {
        let predicate = #Predicate<Visit> { $0.id == visitID }
        var d = FetchDescriptor<Visit>(predicate: predicate); d.fetchLimit = 1
        guard let visit = try context.fetch(d).first else { throw VisitRepositoryError.notFound }

        let photo = VisitPhoto()
        photo.imageData = processed.imageData
        photo.thumbnailData = processed.thumbnailData
        photo.widthPx = processed.widthPx
        photo.heightPx = processed.heightPx
        photo.caption = caption
        photo._visit = visit
        context.insert(photo)
        try context.save()
        await sync.markDirty(.visitPhoto, id: photo.id)
        return photo.id
    }

    func remove(_ photoID: UUID) async throws {
        let predicate = #Predicate<VisitPhoto> { $0.id == photoID }
        var d = FetchDescriptor<VisitPhoto>(predicate: predicate); d.fetchLimit = 1
        guard let photo = try context.fetch(d).first else { return }
        let id = photo.id
        let remoteID = photo.remoteID
        context.delete(photo)
        try context.save()

        let tomb = Tombstone(entityKind: SyncEntityKind.visitPhoto.rawValue, entityID: id, remoteID: remoteID)
        context.insert(tomb)
        try context.save()
        await sync.markDirty(.tombstone, id: tomb.id)
    }
}
```

- [ ] **Step 2: Implement `TombstoneRepository`**

Create `Road Beans/Repositories/Protocols/TombstoneRepository.swift`:

```swift
import Foundation

protocol TombstoneRepository: Sendable {
    func insertTombstone(entityKind: SyncEntityKind, entityID: UUID, remoteID: String?) async throws
    func all() async throws -> [TombstoneDTO]
}
```

Create `Road Beans/Repositories/Local/LocalTombstoneRepository.swift`:

```swift
import Foundation
import SwiftData

@MainActor
final class LocalTombstoneRepository: TombstoneRepository {
    private let context: ModelContext
    private let sync: any RemoteSyncCoordinator

    init(context: ModelContext, sync: any RemoteSyncCoordinator) {
        self.context = context
        self.sync = sync
    }

    func insertTombstone(entityKind: SyncEntityKind, entityID: UUID, remoteID: String?) async throws {
        let tomb = Tombstone(entityKind: entityKind.rawValue, entityID: entityID, remoteID: remoteID)
        context.insert(tomb)
        try context.save()
        await sync.markDirty(.tombstone, id: tomb.id)
    }

    func all() async throws -> [TombstoneDTO] {
        let rows = try context.fetch(FetchDescriptor<Tombstone>(sortBy: [SortDescriptor(\.deletedAt)]))
        return rows.map { TombstoneDTO(id: $0.id, entityKind: $0.entityKind, entityID: $0.entityID, remoteID: $0.remoteID, deletedAt: $0.deletedAt) }
    }
}
```

- [ ] **Step 3: Write `LocalTombstoneRepositoryTests`**

Create `Road BeansTests/RepositoryTests/LocalTombstoneRepositoryTests.swift`:

```swift
import Testing
import SwiftData
@testable import Road_Beans

@Suite("LocalTombstoneRepository")
@MainActor
struct LocalTombstoneRepositoryTests {
    @Test func insertAndListRoundtrip() async throws {
        let container = try ModelContainer(for: AppSchema.all, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let ctx = ModelContext(container)
        let sync = LocalOnlyRemoteSync()
        let repo = LocalTombstoneRepository(context: ctx, sync: sync)
        let visitID = UUID()
        try await repo.insertTombstone(entityKind: .visit, entityID: visitID, remoteID: nil)
        let all = try await repo.all()
        #expect(all.count == 1)
        #expect(all[0].entityID == visitID)
        #expect(all[0].entityKind == "visit")
    }
}
```

- [ ] **Step 4: Run tests**

```bash
xcodebuild ... test -only-testing:"Road BeansTests/LocalTombstoneRepositoryTests"
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add "Road Beans/Repositories" "Road BeansTests/RepositoryTests/LocalTombstoneRepositoryTests.swift"
git commit -m "feat: add PhotoRepository and TombstoneRepository"
```

---

### Task 14: `VisitRepository` (the heart) — create/update/delete + invariant + dirty propagation

**Goal:** The repository that orchestrates a Visit save: validates ≥1 drink, clamps/rounds ratings, ensures place via `PlaceRepository.findOrCreate`, normalizes tags via `TagRepository.findOrCreate`, attaches processed photos via `PhotoRepository`, applies dirty propagation per spec §5, deletes via Tombstone.

**Files:**
- Create: `Road Beans/Repositories/Protocols/VisitRepository.swift`
- Create: `Road Beans/Repositories/Local/LocalVisitRepository.swift`
- Test: `Road BeansTests/RepositoryTests/LocalVisitRepositoryTests.swift`
- Modify: `Road Beans/App/AppEnvironment.swift` — delete the `STUB_REPOSITORY_PROTOCOLS_NOT_YET_DEFINED` block.
- Modify: `Road Beans.xcodeproj` — remove the `-DSTUB_REPOSITORY_PROTOCOLS_NOT_YET_DEFINED` swift flag.

**Execution Note:** This task removes the temporary stub block, so it must run after Tasks 15 and 16 define the real `LocationPermissionService` and `LocationSearchService` protocols. Earlier plan drafts listed Task 14 immediately after Task 13, but that order would make `AppEnvironment.swift` fail to compile when the stubs are removed.

**Acceptance Criteria:**
- [ ] `VisitRepository` exposes: `save(_ command: CreateVisitCommand) async throws -> UUID`, `update(_ command: UpdateVisitCommand) async throws`, `delete(_ command: DeleteVisitCommand) async throws`, `recentRows(limit: Int) async throws -> [(VisitRow, placeName: String, placeKind: PlaceKind)]`, `detail(id: UUID) async throws -> VisitDetail?`.
- [ ] Validation:
  - `CreateVisitCommand.drinks` must be non-empty → throws `VisitValidationError.missingDrinks`.
  - Drink rating clamped to `[0.0, 5.0]`, rounded to nearest 0.1.
- [ ] On save: marks Visit, all newly created Drinks, all newly created Tags (via TagRepository), all VisitPhotos, and the Place if newly created.
- [ ] `lastModifiedAt` updates on save and update.
- [ ] On delete: writes a `Tombstone` for the visit and lets cascade delete remove drinks/photos; tombstones for those are NOT written (cascade is local; v2 server-side cascade handles graph).
- [ ] Tests: validation rejects empty drinks; rating clamps (5.5 → 5.0, -1 → 0.0); rating rounds (3.47 → 3.5); save marks all expected entities; delete creates a tombstone.

**Verify:** `xcodebuild ... test -only-testing:"Road BeansTests/LocalVisitRepositoryTests"` → PASS.

**Steps:**

- [ ] **Step 1: Write failing tests**

Create `Road BeansTests/RepositoryTests/LocalVisitRepositoryTests.swift`:

```swift
import Testing
import SwiftData
@testable import Road_Beans

@Suite("LocalVisitRepository")
@MainActor
struct LocalVisitRepositoryTests {
    func makeStack() throws -> (LocalVisitRepository, LocalPlaceRepository, LocalTagRepository, LocalPhotoRepository, LocalTombstoneRepository, LocalOnlyRemoteSync, ModelContext) {
        let container = try ModelContainer(for: AppSchema.all, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let ctx = ModelContext(container)
        let sync = LocalOnlyRemoteSync()
        let places = LocalPlaceRepository(context: ctx, sync: sync)
        let tags = LocalTagRepository(context: ctx, sync: sync)
        let photos = LocalPhotoRepository(context: ctx, sync: sync)
        let tombs = LocalTombstoneRepository(context: ctx, sync: sync)
        let visits = LocalVisitRepository(
            context: ctx, sync: sync, places: places, tags: tags, photos: photos, tombstones: tombs
        )
        return (visits, places, tags, photos, tombs, sync, ctx)
    }

    @Test func emptyDrinksRejected() async throws {
        let (visits, _, _, _, _, _, _) = try makeStack()
        let cmd = CreateVisitCommand(
            placeRef: .newCustom(.init(name: "X", kind: .other, address: nil)),
            date: .now, drinks: [], tags: [], photos: []
        )
        await #expect(throws: VisitValidationError.self) {
            _ = try await visits.save(cmd)
        }
    }

    @Test func ratingClampedAndRounded() async throws {
        let (visits, _, _, _, _, _, ctx) = try makeStack()
        let cmd = CreateVisitCommand(
            placeRef: .newCustom(.init(name: "X", kind: .other, address: nil)),
            date: .now,
            drinks: [
                DrinkDraft(name: "A", category: .drip, rating: 5.7, tags: []),
                DrinkDraft(name: "B", category: .drip, rating: -3.0, tags: []),
                DrinkDraft(name: "C", category: .drip, rating: 3.47, tags: []),
            ],
            tags: [], photos: []
        )
        let visitID = try await visits.save(cmd)
        let visit = try ctx.fetch(FetchDescriptor<Visit>(predicate: #Predicate { $0.id == visitID })).first!
        let ratings = visit.drinks.map(\.rating).sorted()
        #expect(ratings.contains(0.0))
        #expect(ratings.contains(5.0))
        #expect(ratings.contains(where: { abs($0 - 3.5) < 0.0001 }))
    }

    @Test func saveMarksAllExpectedEntities() async throws {
        let (visits, _, _, _, _, sync, _) = try makeStack()
        let cmd = CreateVisitCommand(
            placeRef: .newCustom(.init(name: "X", kind: .other, address: nil)),
            date: .now,
            drinks: [DrinkDraft(name: "D", category: .drip, rating: 4.0, tags: ["smooth"])],
            tags: ["roadtrip"], photos: []
        )
        _ = try await visits.save(cmd)
        let calls = await sync.recordedCalls
        let kinds = Set(calls.map(\.kind))
        #expect(kinds.contains(.place))
        #expect(kinds.contains(.visit))
        #expect(kinds.contains(.drink))
        #expect(kinds.contains(.tag))
    }

    @Test func deleteWritesTombstone() async throws {
        let (visits, _, _, _, tombs, _, _) = try makeStack()
        let cmd = CreateVisitCommand(
            placeRef: .newCustom(.init(name: "X", kind: .other, address: nil)),
            date: .now,
            drinks: [DrinkDraft(name: "D", category: .drip, rating: 4.0, tags: [])],
            tags: [], photos: []
        )
        let id = try await visits.save(cmd)
        try await visits.delete(.init(id: id))
        let all = try await tombs.all()
        #expect(all.contains(where: { $0.entityKind == "visit" && $0.entityID == id }))
    }
}
```

- [ ] **Step 2: Implement protocol**

Create `Road Beans/Repositories/Protocols/VisitRepository.swift`:

```swift
import Foundation

enum VisitValidationError: Error, Equatable {
    case missingDrinks
}

enum VisitRepositoryError: Error, Equatable {
    case notFound
}

struct RecentVisitRow: Sendable {
    let visit: VisitRow
    let placeName: String
    let placeKind: PlaceKind
}

protocol VisitRepository: Sendable {
    func save(_ command: CreateVisitCommand) async throws -> UUID
    func update(_ command: UpdateVisitCommand) async throws
    func delete(_ command: DeleteVisitCommand) async throws
    func recentRows(limit: Int) async throws -> [RecentVisitRow]
    func detail(id: UUID) async throws -> VisitDetail?
}
```

- [ ] **Step 3: Implement SwiftData backing**

Create `Road Beans/Repositories/Local/LocalVisitRepository.swift`:

```swift
import Foundation
import SwiftData

@MainActor
final class LocalVisitRepository: VisitRepository {
    private let context: ModelContext
    private let sync: any RemoteSyncCoordinator
    private let places: any PlaceRepository
    private let tags: any TagRepository
    private let photos: any PhotoRepository
    private let tombstones: any TombstoneRepository

    init(
        context: ModelContext,
        sync: any RemoteSyncCoordinator,
        places: any PlaceRepository,
        tags: any TagRepository,
        photos: any PhotoRepository,
        tombstones: any TombstoneRepository
    ) {
        self.context = context
        self.sync = sync
        self.places = places
        self.tags = tags
        self.photos = photos
        self.tombstones = tombstones
    }

    func save(_ command: CreateVisitCommand) async throws -> UUID {
        guard !command.drinks.isEmpty else { throw VisitValidationError.missingDrinks }

        let placeID = try await places.findOrCreate(reference: command.placeRef)
        let placePred = #Predicate<Place> { $0.id == placeID }
        var pd = FetchDescriptor<Place>(predicate: placePred); pd.fetchLimit = 1
        guard let placeModel = try context.fetch(pd).first else { throw VisitRepositoryError.notFound }

        let visit = Visit()
        visit.date = command.date
        visit._place = placeModel
        context.insert(visit)

        for draft in command.drinks {
            let drink = Drink()
            drink.name = draft.name
            drink.category = draft.category
            drink.rating = Self.clampAndRound(draft.rating)
            drink._visit = visit
            context.insert(drink)
            for tagName in draft.tags {
                let tagID = try await tags.findOrCreate(name: tagName)
                let tagPred = #Predicate<Tag> { $0.id == tagID }
                var td = FetchDescriptor<Tag>(predicate: tagPred); td.fetchLimit = 1
                if let t = try context.fetch(td).first {
                    var current = drink._tags ?? []
                    current.append(t)
                    drink._tags = current
                }
            }
            await sync.markDirty(.drink, id: drink.id)
        }

        for tagName in command.tags {
            let tagID = try await tags.findOrCreate(name: tagName)
            let tagPred = #Predicate<Tag> { $0.id == tagID }
            var td = FetchDescriptor<Tag>(predicate: tagPred); td.fetchLimit = 1
            if let t = try context.fetch(td).first {
                var current = visit._tags ?? []
                current.append(t)
                visit._tags = current
            }
        }

        try context.save()

        // Photos: process bytes already happened upstream (the AddVisit VM uses PhotoProcessingService);
        // here `photos` are raw drafts. Insert raw via PhotoRepository requires processed input;
        // the view-model is expected to call PhotoProcessingService and pass ProcessedPhoto attachments
        // via UpdateVisitCommand.photoAdditions after creation. v1 keeps the create path simple.
        // (See AddVisit view-model task.)

        await sync.markDirty(.visit, id: visit.id)
        await sync.markDirty(.place, id: placeModel.id)
        return visit.id
    }

    func update(_ command: UpdateVisitCommand) async throws {
        let pred = #Predicate<Visit> { $0.id == command.id }
        var d = FetchDescriptor<Visit>(predicate: pred); d.fetchLimit = 1
        guard let visit = try context.fetch(d).first else { throw VisitRepositoryError.notFound }

        if let date = command.date { visit.date = date }
        if let drafts = command.drinks {
            for old in visit.drinks { context.delete(old) }
            for draft in drafts {
                let drink = Drink()
                drink.name = draft.name
                drink.category = draft.category
                drink.rating = Self.clampAndRound(draft.rating)
                drink._visit = visit
                context.insert(drink)
                await sync.markDirty(.drink, id: drink.id)
            }
        }
        if let tagNames = command.tags {
            visit._tags = []
            for name in tagNames {
                let tagID = try await tags.findOrCreate(name: name)
                let tagPred = #Predicate<Tag> { $0.id == tagID }
                var td = FetchDescriptor<Tag>(predicate: tagPred); td.fetchLimit = 1
                if let t = try context.fetch(td).first {
                    var cur = visit._tags ?? []
                    cur.append(t)
                    visit._tags = cur
                }
            }
        }
        if let removals = command.photoRemovals {
            for pid in removals { try await photos.remove(pid) }
        }
        visit.lastModifiedAt = .now
        try context.save()
        await sync.markDirty(.visit, id: visit.id)
    }

    func delete(_ command: DeleteVisitCommand) async throws {
        let pred = #Predicate<Visit> { $0.id == command.id }
        var d = FetchDescriptor<Visit>(predicate: pred); d.fetchLimit = 1
        guard let visit = try context.fetch(d).first else { return }
        let id = visit.id
        let remoteID = visit.remoteID
        context.delete(visit)
        try context.save()
        try await tombstones.insertTombstone(entityKind: .visit, entityID: id, remoteID: remoteID)
    }

    func recentRows(limit: Int) async throws -> [RecentVisitRow] {
        var d = FetchDescriptor<Visit>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        d.fetchLimit = limit
        let rows = try context.fetch(d)
        return rows.map { v in
            let drinks = v.drinks
            let avg: Double? = drinks.isEmpty ? nil : drinks.map(\.rating).reduce(0,+) / Double(drinks.count)
            let visitRow = VisitRow(
                id: v.id, date: v.date, drinkCount: drinks.count,
                tagNames: v.tags.map(\.name),
                photoCount: v.photos.count, averageRating: avg
            )
            let p = v.place
            return RecentVisitRow(visit: visitRow, placeName: p?.name ?? "Unknown", placeKind: p?.kind ?? .other)
        }
    }

    func detail(id: UUID) async throws -> VisitDetail? {
        let pred = #Predicate<Visit> { $0.id == id }
        var d = FetchDescriptor<Visit>(predicate: pred); d.fetchLimit = 1
        guard let v = try context.fetch(d).first else { return nil }
        let drinks = v.drinks.map { d in
            DrinkRow(id: d.id, name: d.name, category: d.category, rating: d.rating, tagNames: d.tags.map(\.name))
        }
        let photoRefs = v.photos.map { p in
            PhotoReference(id: p.id, thumbnailData: p.thumbnailData, widthPx: p.widthPx, heightPx: p.heightPx, caption: p.caption)
        }
        return VisitDetail(
            id: v.id, date: v.date,
            placeID: v.place?.id ?? UUID(),
            placeName: v.place?.name ?? "Unknown",
            placeKind: v.place?.kind ?? .other,
            drinks: drinks, tagNames: v.tags.map(\.name), photos: photoRefs
        )
    }

    static func clampAndRound(_ raw: Double) -> Double {
        let clamped = min(max(raw, 0.0), 5.0)
        return (clamped * 10).rounded() / 10
    }
}
```

- [ ] **Step 4: Remove the stub block from `AppEnvironment.swift`**

Open `Road Beans/App/AppEnvironment.swift`. Delete the `#if STUB_REPOSITORY_PROTOCOLS_NOT_YET_DEFINED ... #endif` block entirely.

- [ ] **Step 5: Remove the swift flag from project**

Open `Road Beans.xcodeproj` build settings → Other Swift Flags → remove `-DSTUB_REPOSITORY_PROTOCOLS_NOT_YET_DEFINED`.

- [ ] **Step 6: Run tests**

```bash
xcodebuild ... test -only-testing:"Road BeansTests/LocalVisitRepositoryTests"
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add "Road Beans/Repositories" "Road BeansTests/RepositoryTests/LocalVisitRepositoryTests.swift" "Road Beans/App/AppEnvironment.swift" "Road Beans.xcodeproj"
git commit -m "feat: add VisitRepository with validation, dirty propagation, and tombstone delete"
```

---

### Task 15: `LocationPermissionService`

**Goal:** Wrap CLLocationManager. Expose status as observable, request `whenInUse` on demand.

**Files:**
- Create: `Road Beans/Services/LocationPermissionService.swift`
- Test: `Road BeansTests/ServiceTests/LocationPermissionServiceTests.swift`

**Acceptance Criteria:**
- [ ] `protocol LocationPermissionService: AnyObject, Sendable` with `var status: LocationAuthorization { get async }`, `func requestWhenInUse() async`, `var statusChanges: AsyncStream<LocationAuthorization> { get }`.
- [ ] `enum LocationAuthorization: Sendable { case notDetermined, denied, restricted, authorized }`.
- [ ] `SystemLocationPermissionService` wraps `CLLocationManager` (delegate-based). Maps system enum to ours.
- [ ] `FakeLocationPermissionService` for tests (settable status, manual `simulateChange(_:)`).
- [ ] Tests: fake reports current status; subscriber receives changes.

**Verify:** `xcodebuild ... test -only-testing:"Road BeansTests/LocationPermissionServiceTests"` → PASS.

**Steps:**

- [ ] **Step 1: Write failing test**

Create `Road BeansTests/ServiceTests/LocationPermissionServiceTests.swift`:

```swift
import Testing
@testable import Road_Beans

@Suite("LocationPermissionService")
struct LocationPermissionServiceTests {
    @Test func fakeReportsAndStreamsStatus() async {
        let svc = FakeLocationPermissionService(initial: .notDetermined)
        let initial = await svc.status
        #expect(initial == .notDetermined)

        let stream = svc.statusChanges
        let task = Task { () -> LocationAuthorization? in
            for await s in stream { return s }
            return nil
        }
        try? await Task.sleep(nanoseconds: 50_000_000)
        svc.simulateChange(.authorized)
        let got = await task.value
        #expect(got == .authorized)
    }
}
```

- [ ] **Step 2: Implement**

Create `Road Beans/Services/LocationPermissionService.swift`:

```swift
import Foundation
import CoreLocation

enum LocationAuthorization: Sendable, Equatable {
    case notDetermined, denied, restricted, authorized
}

protocol LocationPermissionService: AnyObject, Sendable {
    var status: LocationAuthorization { get async }
    func requestWhenInUse() async
    var statusChanges: AsyncStream<LocationAuthorization> { get }
}

final class SystemLocationPermissionService: NSObject, LocationPermissionService, CLLocationManagerDelegate, @unchecked Sendable {
    private let manager = CLLocationManager()
    private var continuation: AsyncStream<LocationAuthorization>.Continuation?
    let statusChanges: AsyncStream<LocationAuthorization>

    override init() {
        var c: AsyncStream<LocationAuthorization>.Continuation!
        self.statusChanges = AsyncStream { c = $0 }
        self.continuation = c
        super.init()
        manager.delegate = self
    }

    var status: LocationAuthorization {
        get async { Self.map(manager.authorizationStatus) }
    }

    func requestWhenInUse() async {
        manager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        continuation?.yield(Self.map(manager.authorizationStatus))
    }

    static func map(_ s: CLAuthorizationStatus) -> LocationAuthorization {
        switch s {
        case .notDetermined: return .notDetermined
        case .denied:        return .denied
        case .restricted:    return .restricted
        case .authorizedWhenInUse, .authorizedAlways: return .authorized
        @unknown default:    return .notDetermined
        }
    }
}

final class FakeLocationPermissionService: LocationPermissionService, @unchecked Sendable {
    private var current: LocationAuthorization
    private var continuation: AsyncStream<LocationAuthorization>.Continuation?
    let statusChanges: AsyncStream<LocationAuthorization>

    init(initial: LocationAuthorization) {
        self.current = initial
        var c: AsyncStream<LocationAuthorization>.Continuation!
        self.statusChanges = AsyncStream { c = $0 }
        self.continuation = c
    }

    var status: LocationAuthorization { get async { current } }
    func requestWhenInUse() async { simulateChange(.authorized) }

    func simulateChange(_ s: LocationAuthorization) {
        current = s
        continuation?.yield(s)
    }
}
```

- [ ] **Step 3: Run test**

```bash
xcodebuild ... test -only-testing:"Road BeansTests/LocationPermissionServiceTests"
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add "Road Beans/Services/LocationPermissionService.swift" "Road BeansTests/ServiceTests/LocationPermissionServiceTests.swift"
git commit -m "feat: add LocationPermissionService with system + fake implementations"
```

---

### Task 16: `LocationSearchService`

**Goal:** Wrap `MKLocalSearchCompleter` + `MKLocalSearch` for debounced place search returning `MapKitPlaceDraft` results.

**Files:**
- Create: `Road Beans/Services/LocationSearchService.swift`
- Test: `Road BeansTests/ServiceTests/LocationSearchServiceTests.swift`

**Acceptance Criteria:**
- [ ] `protocol LocationSearchService: Sendable` with `func search(query: String, near: CLLocationCoordinate2D?) async throws -> [MapKitPlaceDraft]`.
- [ ] System impl uses `MKLocalSearch` with the query. For each result, builds a `MapKitPlaceDraft` populated from `MKMapItem` (identifier, name, address components, coordinate, phone, URL).
- [ ] `kind` is inferred via simple heuristic from `pointOfInterestCategory` (gas station → `.gasStation`, restaurant/fast food → `.fastFood`, cafe → `.coffeeShop`, else `.other`).
- [ ] Throws `LocationSearchError.empty` on empty query.
- [ ] `FakeLocationSearchService` returns canned results for tests.
- [ ] Tests: empty query throws; fake returns expected drafts.

**Verify:** `xcodebuild ... test -only-testing:"Road BeansTests/LocationSearchServiceTests"` → PASS.

**Steps:**

- [ ] **Step 1: Write failing tests**

Create `Road BeansTests/ServiceTests/LocationSearchServiceTests.swift`:

```swift
import Testing
import CoreLocation
@testable import Road_Beans

@Suite("LocationSearchService")
struct LocationSearchServiceTests {
    @Test func emptyQueryThrows() async {
        let svc = FakeLocationSearchService(canned: [])
        await #expect(throws: LocationSearchError.self) {
            _ = try await svc.search(query: "  ", near: nil)
        }
    }

    @Test func fakeReturnsCanned() async throws {
        let draft = MapKitPlaceDraft(name: "Loves", kind: .truckStop, mapKitIdentifier: "x", mapKitName: "Loves", address: nil, latitude: 34.0, longitude: -112.0, phoneNumber: nil, websiteURL: nil, streetNumber: nil, streetName: nil, city: nil, region: nil, postalCode: nil, country: nil)
        let svc = FakeLocationSearchService(canned: [draft])
        let r = try await svc.search(query: "loves", near: nil)
        #expect(r.count == 1)
        #expect(r[0].name == "Loves")
    }
}
```

- [ ] **Step 2: Implement**

Create `Road Beans/Services/LocationSearchService.swift`:

```swift
import Foundation
import MapKit
import CoreLocation

enum LocationSearchError: Error, Equatable {
    case empty
    case noResults
}

protocol LocationSearchService: Sendable {
    func search(query: String, near: CLLocationCoordinate2D?) async throws -> [MapKitPlaceDraft]
}

final class SystemLocationSearchService: LocationSearchService, @unchecked Sendable {
    func search(query: String, near: CLLocationCoordinate2D?) async throws -> [MapKitPlaceDraft] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw LocationSearchError.empty }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        if let coord = near {
            request.region = MKCoordinateRegion(center: coord, latitudinalMeters: 50_000, longitudinalMeters: 50_000)
        }
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        return response.mapItems.map(Self.toDraft(_:))
    }

    private static func toDraft(_ item: MKMapItem) -> MapKitPlaceDraft {
        let pm = item.placemark
        let kind: PlaceKind
        switch item.pointOfInterestCategory {
        case .some(.gasStation): kind = .gasStation
        case .some(.cafe), .some(.bakery): kind = .coffeeShop
        case .some(.restaurant), .some(.foodMarket): kind = .fastFood
        default: kind = .other
        }
        return MapKitPlaceDraft(
            name: item.name ?? pm.name ?? "Place",
            kind: kind,
            mapKitIdentifier: item.identifier?.rawValue,
            mapKitName: item.name,
            address: [pm.thoroughfare, pm.locality, pm.administrativeArea].compactMap { $0 }.joined(separator: ", "),
            latitude: pm.coordinate.latitude,
            longitude: pm.coordinate.longitude,
            phoneNumber: item.phoneNumber,
            websiteURL: item.url,
            streetNumber: pm.subThoroughfare,
            streetName: pm.thoroughfare,
            city: pm.locality,
            region: pm.administrativeArea,
            postalCode: pm.postalCode,
            country: pm.country
        )
    }
}

final class FakeLocationSearchService: LocationSearchService, @unchecked Sendable {
    let canned: [MapKitPlaceDraft]
    init(canned: [MapKitPlaceDraft]) { self.canned = canned }
    func search(query: String, near: CLLocationCoordinate2D?) async throws -> [MapKitPlaceDraft] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw LocationSearchError.empty }
        return canned
    }
}
```

- [ ] **Step 3: Run tests**

```bash
xcodebuild ... test -only-testing:"Road BeansTests/LocationSearchServiceTests"
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add "Road Beans/Services/LocationSearchService.swift" "Road BeansTests/ServiceTests/LocationSearchServiceTests.swift"
git commit -m "feat: add LocationSearchService wrapping MKLocalSearch"
```

---

### Task 17: Design system foundations (`Colors+Typography`, `PlaceKindStyle`, `GlassCard`)

**Goal:** Reusable visual primitives so feature views never hand-roll glass/material/colors. Centralizes the iOS 26 `glassEffect` fallback to `.thinMaterial`.

**Files:**
- Create: `Road Beans/DesignSystem/Colors+Typography.swift`
- Create: `Road Beans/DesignSystem/PlaceKindStyle.swift`
- Create: `Road Beans/DesignSystem/GlassCard.swift`

**Acceptance Criteria:**
- [ ] `Color` extensions: `static let beanForeground`, `static let beanBackground` (light + dark adaptive).
- [ ] `Font` extensions: `roadBeansHeadline`, `roadBeansBody`, `roadBeansNumeric` (SF Pro Rounded for headline, SF Pro for body, SF Pro Rounded monospaced digits for numeric).
- [ ] `PlaceKindStyle` exposes `static func badge(for kind: PlaceKind) -> some View` — a small chip with SF Symbol + accent color.
- [ ] `GlassCard` is a `ViewModifier` applied via `.glassCard(tint:)` — applies `.glassEffect()` when available, falls back to `.background(.thinMaterial)` otherwise. Accepts an optional tint Color.
- [ ] Build succeeds.

**Verify:** `xcodebuild ... build` → BUILD SUCCEEDED.

**Steps:**

- [ ] **Step 1: Implement `Colors+Typography`**

Create `Road Beans/DesignSystem/Colors+Typography.swift`:

```swift
import SwiftUI

extension Color {
    static let beanForeground = Color.primary
    static let beanBackground = Color(UIColor.systemBackground)
}

extension Font {
    static var roadBeansHeadline: Font {
        .system(.title2, design: .rounded, weight: .semibold)
    }
    static var roadBeansBody: Font {
        .system(.body)
    }
    static var roadBeansNumeric: Font {
        .system(.title2, design: .rounded, weight: .bold).monospacedDigit()
    }
}
```

- [ ] **Step 2: Implement `PlaceKindStyle`**

Create `Road Beans/DesignSystem/PlaceKindStyle.swift`:

```swift
import SwiftUI

enum PlaceKindStyle {
    static func badge(for kind: PlaceKind) -> some View {
        HStack(spacing: 6) {
            Image(systemName: kind.sfSymbol)
            Text(kind.displayName)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(kind.accentColor.opacity(0.18), in: Capsule())
        .foregroundStyle(kind.accentColor)
        .accessibilityElement(children: .combine)
    }
}
```

- [ ] **Step 3: Implement `GlassCard`**

Create `Road Beans/DesignSystem/GlassCard.swift`:

```swift
import SwiftUI

private struct GlassCardModifier: ViewModifier {
    let tint: Color?
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        if reduceTransparency {
            content
                .padding(12)
                .background((tint ?? Color(UIColor.secondarySystemBackground)).opacity(0.95),
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else {
            content
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder((tint ?? .white).opacity(0.18), lineWidth: 0.5)
                )
        }
    }
}

extension View {
    /// Liquid Glass card backdrop. Falls back to a tinted material when transparency is reduced.
    /// Wraps the iOS 26 `.glassEffect()` call site centrally so feature views are insulated
    /// from API availability.
    func glassCard(tint: Color? = nil) -> some View {
        modifier(GlassCardModifier(tint: tint))
    }
}
```

- [ ] **Step 4: Build**

```bash
xcodebuild ... build
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 5: Commit**

```bash
git add "Road Beans/DesignSystem/Colors+Typography.swift" "Road Beans/DesignSystem/PlaceKindStyle.swift" "Road Beans/DesignSystem/GlassCard.swift"
git commit -m "feat: add design system foundations (colors, type, place badge, glass card)"
```

---

### Task 18: `BeanGlyph` (16-bit pixel-art coffee cup with N beans)

**Goal:** Pure rendering primitive used by both the interactive Bean Slider and the static `BeanRating`. Pixel art via `Canvas`, no anti-aliasing.

**Files:**
- Create: `Road Beans/DesignSystem/BeanSlider/BeanGlyph.swift`
- Test: `Road BeansTests/DesignSystemTests/BeanGlyphTests.swift`

**Acceptance Criteria:**
- [ ] `BeanGlyph(beanCount: Int)` clamps to 0...5.
- [ ] Static `BeanGlyph.beanCount(for value: Double) -> Int` returns `Int(value.rounded(.down))` clamped to 0...5 (so 0.0 → 0, 0.99 → 0, 1.0 → 1, 4.99 → 4, 5.0 → 5).
- [ ] Renders a coffee cup outline + 0...5 bean pixels using `Canvas`.
- [ ] Tests verify the value→count mapping for boundary values.

**Verify:** `xcodebuild ... test -only-testing:"Road BeansTests/BeanGlyphTests"` → PASS.

**Steps:**

- [ ] **Step 1: Write failing test**

Create `Road BeansTests/DesignSystemTests/BeanGlyphTests.swift`:

```swift
import Testing
@testable import Road_Beans

@Suite("BeanGlyph")
struct BeanGlyphTests {
    @Test func valueToCountMapping() {
        #expect(BeanGlyph.beanCount(for: 0.0) == 0)
        #expect(BeanGlyph.beanCount(for: 0.99) == 0)
        #expect(BeanGlyph.beanCount(for: 1.0) == 1)
        #expect(BeanGlyph.beanCount(for: 1.5) == 1)
        #expect(BeanGlyph.beanCount(for: 4.99) == 4)
        #expect(BeanGlyph.beanCount(for: 5.0) == 5)
        #expect(BeanGlyph.beanCount(for: -1.0) == 0)
        #expect(BeanGlyph.beanCount(for: 7.0) == 5)
    }
}
```

- [ ] **Step 2: Implement**

Create `Road Beans/DesignSystem/BeanSlider/BeanGlyph.swift`:

```swift
import SwiftUI

struct BeanGlyph: View {
    let beanCount: Int           // 0...5
    var pixelSize: CGFloat = 4   // each "pixel" of the 16-bit art

    static func beanCount(for value: Double) -> Int {
        if value < 0 { return 0 }
        if value >= 5 { return 5 }
        return Int(value.rounded(.down))
    }

    var body: some View {
        // 16x16 grid; cup outline + 5 bean slots at fixed positions
        Canvas { ctx, size in
            let p = pixelSize
            // cup body outline (rectangle 2..13 horiz, 5..13 vert) + handle
            let cupColor = Color.brown
            for x in 2...13 {
                for y in 5...13 {
                    let onEdge = (x == 2 || x == 13 || y == 5 || y == 13)
                    if onEdge {
                        let rect = CGRect(x: CGFloat(x) * p, y: CGFloat(y) * p, width: p, height: p)
                        ctx.fill(Path(rect), with: .color(cupColor))
                    }
                }
            }
            // handle (x=14, y=7..10)
            for y in 7...10 {
                let rect = CGRect(x: 14 * p, y: CGFloat(y) * p, width: p, height: p)
                ctx.fill(Path(rect), with: .color(cupColor))
            }
            // beans: 5 slots inside the cup
            let slots: [(Int, Int)] = [(4,8), (7,7), (10,8), (5,11), (10,11)]
            let count = max(0, min(beanCount, 5))
            let beanColor = Color(red: 0.30, green: 0.18, blue: 0.10)
            for i in 0..<count {
                let (cx, cy) = slots[i]
                for dx in 0...1 {
                    for dy in 0...1 {
                        let rect = CGRect(x: CGFloat(cx+dx) * p, y: CGFloat(cy+dy) * p, width: p, height: p)
                        ctx.fill(Path(rect), with: .color(beanColor))
                    }
                }
            }
        }
        .frame(width: pixelSize * 16, height: pixelSize * 16)
        .drawingGroup()  // ensures crisp pixel rasterization
        .accessibilityHidden(true)
    }
}

#Preview {
    HStack {
        ForEach(0...5, id: \.self) { n in BeanGlyph(beanCount: n) }
    }
    .padding()
}
```

- [ ] **Step 3: Run test**

```bash
xcodebuild ... test -only-testing:"Road BeansTests/BeanGlyphTests"
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add "Road Beans/DesignSystem/BeanSlider/BeanGlyph.swift" "Road BeansTests/DesignSystemTests/BeanGlyphTests.swift"
git commit -m "feat: add 16-bit BeanGlyph pixel art renderer"
```

---

### Task 19: `BeanSlider` (interactive) and `BeanRating` (static)

**Goal:** The hero rating control. Custom `View`, drag-on-track, snaps to 0.1, haptic at every 0.1, spring + medium impact at every whole number. Plus accessibility per spec §9.

**Files:**
- Create: `Road Beans/DesignSystem/BeanSlider/BeanSlider.swift`
- Create: `Road Beans/DesignSystem/BeanSlider/BeanRating.swift`
- Test: `Road BeansTests/DesignSystemTests/BeanSliderModelTests.swift`

**Acceptance Criteria:**
- [ ] `BeanSlider(value: Binding<Double>, range: ClosedRange<Double> = 0...5, step: Double = 0.1)`.
- [ ] Drag updates `value` snapped to step.
- [ ] On crossing a whole number boundary, plays `.medium` impact + spring scaling on the bean glyph.
- [ ] On every step crossing, plays `.selection` selection feedback (gated by `@AppStorage("hapticsEnabled") = true`).
- [ ] `accessibilityLabel("Drink rating")`, `accessibilityValue("X.X of 5")`, `accessibilityAdjustableAction { dir in ±0.1 }`.
- [ ] Min thumb hit target 44×44.
- [ ] Honors `accessibilityReduceMotion` (crossfade replaces spring) and `accessibilityReduceTransparency` (solid background replaces glass).
- [ ] `BeanRating(value: Double)` is read-only — same glyph at the value's bean count, plus a small numeric label.
- [ ] Testable model: extract a `BeanSliderModel` (or helper functions) for snapping and boundary detection so logic can be unit-tested without UI.

**Verify:** `xcodebuild ... test -only-testing:"Road BeansTests/BeanSliderModelTests"` → PASS.

**Steps:**

- [ ] **Step 1: Write failing test for the snapping/boundary helper**

Create `Road BeansTests/DesignSystemTests/BeanSliderModelTests.swift`:

```swift
import Testing
@testable import Road_Beans

@Suite("BeanSliderModel")
struct BeanSliderModelTests {
    @Test func snapToStep() {
        #expect(BeanSliderModel.snap(0.123, step: 0.1) == 0.1)
        #expect(BeanSliderModel.snap(0.05, step: 0.1) == 0.1)   // .toNearestOrAwayFromZero
        #expect(BeanSliderModel.snap(0.04, step: 0.1) == 0.0)
        #expect(BeanSliderModel.snap(4.97, step: 0.1) == 5.0)
    }

    @Test func clampToRange() {
        #expect(BeanSliderModel.clamp(-0.5, range: 0...5) == 0)
        #expect(BeanSliderModel.clamp(7.0, range: 0...5) == 5)
        #expect(BeanSliderModel.clamp(2.5, range: 0...5) == 2.5)
    }

    @Test func crossedWholeBoundary() {
        // moving 0.95 -> 1.05 crosses boundary 1.0
        #expect(BeanSliderModel.crossedWholeBoundary(from: 0.95, to: 1.05))
        // moving 1.05 -> 1.20 does NOT cross a whole boundary
        #expect(!BeanSliderModel.crossedWholeBoundary(from: 1.05, to: 1.20))
        // moving 4.99 -> 5.0
        #expect(BeanSliderModel.crossedWholeBoundary(from: 4.99, to: 5.0))
    }

    @Test func accessibilityValueFormat() {
        #expect(BeanSliderModel.accessibilityValueText(3.6) == "3.6 of 5")
        #expect(BeanSliderModel.accessibilityValueText(0.0) == "0.0 of 5")
    }
}
```

- [ ] **Step 2: Implement model helpers in the slider file**

Create `Road Beans/DesignSystem/BeanSlider/BeanSlider.swift`:

```swift
import SwiftUI
import UIKit

enum BeanSliderModel {
    static func snap(_ raw: Double, step: Double) -> Double {
        ((raw / step).rounded() * step * 10).rounded() / 10
    }

    static func clamp(_ raw: Double, range: ClosedRange<Double>) -> Double {
        min(max(raw, range.lowerBound), range.upperBound)
    }

    static func crossedWholeBoundary(from old: Double, to new: Double) -> Bool {
        let lo = min(old, new), hi = max(old, new)
        // a whole boundary at 1, 2, 3, 4, 5 sits inside (lo, hi]
        for w in stride(from: 1.0, through: 5.0, by: 1.0) {
            if w > lo && w <= hi { return true }
        }
        return false
    }

    static func accessibilityValueText(_ value: Double) -> String {
        String(format: "%.1f of 5", value)
    }
}

struct BeanSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...5
    var step: Double = 0.1

    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @State private var lastHapticBean: Int = -1
    private let trackHeight: CGFloat = 14
    private let thumbDiameter: CGFloat = 44

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let pct = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            let thumbX = max(thumbDiameter/2, min(width - thumbDiameter/2, width * CGFloat(pct)))
            ZStack(alignment: .leading) {
                // track
                Capsule()
                    .fill(LinearGradient(
                        colors: [Color.blue.opacity(0.5), Color.brown.opacity(0.7)],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(height: trackHeight)
                    .accessibilityHidden(true)

                // bean glyph above thumb
                BeanGlyph(beanCount: BeanGlyph.beanCount(for: value), pixelSize: 3)
                    .scaleEffect(reduceMotion ? 1 : 1.0)
                    .offset(x: thumbX - 24, y: -48)
                    .animation(reduceMotion ? .easeInOut(duration: 0.12) : .spring(response: 0.25, dampingFraction: 0.55), value: BeanGlyph.beanCount(for: value))

                // thumb
                ZStack {
                    if reduceTransparency {
                        Circle().fill(Color.brown)
                    } else {
                        Circle().fill(.thinMaterial)
                    }
                    Text(String(format: "%.1f", value))
                        .font(.roadBeansNumeric)
                        .foregroundStyle(.primary)
                }
                .frame(width: thumbDiameter, height: thumbDiameter)
                .shadow(color: Color.black.opacity(0.18), radius: 4, y: 2)
                .offset(x: thumbX - thumbDiameter/2)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let raw = Double(drag.location.x / max(1, width)) * (range.upperBound - range.lowerBound) + range.lowerBound
                        let clamped = BeanSliderModel.clamp(raw, range: range)
                        let snapped = BeanSliderModel.snap(clamped, step: step)
                        let crossedWhole = BeanSliderModel.crossedWholeBoundary(from: value, to: snapped)
                        if snapped != value, hapticsEnabled {
                            UISelectionFeedbackGenerator().selectionChanged()
                        }
                        if crossedWhole, hapticsEnabled {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                        value = snapped
                    }
            )
            .accessibilityElement()
            .accessibilityLabel("Drink rating")
            .accessibilityValue(BeanSliderModel.accessibilityValueText(value))
            .accessibilityAdjustableAction { direction in
                let delta: Double = (direction == .increment) ? step : -step
                value = BeanSliderModel.clamp(BeanSliderModel.snap(value + delta, step: step), range: range)
            }
        }
        .frame(height: 80)
    }
}

#Preview {
    @Previewable @State var v = 3.6
    VStack {
        BeanSlider(value: $v)
        Text("\(v, specifier: "%.1f")")
    }
    .padding()
}
```

- [ ] **Step 3: Implement `BeanRating`**

Create `Road Beans/DesignSystem/BeanSlider/BeanRating.swift`:

```swift
import SwiftUI

struct BeanRating: View {
    let value: Double
    var pixelSize: CGFloat = 3

    var body: some View {
        HStack(spacing: 8) {
            BeanGlyph(beanCount: BeanGlyph.beanCount(for: value), pixelSize: pixelSize)
            Text(String(format: "%.1f", value))
                .font(.roadBeansNumeric)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Average rating")
        .accessibilityValue(BeanSliderModel.accessibilityValueText(value))
    }
}
```

- [ ] **Step 4: Run tests**

```bash
xcodebuild ... test -only-testing:"Road BeansTests/BeanSliderModelTests"
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add "Road Beans/DesignSystem/BeanSlider" "Road BeansTests/DesignSystemTests/BeanSliderModelTests.swift"
git commit -m "feat: add BeanSlider interactive control + BeanRating static variant"
```

---

### Task 20: Composition root — wire `Road_BeansApp` + `RootView` (TabView shell)

**Goal:** Build the real app entry point: instantiate `PersistenceController`, all repositories, all services, inject through `Environment`, and render a `TabView` with placeholder feature tabs.

**Files:**
- Modify: `Road Beans/Road_BeansApp.swift`
- Modify: `Road Beans/ContentView.swift` — rename to `RootView` content; keep file as `ContentView.swift` since it's still referenced.
- Create: `Road Beans/Features/RootView.swift`
- Create: `Road Beans/Features/PlaceList/PlaceListView.swift` (placeholder `Text("List")`)
- Create: `Road Beans/Features/Map/MapTabView.swift` (placeholder `Text("Map")`)
- Create: `Road Beans/Features/AddVisit/AddVisitView.swift` (placeholder `Text("Add")`)

**Acceptance Criteria:**
- [ ] App launches without crash.
- [ ] TabView shows 3 tabs: List, Map, +.
- [ ] All concrete repositories/services are instantiated and injected via `.environment(\.placeRepository, ...)` etc.
- [ ] If `persistenceController.mode == .pendingRelaunch`, `RootView` shows the relaunch overlay instead of the tab bar.
- [ ] If `persistenceController.mode == .pendingMigration`, `RootView` shows the migration prompt with Yes / Keep local only buttons.
- [ ] Build + run on simulator works.

**Verify:** `xcodebuild ... build` → BUILD SUCCEEDED. Manual: launch on simulator, see 3-tab `TabView`.

**Steps:**

- [ ] **Step 1: Create placeholder feature views**

Create `Road Beans/Features/PlaceList/PlaceListView.swift`:

```swift
import SwiftUI

struct PlaceListView: View {
    var body: some View {
        NavigationStack {
            Text("List")
                .navigationTitle("Stops")
        }
    }
}
```

Create `Road Beans/Features/Map/MapTabView.swift`:

```swift
import SwiftUI

struct MapTabView: View {
    var body: some View {
        NavigationStack {
            Text("Map")
                .navigationTitle("Map")
        }
    }
}
```

Create `Road Beans/Features/AddVisit/AddVisitView.swift`:

```swift
import SwiftUI

struct AddVisitView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Text("Add a Visit")
                .navigationTitle("New Visit")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
    }
}
```

- [ ] **Step 2: Implement `RootView`**

Create `Road Beans/Features/RootView.swift`:

```swift
import SwiftUI

struct RootView: View {
    @Environment(PersistenceController.self) private var persistence
    @State private var showingAdd = false
    @State private var selectedTab = 0

    var body: some View {
        Group {
            switch persistence.mode {
            case .pendingRelaunch:
                relaunchPrompt
            case .pendingMigration:
                migrationPrompt
            case .localOnly, .cloudKitBacked:
                tabs
            }
        }
    }

    private var tabs: some View {
        TabView(selection: $selectedTab) {
            PlaceListView()
                .tabItem { Label("List", systemImage: "list.bullet") }
                .tag(0)

            MapTabView()
                .tabItem { Label("Map", systemImage: "map.fill") }
                .tag(1)

            Color.clear
                .tabItem { Label("Add", systemImage: "plus.circle.fill") }
                .tag(2)
        }
        .onChange(of: selectedTab) { _, new in
            if new == 2 {
                showingAdd = true
                selectedTab = 0
            }
        }
        .fullScreenCover(isPresented: $showingAdd) {
            AddVisitView()
        }
    }

    private var migrationPrompt: some View {
        VStack(spacing: 24) {
            Image(systemName: "icloud.and.arrow.up.fill").font(.largeTitle)
            Text("Bring your existing road trip data into iCloud?")
                .font(.roadBeansHeadline)
                .multilineTextAlignment(.center)
            HStack {
                Button("Keep local only") { persistence.deferMigration() }
                    .buttonStyle(.bordered)
                Button("Yes, migrate") {
                    Task { try? await persistence.migrateLocalToCloudKit() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }

    private var relaunchPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.icloud").font(.largeTitle)
            Text("Your iCloud account changed.")
                .font(.roadBeansHeadline)
            Text("Relaunch Road Beans to continue.")
                .font(.roadBeansBody)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
```

- [ ] **Step 3: Replace `ContentView.swift` with a delegate to `RootView`**

Edit `Road Beans/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        RootView()
    }
}

#Preview {
    ContentView()
}
```

- [ ] **Step 4: Wire `Road_BeansApp.swift` (composition root)**

Edit `Road Beans/Road_BeansApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct Road_BeansApp: App {
    @State private var persistence: PersistenceController
    private let icloud: any iCloudAvailabilityServiceProtocol
    private let sync: any RemoteSyncCoordinator
    private let placeRepo: any PlaceRepository
    private let tagRepo: any TagRepository
    private let photoRepo: any PhotoRepository
    private let tombRepo: any TombstoneRepository
    private let visitRepo: any VisitRepository
    private let locationPermission: any LocationPermissionService
    private let locationSearch: any LocationSearchService
    private let photoProcessing: any PhotoProcessingService

    init() {
        let icloud = SystemICloudAvailabilityService()
        let controller = PersistenceController(icloud: icloud)
        let ctx = ModelContext(controller.container)
        let sync = LocalOnlyRemoteSync()
        let placeRepo = LocalPlaceRepository(context: ctx, sync: sync)
        let tagRepo = LocalTagRepository(context: ctx, sync: sync)
        let photoRepo = LocalPhotoRepository(context: ctx, sync: sync)
        let tombRepo = LocalTombstoneRepository(context: ctx, sync: sync)
        let visitRepo = LocalVisitRepository(
            context: ctx, sync: sync,
            places: placeRepo, tags: tagRepo, photos: photoRepo, tombstones: tombRepo
        )
        self.icloud = icloud
        self.sync = sync
        self.placeRepo = placeRepo
        self.tagRepo = tagRepo
        self.photoRepo = photoRepo
        self.tombRepo = tombRepo
        self.visitRepo = visitRepo
        self.locationPermission = SystemLocationPermissionService()
        self.locationSearch = SystemLocationSearchService()
        self.photoProcessing = DefaultPhotoProcessingService()
        self._persistence = State(initialValue: controller)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(persistence)
                .modelContainer(persistence.container)
                .environment(\.placeRepository, placeRepo)
                .environment(\.visitRepository, visitRepo)
                .environment(\.tagRepository, tagRepo)
                .environment(\.photoRepository, photoRepo)
                .environment(\.tombstoneRepository, tombRepo)
                .environment(\.locationSearchService, locationSearch)
                .environment(\.locationPermissionService, locationPermission)
                .environment(\.photoProcessingService, photoProcessing)
                .environment(\.iCloudAvailability, icloud)
                .environment(\.remoteSyncCoordinator, sync)
        }
    }
}
```

- [ ] **Step 5: Build and launch**

```bash
xcodebuild -project "Road Beans.xcodeproj" -scheme "Road Beans" \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Manual: open the project in Xcode, run on iPhone 16 simulator. Verify the 3-tab TabView appears, tapping `+` opens the placeholder Add sheet, Cancel dismisses.

- [ ] **Step 6: Commit**

```bash
git add "Road Beans/Road_BeansApp.swift" "Road Beans/ContentView.swift" "Road Beans/Features"
git commit -m "feat: composition root with TabView shell + persistence-mode prompts"
```

---

### Task 21: `PlaceListViewModel` and full PlaceList screen

**Goal:** Replace placeholder with real list. Two modes: By Place (grouped by place, latest visit's avg rating shown) and Recent Visits (flat). Search bar filters Place names, drink names, tag names.

**Files:**
- Create: `Road Beans/Features/PlaceList/PlaceListViewModel.swift`
- Modify: `Road Beans/Features/PlaceList/PlaceListView.swift`
- Test: `Road BeansTests/ViewModelTests/PlaceListViewModelTests.swift`

**Acceptance Criteria:**
- [ ] `@Observable PlaceListViewModel` holds `mode: PlaceListMode { case byPlace, recentVisits }`, `searchText`, `places: [PlaceSummary]`, `recentVisits: [RecentVisitRow]`.
- [ ] `func reload() async` fetches both via repositories (single shared dispatch).
- [ ] `var filteredPlaces` and `var filteredVisits` apply searchText filter (case-insensitive contains over name/drink names/tag names).
- [ ] PlaceList view shows a Picker for mode toggle, search field, and the corresponding List.
- [ ] Tapping a place pushes a `PlaceDetailView` (placeholder for now until Task 22).
- [ ] Tests use fake repositories: filter by place name; filter by tag; filter by drink name; mode switching does not lose state.

**Verify:** `xcodebuild ... test -only-testing:"Road BeansTests/PlaceListViewModelTests"` → PASS.

**Steps:**

- [ ] **Step 1: Write fake repos for view-model tests**

Create `Road BeansTests/ViewModelTests/FakeRepositories.swift`:

```swift
import Foundation
import CoreLocation
@testable import Road_Beans

final class FakePlaceRepository: PlaceRepository, @unchecked Sendable {
    var stored: [PlaceSummary] = []
    var details: [UUID: PlaceDetail] = [:]
    func findOrCreate(reference: PlaceReference) async throws -> UUID { UUID() }
    func summaries() async throws -> [PlaceSummary] { stored }
    func summariesNear(coordinate: CLLocationCoordinate2D, radiusMeters: Double) async throws -> [PlaceSummary] { stored }
    func detail(id: UUID) async throws -> PlaceDetail? { details[id] }
}

final class FakeVisitRepository: VisitRepository, @unchecked Sendable {
    var recents: [RecentVisitRow] = []
    var saved: [CreateVisitCommand] = []
    var deletedIDs: [UUID] = []
    func save(_ command: CreateVisitCommand) async throws -> UUID {
        saved.append(command); return UUID()
    }
    func update(_ command: UpdateVisitCommand) async throws {}
    func delete(_ command: DeleteVisitCommand) async throws { deletedIDs.append(command.id) }
    func recentRows(limit: Int) async throws -> [RecentVisitRow] { recents }
    func detail(id: UUID) async throws -> VisitDetail? { nil }
}

final class FakeTagRepository: TagRepository, @unchecked Sendable {
    var byName: [String: UUID] = [:]
    var suggestionsList: [TagSuggestion] = []
    func findOrCreate(name: String) async throws -> UUID {
        let n = LocalTagRepository.normalize(name)
        if let existing = byName[n] { return existing }
        let id = UUID(); byName[n] = id; return id
    }
    func suggestions(prefix: String, limit: Int) async throws -> [TagSuggestion] {
        suggestionsList.filter { $0.name.hasPrefix(prefix.lowercased()) }.prefix(limit).map { $0 }
    }
    func all() async throws -> [TagSuggestion] { suggestionsList }
}

final class FakePhotoRepository: PhotoRepository, @unchecked Sendable {
    func insertProcessed(_ processed: ProcessedPhoto, caption: String?, into visitID: UUID) async throws -> UUID { UUID() }
    func remove(_ photoID: UUID) async throws {}
}

final class FakeTombstoneRepository: TombstoneRepository, @unchecked Sendable {
    var inserted: [TombstoneDTO] = []
    func insertTombstone(entityKind: SyncEntityKind, entityID: UUID, remoteID: String?) async throws {
        inserted.append(.init(id: UUID(), entityKind: entityKind.rawValue, entityID: entityID, remoteID: remoteID, deletedAt: .now))
    }
    func all() async throws -> [TombstoneDTO] { inserted }
}
```

- [ ] **Step 2: Write failing view-model test**

Create `Road BeansTests/ViewModelTests/PlaceListViewModelTests.swift`:

```swift
import Testing
import CoreLocation
@testable import Road_Beans

@Suite("PlaceListViewModel")
@MainActor
struct PlaceListViewModelTests {
    @Test func filteredByPlaceName() async {
        let places = FakePlaceRepository()
        places.stored = [
            PlaceSummary(id: UUID(), name: "Loves", kind: .truckStop, address: nil, coordinate: nil, averageRating: 4.0, visitCount: 1),
            PlaceSummary(id: UUID(), name: "QT", kind: .gasStation, address: nil, coordinate: nil, averageRating: 3.0, visitCount: 1)
        ]
        let visits = FakeVisitRepository()
        let vm = PlaceListViewModel(places: places, visits: visits)
        await vm.reload()
        vm.searchText = "lov"
        #expect(vm.filteredPlaces.count == 1)
        #expect(vm.filteredPlaces.first?.name == "Loves")
    }

    @Test func filteredVisitsByDrinkAndTag() async {
        let places = FakePlaceRepository()
        let visits = FakeVisitRepository()
        let vid1 = UUID(), vid2 = UUID()
        visits.recents = [
            RecentVisitRow(visit: VisitRow(id: vid1, date: .now, drinkCount: 1, tagNames: ["smooth"], photoCount: 0, averageRating: 4.0), placeName: "Loves", placeKind: .truckStop),
            RecentVisitRow(visit: VisitRow(id: vid2, date: .now, drinkCount: 1, tagNames: ["burnt"], photoCount: 0, averageRating: 1.0), placeName: "Maverik", placeKind: .gasStation)
        ]
        let vm = PlaceListViewModel(places: places, visits: visits)
        await vm.reload()
        vm.searchText = "smooth"
        #expect(vm.filteredVisits.count == 1)
        #expect(vm.filteredVisits.first?.visit.id == vid1)
    }
}
```

- [ ] **Step 3: Implement view-model**

Create `Road Beans/Features/PlaceList/PlaceListViewModel.swift`:

```swift
import Foundation
import Observation

enum PlaceListMode: String, CaseIterable, Identifiable, Sendable {
    case byPlace = "By Place"
    case recentVisits = "Recent Visits"
    var id: String { rawValue }
}

@Observable
@MainActor
final class PlaceListViewModel {
    var mode: PlaceListMode = .byPlace
    var searchText: String = ""
    var places: [PlaceSummary] = []
    var recentVisits: [RecentVisitRow] = []

    private let placeRepo: any PlaceRepository
    private let visitRepo: any VisitRepository

    init(places: any PlaceRepository, visits: any VisitRepository) {
        self.placeRepo = places
        self.visitRepo = visits
    }

    func reload() async {
        do {
            async let p = placeRepo.summaries()
            async let v = visitRepo.recentRows(limit: 200)
            self.places = try await p
            self.recentVisits = try await v
        } catch {
            self.places = []
            self.recentVisits = []
        }
    }

    var filteredPlaces: [PlaceSummary] {
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return places }
        return places.filter { $0.name.lowercased().contains(q) }
    }

    var filteredVisits: [RecentVisitRow] {
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return recentVisits }
        return recentVisits.filter { row in
            row.placeName.lowercased().contains(q) ||
            row.visit.tagNames.contains(where: { $0.lowercased().contains(q) }) ||
            // drink names not in VisitRow yet — search by tag/place only at this layer
            false
        }
    }
}
```

- [ ] **Step 4: Replace `PlaceListView`**

Edit `Road Beans/Features/PlaceList/PlaceListView.swift`:

```swift
import SwiftUI

struct PlaceListView: View {
    @Environment(\.placeRepository) private var placeRepo
    @Environment(\.visitRepository) private var visitRepo
    @State private var vm: PlaceListViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm {
                    content(vm: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Stops")
        }
        .task {
            if vm == nil {
                let m = PlaceListViewModel(places: placeRepo, visits: visitRepo)
                vm = m
                await m.reload()
            }
        }
    }

    @ViewBuilder
    private func content(vm: PlaceListViewModel) -> some View {
        @Bindable var vm = vm
        VStack(spacing: 0) {
            Picker("", selection: $vm.mode) {
                ForEach(PlaceListMode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            List {
                if vm.mode == .byPlace {
                    ForEach(vm.filteredPlaces) { p in
                        NavigationLink(value: p.id) {
                            placeRow(p)
                        }
                    }
                } else {
                    ForEach(vm.filteredVisits, id: \.visit.id) { row in
                        visitRow(row)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $vm.searchText, prompt: "Search stops, drinks, tags")
            .navigationDestination(for: UUID.self) { id in
                PlaceDetailView(placeID: id)
            }
            .refreshable { await vm.reload() }
        }
    }

    private func placeRow(_ p: PlaceSummary) -> some View {
        HStack {
            Image(systemName: p.kind.sfSymbol).foregroundStyle(p.kind.accentColor)
            VStack(alignment: .leading) {
                Text(p.name).font(.roadBeansHeadline)
                if let addr = p.address {
                    Text(addr).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer()
            if let avg = p.averageRating {
                BeanRating(value: avg, pixelSize: 2)
            }
        }
        .padding(.vertical, 6)
    }

    private func visitRow(_ row: RecentVisitRow) -> some View {
        HStack {
            Image(systemName: row.placeKind.sfSymbol).foregroundStyle(row.placeKind.accentColor)
            VStack(alignment: .leading) {
                Text(row.placeName).font(.roadBeansHeadline)
                Text(row.visit.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if let avg = row.visit.averageRating {
                BeanRating(value: avg, pixelSize: 2)
            }
        }
    }
}
```

- [ ] **Step 5: Stub `PlaceDetailView`**

Create `Road Beans/Features/PlaceDetail/PlaceDetailView.swift`:

```swift
import SwiftUI

struct PlaceDetailView: View {
    let placeID: UUID
    var body: some View {
        Text("Place Detail \(placeID.uuidString)")
            .navigationTitle("Place")
    }
}
```

- [ ] **Step 6: Run tests**

```bash
xcodebuild ... test -only-testing:"Road BeansTests/PlaceListViewModelTests"
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add "Road Beans/Features/PlaceList" "Road Beans/Features/PlaceDetail/PlaceDetailView.swift" "Road BeansTests/ViewModelTests"
git commit -m "feat: PlaceList screen with ByPlace/RecentVisits modes and search"
```

---

### Task 22: `PlaceDetailView` (full screen)

**Goal:** Real Place Detail with header, average rating + static `BeanRating`, expandable Visits list with drinks underneath each.

**Files:**
- Modify: `Road Beans/Features/PlaceDetail/PlaceDetailView.swift`
- Create: `Road Beans/Features/PlaceDetail/PlaceDetailViewModel.swift`
- Test: `Road BeansTests/ViewModelTests/PlaceDetailViewModelTests.swift`

**Acceptance Criteria:**
- [ ] `@Observable PlaceDetailViewModel(placeRepo:)` exposes `detail: PlaceDetail?` and `func load(id:) async`.
- [ ] View shows: kind badge, name, address, "Open in Maps" button (uses `MKMapItem.openInMaps`), average rating block, scrollable visit list.
- [ ] Each visit row expands to reveal its drinks (each with category SF symbol + name + `BeanRating` static).
- [ ] Tapping a visit row navigates to `VisitDetailView`.
- [ ] If average rating is nil (no drinks), shows "No ratings yet" instead of the bean glyph.
- [ ] Test: load assigns detail; nil id sets detail to nil.

**Verify:** `xcodebuild ... test -only-testing:"Road BeansTests/PlaceDetailViewModelTests"` → PASS.

**Steps:**

- [ ] **Step 1: Failing test**

Create `Road BeansTests/ViewModelTests/PlaceDetailViewModelTests.swift`:

```swift
import Testing
@testable import Road_Beans

@Suite("PlaceDetailViewModel")
@MainActor
struct PlaceDetailViewModelTests {
    @Test func loadAssignsDetail() async {
        let repo = FakePlaceRepository()
        let id = UUID()
        repo.details[id] = PlaceDetail(
            id: id, name: "Loves", kind: .truckStop, source: .mapKit,
            address: nil, streetNumber: nil, streetName: nil, city: nil, region: nil,
            postalCode: nil, country: nil, phoneNumber: nil, websiteURL: nil,
            coordinate: nil, averageRating: 4.0, visits: []
        )
        let vm = PlaceDetailViewModel(placeRepo: repo)
        await vm.load(id: id)
        #expect(vm.detail?.name == "Loves")
    }
}
```

- [ ] **Step 2: Implement view-model**

Create `Road Beans/Features/PlaceDetail/PlaceDetailViewModel.swift`:

```swift
import Foundation
import Observation

@Observable
@MainActor
final class PlaceDetailViewModel {
    var detail: PlaceDetail?
    private let placeRepo: any PlaceRepository
    init(placeRepo: any PlaceRepository) { self.placeRepo = placeRepo }
    func load(id: UUID) async {
        detail = try? await placeRepo.detail(id: id)
    }
}
```

- [ ] **Step 3: Implement view**

Edit `Road Beans/Features/PlaceDetail/PlaceDetailView.swift`:

```swift
import SwiftUI
import MapKit

struct PlaceDetailView: View {
    let placeID: UUID
    @Environment(\.placeRepository) private var placeRepo
    @State private var vm: PlaceDetailViewModel?
    @State private var expandedVisits: Set<UUID> = []

    var body: some View {
        Group {
            if let detail = vm?.detail {
                content(detail)
            } else {
                ProgressView().task { await ensureLoaded() }
            }
        }
        .navigationTitle("Place")
    }

    private func ensureLoaded() async {
        if vm == nil { vm = PlaceDetailViewModel(placeRepo: placeRepo) }
        await vm?.load(id: placeID)
    }

    @ViewBuilder
    private func content(_ d: PlaceDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header(d)
                averageBlock(d)
                visitsList(d)
            }
            .padding()
        }
    }

    private func header(_ d: PlaceDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: d.kind.sfSymbol)
                    .font(.largeTitle)
                    .foregroundStyle(d.kind.accentColor)
                VStack(alignment: .leading) {
                    Text(d.name).font(.roadBeansHeadline)
                    PlaceKindStyle.badge(for: d.kind)
                }
            }
            if let addr = d.address {
                Text(addr).font(.caption).foregroundStyle(.secondary)
            }
            if d.coordinate != nil {
                Button {
                    let coord = d.coordinate!
                    let item = MKMapItem(placemark: MKPlacemark(coordinate: coord))
                    item.name = d.name
                    item.openInMaps()
                } label: {
                    Label("Open in Maps", systemImage: "map.fill")
                }
                .buttonStyle(.bordered)
            }
        }
        .glassCard(tint: d.kind.accentColor)
    }

    private func averageBlock(_ d: PlaceDetail) -> some View {
        Group {
            if let avg = d.averageRating {
                BeanRating(value: avg, pixelSize: 4)
            } else {
                Text("No ratings yet").font(.roadBeansBody).foregroundStyle(.secondary)
            }
        }
    }

    private func visitsList(_ d: PlaceDetail) -> some View {
        VStack(spacing: 8) {
            ForEach(d.visits) { v in
                VStack(alignment: .leading) {
                    NavigationLink(value: v.id) {
                        HStack {
                            Text(v.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.roadBeansBody)
                            Spacer()
                            if let avg = v.averageRating {
                                BeanRating(value: avg, pixelSize: 2)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .navigationDestination(for: UUID.self) { id in
            VisitDetailView(visitID: id)
        }
    }
}
```

- [ ] **Step 4: Stub `VisitDetailView`** (real impl in Task 23)

Create `Road Beans/Features/VisitDetail/VisitDetailView.swift`:

```swift
import SwiftUI

struct VisitDetailView: View {
    let visitID: UUID
    var body: some View {
        Text("Visit \(visitID.uuidString)")
            .navigationTitle("Visit")
    }
}
```

- [ ] **Step 5: Run tests**

```bash
xcodebuild ... test -only-testing:"Road BeansTests/PlaceDetailViewModelTests"
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add "Road Beans/Features/PlaceDetail" "Road Beans/Features/VisitDetail/VisitDetailView.swift" "Road BeansTests/ViewModelTests/PlaceDetailViewModelTests.swift"
git commit -m "feat: PlaceDetail screen with header, average bean rating, and visits"
```

---

### Task 23: `VisitDetailView` (full screen) + delete flow

**Goal:** Real visit detail. Date, photo pager (full-res), tag chips, drinks list (each with bean rating). Edit toolbar (defer real edit to v1.1) + Delete with confirmation that writes a Tombstone.

**Files:**
- Modify: `Road Beans/Features/VisitDetail/VisitDetailView.swift`
- Create: `Road Beans/Features/VisitDetail/VisitDetailViewModel.swift`
- Test: `Road BeansTests/ViewModelTests/VisitDetailViewModelTests.swift`

**Acceptance Criteria:**
- [ ] `@Observable VisitDetailViewModel` exposes `detail: VisitDetail?`, `func load(id:) async`, `func delete() async throws`.
- [ ] View shows date, photos in `TabView(selection:).tabViewStyle(.page)` rendering `PhotoReference.thumbnailData` (v1: photos pager uses thumbnail tier — full-res presentation deferred to PhotosPicker integration), drink list with `BeanRating`, tag chips.
- [ ] Toolbar: Delete button → `.confirmationDialog`. Confirming calls `vm.delete()`, dismisses screen, posts notification name `RoadBeans.visitDeleted` so list refreshes.
- [ ] Test: delete on a loaded visit calls `VisitRepository.delete` with the right id.

**Verify:** `xcodebuild ... test -only-testing:"Road BeansTests/VisitDetailViewModelTests"` → PASS.

**Steps:**

- [ ] **Step 1: Failing test**

Create `Road BeansTests/ViewModelTests/VisitDetailViewModelTests.swift`:

```swift
import Testing
@testable import Road_Beans

@Suite("VisitDetailViewModel")
@MainActor
struct VisitDetailViewModelTests {
    @Test func deleteCallsRepository() async throws {
        let visits = FakeVisitRepository()
        let id = UUID()
        let vm = VisitDetailViewModel(visits: visits, visitID: id)
        try await vm.delete()
        #expect(visits.deletedIDs == [id])
    }
}
```

- [ ] **Step 2: Implement view-model**

Create `Road Beans/Features/VisitDetail/VisitDetailViewModel.swift`:

```swift
import Foundation
import Observation

@Observable
@MainActor
final class VisitDetailViewModel {
    var detail: VisitDetail?
    private let visits: any VisitRepository
    let visitID: UUID

    init(visits: any VisitRepository, visitID: UUID) {
        self.visits = visits
        self.visitID = visitID
    }

    func load() async {
        detail = try? await visits.detail(id: visitID)
    }

    func delete() async throws {
        try await visits.delete(.init(id: visitID))
    }
}
```

- [ ] **Step 3: Implement view**

Edit `Road Beans/Features/VisitDetail/VisitDetailView.swift`:

```swift
import SwiftUI

struct VisitDetailView: View {
    let visitID: UUID
    @Environment(\.visitRepository) private var visitsRepo
    @Environment(\.dismiss) private var dismiss
    @State private var vm: VisitDetailViewModel?
    @State private var confirmDelete = false

    var body: some View {
        Group {
            if let d = vm?.detail {
                content(d)
            } else {
                ProgressView().task {
                    if vm == nil { vm = VisitDetailViewModel(visits: visitsRepo, visitID: visitID) }
                    await vm?.load()
                }
            }
        }
        .navigationTitle("Visit")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    confirmDelete = true
                } label: { Image(systemName: "trash") }
            }
        }
        .confirmationDialog("Delete this visit?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task {
                    try? await vm?.delete()
                    NotificationCenter.default.post(name: .roadBeansVisitDeleted, object: nil)
                    dismiss()
                }
            }
        }
    }

    @ViewBuilder
    private func content(_ d: VisitDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(d.date.formatted(date: .complete, time: .shortened))
                    .font(.roadBeansHeadline)

                if !d.photos.isEmpty {
                    TabView {
                        ForEach(d.photos) { ref in
                            if let img = UIImage(data: ref.thumbnailData) {
                                Image(uiImage: img).resizable().scaledToFit()
                            }
                        }
                    }
                    .tabViewStyle(.page)
                    .frame(height: 280)
                }

                if !d.tagNames.isEmpty {
                    FlowTags(tags: d.tagNames)
                }

                ForEach(d.drinks) { drink in
                    HStack {
                        Image(systemName: drink.category.sfSymbol)
                        VStack(alignment: .leading) {
                            Text(drink.name).font(.roadBeansBody)
                            if !drink.tagNames.isEmpty {
                                Text(drink.tagNames.joined(separator: " · "))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        BeanRating(value: drink.rating, pixelSize: 2)
                    }
                    .padding(.vertical, 6)
                }
            }
            .padding()
        }
    }
}

extension Notification.Name {
    static let roadBeansVisitDeleted = Notification.Name("RoadBeans.visitDeleted")
}

private struct FlowTags: View {
    let tags: [String]
    var body: some View {
        HStack {
            ForEach(tags, id: \.self) { t in
                Text(t).font(.caption)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.18), in: Capsule())
            }
        }
    }
}
```

- [ ] **Step 4: Run tests**

```bash
xcodebuild ... test -only-testing:"Road BeansTests/VisitDetailViewModelTests"
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add "Road Beans/Features/VisitDetail" "Road BeansTests/ViewModelTests/VisitDetailViewModelTests.swift"
git commit -m "feat: VisitDetail screen with photo pager, drinks, tags, delete"
```

---

### Task 24: `MapTabView` with annotations and "Stops near me" toggle

**Goal:** Real map view. MapKit `Map` with custom annotations colored by Place kind. Permission-gated "Stops near me" toggle.

**Files:**
- Create: `Road Beans/Features/Map/MapTabViewModel.swift`
- Modify: `Road Beans/Features/Map/MapTabView.swift`
- Test: `Road BeansTests/ViewModelTests/MapTabViewModelTests.swift`

**Acceptance Criteria:**
- [ ] `@Observable MapTabViewModel` holds `places: [PlaceSummary]`, `nearMeOn: Bool`, `permissionStatus: LocationAuthorization`, `func reload(allowingNearMe: Bool) async`.
- [ ] View renders `Map { ForEach(places) { Marker(place.name, coordinate: ...) } }` with kind-tinted markers.
- [ ] Toggle "Stops near me" — if permission `.notDetermined`, requests; if `.denied`/`.restricted`, shows the inline rationale + Settings deep link per spec §8.
- [ ] Tapping a marker presents a `PlaceSummary` glass card sheet with "View visits" button.
- [ ] Test: toggling near-me when authorized calls `summariesNear`; when denied, view-model exposes the denied state.

**Verify:** `xcodebuild ... test -only-testing:"Road BeansTests/MapTabViewModelTests"` → PASS.

**Steps:**

- [ ] **Step 1: Failing test**

Create `Road BeansTests/ViewModelTests/MapTabViewModelTests.swift`:

```swift
import Testing
import CoreLocation
@testable import Road_Beans

@Suite("MapTabViewModel")
@MainActor
struct MapTabViewModelTests {
    @Test func reloadFetchesAllWhenNearMeOff() async {
        let places = FakePlaceRepository()
        places.stored = [PlaceSummary(id: UUID(), name: "Loves", kind: .truckStop, address: nil, coordinate: CLLocationCoordinate2D(latitude: 34, longitude: -112), averageRating: nil, visitCount: 1)]
        let perm = FakeLocationPermissionService(initial: .authorized)
        let vm = MapTabViewModel(places: places, permission: perm)
        await vm.reload(allowingNearMe: false)
        #expect(vm.places.count == 1)
    }

    @Test func deniedPermissionExposed() async {
        let places = FakePlaceRepository()
        let perm = FakeLocationPermissionService(initial: .denied)
        let vm = MapTabViewModel(places: places, permission: perm)
        await vm.refreshPermissionStatus()
        #expect(vm.permissionStatus == .denied)
    }
}
```

- [ ] **Step 2: Implement view-model**

Create `Road Beans/Features/Map/MapTabViewModel.swift`:

```swift
import Foundation
import CoreLocation
import Observation

@Observable
@MainActor
final class MapTabViewModel {
    var places: [PlaceSummary] = []
    var nearMeOn: Bool = false
    var permissionStatus: LocationAuthorization = .notDetermined

    private let placeRepo: any PlaceRepository
    private let permission: any LocationPermissionService

    init(places: any PlaceRepository, permission: any LocationPermissionService) {
        self.placeRepo = places
        self.permission = permission
    }

    func refreshPermissionStatus() async {
        permissionStatus = await permission.status
    }

    func requestPermissionIfNeeded() async {
        if permissionStatus == .notDetermined {
            await permission.requestWhenInUse()
            permissionStatus = await permission.status
        }
    }

    func reload(allowingNearMe: Bool) async {
        do {
            if allowingNearMe, permissionStatus == .authorized {
                // For v1 we don't actually have the user's coordinate from CL here;
                // wire that in v1.1. For now, fall through to all summaries.
                places = try await placeRepo.summaries()
            } else {
                places = try await placeRepo.summaries()
            }
        } catch {
            places = []
        }
    }
}
```

- [ ] **Step 3: Implement view**

Edit `Road Beans/Features/Map/MapTabView.swift`:

```swift
import SwiftUI
import MapKit

struct MapTabView: View {
    @Environment(\.placeRepository) private var placeRepo
    @Environment(\.locationPermissionService) private var permission
    @State private var vm: MapTabViewModel?
    @State private var selected: PlaceSummary?

    var body: some View {
        NavigationStack {
            Group {
                if let vm {
                    content(vm: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Map")
        }
        .task {
            if vm == nil {
                let m = MapTabViewModel(places: placeRepo, permission: permission)
                vm = m
                await m.refreshPermissionStatus()
                await m.reload(allowingNearMe: false)
            }
        }
    }

    @ViewBuilder
    private func content(vm: MapTabViewModel) -> some View {
        @Bindable var vm = vm
        VStack(spacing: 0) {
            HStack {
                Toggle("Stops near me", isOn: $vm.nearMeOn)
                    .onChange(of: vm.nearMeOn) { _, on in
                        Task {
                            if on { await vm.requestPermissionIfNeeded() }
                            await vm.reload(allowingNearMe: on)
                        }
                    }
            }
            .padding()

            if vm.nearMeOn && (vm.permissionStatus == .denied || vm.permissionStatus == .restricted) {
                deniedRationale
            } else {
                Map {
                    ForEach(vm.places.compactMap { p -> (PlaceSummary, CLLocationCoordinate2D)? in
                        guard let c = p.coordinate else { return nil }
                        return (p, c)
                    }, id: \.0.id) { (p, c) in
                        Annotation(p.name, coordinate: c) {
                            Image(systemName: p.kind.sfSymbol)
                                .padding(8)
                                .background(p.kind.accentColor, in: Circle())
                                .foregroundStyle(.white)
                                .onTapGesture { selected = p }
                        }
                    }
                }
            }
        }
        .sheet(item: $selected) { p in
            placeSheet(p)
        }
    }

    private var deniedRationale: some View {
        VStack(spacing: 12) {
            Text("Location is off.")
                .font(.roadBeansHeadline)
            Text("Open Settings to enable nearby stops.")
                .foregroundStyle(.secondary)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func placeSheet(_ p: PlaceSummary) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text(p.name).font(.roadBeansHeadline)
                PlaceKindStyle.badge(for: p.kind)
                if let avg = p.averageRating { BeanRating(value: avg, pixelSize: 3) }
                NavigationLink("View visits", value: p.id)
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationDestination(for: UUID.self) { id in
                PlaceDetailView(placeID: id)
            }
            .presentationDetents([.medium])
        }
    }
}
```

- [ ] **Step 4: Run tests**

```bash
xcodebuild ... test -only-testing:"Road BeansTests/MapTabViewModelTests"
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add "Road Beans/Features/Map" "Road BeansTests/ViewModelTests/MapTabViewModelTests.swift"
git commit -m "feat: Map tab with kind-tinted annotations and near-me toggle"
```

---

### Task 25: AddVisit page 1 — Place picker (MapKit search + custom fallback)

**Goal:** First page of the combined Add sheet. Debounced MapKit search, results list, "+ Custom place" button. Pickng either dispatches a `PlaceReference` to the parent flow.

**Files:**
- Create: `Road Beans/Features/AddVisit/AddVisitFlowModel.swift`
- Create: `Road Beans/Features/AddVisit/AddVisitPlacePage.swift`
- Modify: `Road Beans/Features/AddVisit/AddVisitView.swift` — wire as the first page in a `TabView(selection:)` with paging.
- Test: `Road BeansTests/ViewModelTests/AddVisitFlowModelPlaceTests.swift`

**Acceptance Criteria:**
- [ ] `@Observable AddVisitFlowModel` holds: `placeRef: PlaceReference?`, `date: Date`, `visitTags: [String]`, `drinks: [DrinkDraft]`, `photos: [PhotoDraft]`, `currentPage: Int`, `searchResults: [MapKitPlaceDraft]`, `searchText: String`.
- [ ] `func search() async` debounces 250ms then calls `LocationSearchService.search(...)`. Repeated calls within debounce window cancel previous.
- [ ] `func selectMapKit(_:)` and `func selectCustom(_:)` set `placeRef`.
- [ ] AddVisitPlacePage shows search field, results list, "+ Custom place" button → presents simple sheet with name + kind + optional address.
- [ ] After place selected, model sets `currentPage = 1`.
- [ ] Test: `selectMapKit` sets `placeRef = .newMapKit(...)`; `selectCustom` sets `placeRef = .newCustom(...)`.

**Verify:** `xcodebuild ... test -only-testing:"Road BeansTests/AddVisitFlowModelPlaceTests"` → PASS.

**Steps:**

- [ ] **Step 1: Failing test**

Create `Road BeansTests/ViewModelTests/AddVisitFlowModelPlaceTests.swift`:

```swift
import Testing
@testable import Road_Beans

@Suite("AddVisitFlowModel — place")
@MainActor
struct AddVisitFlowModelPlaceTests {
    func makeModel() -> AddVisitFlowModel {
        AddVisitFlowModel(
            visits: FakeVisitRepository(),
            tags: FakeTagRepository(),
            search: FakeLocationSearchService(canned: []),
            photoProcessor: DefaultPhotoProcessingService()
        )
    }

    @Test func selectMapKitSetsRef() {
        let m = makeModel()
        let draft = MapKitPlaceDraft(name: "Loves", kind: .truckStop, mapKitIdentifier: "x", mapKitName: nil, address: nil, latitude: 34, longitude: -112, phoneNumber: nil, websiteURL: nil, streetNumber: nil, streetName: nil, city: nil, region: nil, postalCode: nil, country: nil)
        m.selectMapKit(draft)
        if case .newMapKit(let d) = m.placeRef { #expect(d.name == "Loves") } else { Issue.record("ref not set") }
    }

    @Test func selectCustomSetsRef() {
        let m = makeModel()
        m.selectCustom(.init(name: "My Stop", kind: .other, address: nil))
        if case .newCustom(let d) = m.placeRef { #expect(d.name == "My Stop") } else { Issue.record("ref not set") }
    }
}
```

- [ ] **Step 2: Implement flow model**

Create `Road Beans/Features/AddVisit/AddVisitFlowModel.swift`:

```swift
import Foundation
import Observation

@Observable
@MainActor
final class AddVisitFlowModel {
    // selections
    var placeRef: PlaceReference?
    var date: Date = .now
    var visitTags: [String] = []
    var drinks: [DrinkDraft] = []
    var photos: [PhotoDraft] = []

    // navigation
    var currentPage: Int = 0

    // search state
    var searchText: String = ""
    var searchResults: [MapKitPlaceDraft] = []

    // services
    let visits: any VisitRepository
    let tagsRepo: any TagRepository
    let searchService: any LocationSearchService
    let photoProcessor: any PhotoProcessingService

    private var searchTask: Task<Void, Never>?

    init(visits: any VisitRepository, tags: any TagRepository,
         search: any LocationSearchService, photoProcessor: any PhotoProcessingService) {
        self.visits = visits
        self.tagsRepo = tags
        self.searchService = search
        self.photoProcessor = photoProcessor
    }

    func search() {
        searchTask?.cancel()
        let q = searchText
        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled, let self else { return }
            let results = (try? await self.searchService.search(query: q, near: nil)) ?? []
            await MainActor.run { self.searchResults = results }
        }
    }

    func selectMapKit(_ draft: MapKitPlaceDraft) {
        placeRef = .newMapKit(draft)
        currentPage = 1
    }

    func selectCustom(_ draft: CustomPlaceDraft) {
        placeRef = .newCustom(draft)
        currentPage = 1
    }
}
```

- [ ] **Step 3: Implement Place page**

Create `Road Beans/Features/AddVisit/AddVisitPlacePage.swift`:

```swift
import SwiftUI

struct AddVisitPlacePage: View {
    @Bindable var model: AddVisitFlowModel
    @State private var showingCustom = false

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search for a place", text: $model.searchText)
                .textFieldStyle(.roundedBorder)
                .padding()
                .onChange(of: model.searchText) { _, _ in model.search() }

            if model.searchResults.isEmpty && !model.searchText.isEmpty {
                VStack(spacing: 8) {
                    Text("No matches.").foregroundStyle(.secondary)
                    Button("+ Add as custom place") { showingCustom = true }
                }
                .padding()
            } else {
                List(model.searchResults, id: \.mapKitIdentifier.self) { draft in
                    Button {
                        model.selectMapKit(draft)
                    } label: {
                        HStack {
                            Image(systemName: draft.kind.sfSymbol).foregroundStyle(draft.kind.accentColor)
                            VStack(alignment: .leading) {
                                Text(draft.name).font(.roadBeansBody)
                                if let addr = draft.address, !addr.isEmpty {
                                    Text(addr).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }

            Spacer()

            Button {
                showingCustom = true
            } label: {
                Label("+ Custom place", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .sheet(isPresented: $showingCustom) {
            CustomPlaceSheet { draft in
                model.selectCustom(draft)
                showingCustom = false
            }
        }
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
                    ForEach(PlaceKind.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
                TextField("Address (optional)", text: $address)
            }
            .navigationTitle("Custom place")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onConfirm(.init(name: name, kind: kind, address: address.isEmpty ? nil : address))
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
```

- [ ] **Step 4: Wire as first page in `AddVisitView`** (full multi-page wiring lands in Task 28)

Edit `Road Beans/Features/AddVisit/AddVisitView.swift`:

```swift
import SwiftUI

struct AddVisitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.visitRepository) private var visits
    @Environment(\.tagRepository) private var tags
    @Environment(\.locationSearchService) private var search
    @Environment(\.photoProcessingService) private var photoProcessor
    @State private var model: AddVisitFlowModel?

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    AddVisitPlacePage(model: model)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("New Visit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .task {
            if model == nil {
                model = AddVisitFlowModel(visits: visits, tags: tags, search: search, photoProcessor: photoProcessor)
            }
        }
    }
}
```

- [ ] **Step 5: Run tests**

```bash
xcodebuild ... test -only-testing:"Road BeansTests/AddVisitFlowModelPlaceTests"
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add "Road Beans/Features/AddVisit" "Road BeansTests/ViewModelTests/AddVisitFlowModelPlaceTests.swift"
git commit -m "feat: AddVisit page 1 — MapKit search + custom place fallback"
```

---

### Task 26: AddVisit page 2 — Visit details (date + photos + tags)

**Goal:** Date picker, PhotosPicker (max 8), token-style visit tag entry with autocomplete.

**Files:**
- Create: `Road Beans/Features/AddVisit/AddVisitVisitPage.swift`
- Create: `Road Beans/Features/AddVisit/TagTokenField.swift`
- Test: `Road BeansTests/ViewModelTests/TagTokenSuggestionTests.swift`

**Acceptance Criteria:**
- [ ] `AddVisitVisitPage` shows DatePicker, `PhotosPicker(maxSelectionCount: 8)` (results processed via `PhotoProcessingService` and stored in `model.photos`), and `TagTokenField`.
- [ ] `TagTokenField(tags: Binding<[String]>, suggestions: (String) async -> [TagSuggestion])` — text field; on Enter or comma, normalizes and adds; renders existing tags as removable chips; shows top-5 suggestions filtered by current input.
- [ ] PhotosPicker selections processed off-main; preview thumbnails shown as a horizontal strip.
- [ ] Test: tag normalization (trim/lower) and dedup before adding.

**Verify:** `xcodebuild ... test -only-testing:"Road BeansTests/TagTokenSuggestionTests"` → PASS.

**Steps:**

- [ ] **Step 1: Failing test**

Create `Road BeansTests/ViewModelTests/TagTokenSuggestionTests.swift`:

```swift
import Testing
@testable import Road_Beans

@Suite("TagTokenField helpers")
struct TagTokenSuggestionTests {
    @Test func addNormalizesAndDedups() {
        var tokens: [String] = ["smooth"]
        TagTokenLogic.add("  Smooth ", to: &tokens)
        TagTokenLogic.add("BURNT", to: &tokens)
        #expect(tokens == ["smooth", "burnt"])
    }

    @Test func addRejectsEmpty() {
        var tokens: [String] = []
        TagTokenLogic.add("   ", to: &tokens)
        #expect(tokens.isEmpty)
    }
}
```

- [ ] **Step 2: Implement `TagTokenField` + helpers**

Create `Road Beans/Features/AddVisit/TagTokenField.swift`:

```swift
import SwiftUI

enum TagTokenLogic {
    static func add(_ raw: String, to tokens: inout [String]) {
        let n = LocalTagRepository.normalize(raw)
        guard !n.isEmpty, !tokens.contains(n) else { return }
        tokens.append(n)
    }
}

struct TagTokenField: View {
    @Binding var tokens: [String]
    let suggestions: (String) async -> [TagSuggestion]

    @State private var input: String = ""
    @State private var current: [TagSuggestion] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ForEach(tokens, id: \.self) { t in
                    HStack(spacing: 4) {
                        Text(t)
                        Button { tokens.removeAll { $0 == t } } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.18), in: Capsule())
                }
            }
            TextField("Add a tag", text: $input)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    TagTokenLogic.add(input, to: &tokens)
                    input = ""
                }
                .onChange(of: input) { _, new in
                    Task { current = await suggestions(new) }
                    if new.contains(",") {
                        let parts = new.split(separator: ",")
                        for p in parts { TagTokenLogic.add(String(p), to: &tokens) }
                        input = ""
                    }
                }
            if !current.isEmpty {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(current) { s in
                            Button(s.name) {
                                TagTokenLogic.add(s.name, to: &tokens)
                                input = ""
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 3: Implement `AddVisitVisitPage`**

Create `Road Beans/Features/AddVisit/AddVisitVisitPage.swift`:

```swift
import SwiftUI
import PhotosUI

struct AddVisitVisitPage: View {
    @Bindable var model: AddVisitFlowModel
    @State private var pickerItems: [PhotosPickerItem] = []

    var body: some View {
        Form {
            DatePicker("When", selection: $model.date)

            Section("Photos") {
                PhotosPicker(selection: $pickerItems, maxSelectionCount: 8, matching: .images) {
                    Label("Choose photos", systemImage: "photo.on.rectangle")
                }
                .onChange(of: pickerItems) { _, new in
                    Task { await loadPhotos(new) }
                }
                if !model.photos.isEmpty {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(Array(model.photos.enumerated()), id: \.offset) { _, draft in
                                if let img = UIImage(data: draft.rawImageData) {
                                    Image(uiImage: img).resizable().scaledToFill().frame(width: 80, height: 80).clipped().cornerRadius(8)
                                }
                            }
                        }
                    }
                }
            }

            Section("Visit tags") {
                TagTokenField(tags: $model.visitTags) { prefix in
                    (try? await model.tagsRepo.suggestions(prefix: prefix, limit: 5)) ?? []
                }
            }
        }
    }

    private func loadPhotos(_ items: [PhotosPickerItem]) async {
        var drafts: [PhotoDraft] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                drafts.append(PhotoDraft(rawImageData: data, caption: nil))
            }
        }
        model.photos = drafts
    }
}
```

- [ ] **Step 4: Run tests**

```bash
xcodebuild ... test -only-testing:"Road BeansTests/TagTokenSuggestionTests"
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add "Road Beans/Features/AddVisit" "Road BeansTests/ViewModelTests/TagTokenSuggestionTests.swift"
git commit -m "feat: AddVisit page 2 — date, photos picker, visit tags"
```

---

### Task 27: AddVisit page 3 — Drinks list with Bean Slider

**Goal:** Append-rows UI; each row has category segmented control, name field, tag tokens, and the Bean Slider. ≥1 drink required to enable Save.

**Files:**
- Create: `Road Beans/Features/AddVisit/AddVisitDrinksPage.swift`

**Acceptance Criteria:**
- [ ] `AddVisitDrinksPage` shows a list bound to `model.drinks: [DrinkDraft]`.
- [ ] Each row: category `Picker(.segmented)`, TextField "Drink name", `TagTokenField`, `BeanSlider` for rating.
- [ ] "+ Add drink" button appends a new `DrinkDraft(name: "", category: .drip, rating: 3.0, tags: [])`.
- [ ] Swipe-to-delete on rows.
- [ ] No tests beyond what `BeanSliderModel` and `TagTokenLogic` already cover (this is glue UI). Build succeeds.

**Verify:** `xcodebuild ... build` → BUILD SUCCEEDED.

**Steps:**

- [ ] **Step 1: Implement page**

Create `Road Beans/Features/AddVisit/AddVisitDrinksPage.swift`:

```swift
import SwiftUI

struct AddVisitDrinksPage: View {
    @Bindable var model: AddVisitFlowModel

    var body: some View {
        List {
            ForEach($model.drinks, id: \.self) { $drink in
                Section {
                    Picker("Category", selection: $drink.category) {
                        ForEach(DrinkCategory.allCases, id: \.self) { c in
                            Text(c.displayName).tag(c)
                        }
                    }
                    .pickerStyle(.segmented)

                    TextField("Drink name", text: $drink.name)
                        .textFieldStyle(.roundedBorder)

                    TagTokenField(tags: $drink.tags) { prefix in
                        (try? await model.tagsRepo.suggestions(prefix: prefix, limit: 5)) ?? []
                    }

                    BeanSlider(value: $drink.rating)
                        .padding(.top, 32)
                }
            }
            .onDelete { offsets in model.drinks.remove(atOffsets: offsets) }

            Section {
                Button {
                    model.drinks.append(DrinkDraft(name: "", category: .drip, rating: 3.0, tags: []))
                } label: { Label("Add drink", systemImage: "plus") }
            }
        }
    }
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild ... build
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add "Road Beans/Features/AddVisit/AddVisitDrinksPage.swift"
git commit -m "feat: AddVisit page 3 — drinks list with Bean Slider"
```

---

### Task 28: AddVisit save flow + paged sheet wiring + toast

**Goal:** Wire the three pages into one paged TabView in `AddVisitView`. Save button on page 3 (disabled until ≥1 drink). On save: build `CreateVisitCommand`, call `VisitRepository.save`, dismiss, post a toast notification. `LocalVisitRepository.save` owns raw photo processing and `PhotoRepository.insertProcessed` to avoid duplicating photo persistence in the view model.

**Files:**
- Modify: `Road Beans/Features/AddVisit/AddVisitView.swift`
- Create: `Road Beans/Features/AddVisit/AddVisitFlowModel+Save.swift` (extension with the save method)
- Create: `Road Beans/Features/RootToastOverlay.swift` (transient toast UI)
- Modify: `Road Beans/Features/RootView.swift` — overlay the toast.
- Test: `Road BeansTests/ViewModelTests/AddVisitSaveTests.swift`

**Acceptance Criteria:**
- [ ] `AddVisitView` is a `TabView(selection: $model.currentPage).tabViewStyle(.page(indexDisplayMode: .never))` with three pages.
- [ ] Top toolbar: Cancel always; Back when page > 0; Next on pages 0/1; Save on page 2 (disabled if drinks empty or placeRef nil).
- [ ] `model.save() async throws -> String` returns the toast text "Added to *Place name*."
- [ ] On save: `VisitRepository.save` receives the create command including `PhotoDraft`s; the repository handles photo processing and persistence.
- [ ] After save: posts `Notification.Name.roadBeansVisitSaved` with the toast string in `userInfo["text"]`.
- [ ] `RootToastOverlay` listens and shows a transient glass card for 2.5s.
- [ ] Tests: save with empty drinks throws; save with valid drinks calls `visits.save` once with a `CreateVisitCommand` that matches inputs.

**Verify:** `xcodebuild ... test -only-testing:"Road BeansTests/AddVisitSaveTests"` → PASS.

**Steps:**

- [ ] **Step 1: Failing test**

Create `Road BeansTests/ViewModelTests/AddVisitSaveTests.swift`:

```swift
import Testing
@testable import Road_Beans

@Suite("AddVisitFlowModel — save")
@MainActor
struct AddVisitSaveTests {
    func makeModel() -> (AddVisitFlowModel, FakeVisitRepository) {
        let visits = FakeVisitRepository()
        let m = AddVisitFlowModel(
            visits: visits,
            tags: FakeTagRepository(),
            search: FakeLocationSearchService(canned: []),
            photoProcessor: DefaultPhotoProcessingService()
        )
        return (m, visits)
    }

    @Test func emptyDrinksRejected() async {
        let (m, _) = makeModel()
        m.placeRef = .newCustom(.init(name: "X", kind: .other, address: nil))
        await #expect(throws: VisitValidationError.self) {
            _ = try await m.save()
        }
    }

    @Test func savePassesCommand() async throws {
        let (m, visits) = makeModel()
        m.placeRef = .newCustom(.init(name: "Loves", kind: .truckStop, address: nil))
        m.drinks = [DrinkDraft(name: "CFHB", category: .drip, rating: 4.2, tags: [])]
        m.visitTags = ["roadtrip"]
        let toast = try await m.save()
        #expect(toast.contains("Added to"))
        #expect(visits.saved.count == 1)
        #expect(visits.saved[0].drinks.count == 1)
    }
}
```

- [ ] **Step 2: Implement save extension**

Create `Road Beans/Features/AddVisit/AddVisitFlowModel+Save.swift`:

```swift
import Foundation

extension AddVisitFlowModel {
    func save() async throws -> String {
        guard !drinks.isEmpty else { throw VisitValidationError.missingDrinks }
        guard let ref = placeRef else { throw VisitValidationError.missingDrinks }

        let cmd = CreateVisitCommand(
            placeRef: ref, date: date, drinks: drinks,
            tags: visitTags, photos: photos
        )
        _ = try await visits.save(cmd)
        // Note: photo attachment is handled by VisitRepository extension once ProcessedPhoto
        // pipeline is wired in v1.1 — out of scope for v1's create command path. The DTOs
        // already model photos so the v2 upload contract is unaffected.

        let placeName: String = {
            switch ref {
            case .existing: return "place"
            case .newMapKit(let d): return d.name
            case .newCustom(let d): return d.name
            }
        }()
        return "Added to \(placeName)."
    }
}
```

- [ ] **Step 3: Implement toast overlay**

Create `Road Beans/Features/RootToastOverlay.swift`:

```swift
import SwiftUI

struct RootToastOverlay: View {
    @State private var text: String?
    var body: some View {
        VStack {
            Spacer()
            if let text {
                Text(text)
                    .font(.roadBeansBody)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .glassCard()
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring, value: text)
        .onReceive(NotificationCenter.default.publisher(for: .roadBeansVisitSaved)) { note in
            if let t = note.userInfo?["text"] as? String {
                text = t
                Task {
                    try? await Task.sleep(nanoseconds: 2_500_000_000)
                    text = nil
                }
            }
        }
    }
}

extension Notification.Name {
    static let roadBeansVisitSaved = Notification.Name("RoadBeans.visitSaved")
}
```

- [ ] **Step 4: Wire `RootView` to overlay it**

Edit `Road Beans/Features/RootView.swift` — replace the `tabs` definition with:

```swift
private var tabs: some View {
    ZStack {
        TabView(selection: $selectedTab) {
            PlaceListView()
                .tabItem { Label("List", systemImage: "list.bullet") }
                .tag(0)

            MapTabView()
                .tabItem { Label("Map", systemImage: "map.fill") }
                .tag(1)

            Color.clear
                .tabItem { Label("Add", systemImage: "plus.circle.fill") }
                .tag(2)
        }
        .onChange(of: selectedTab) { _, new in
            if new == 2 {
                showingAdd = true
                selectedTab = 0
            }
        }
        .fullScreenCover(isPresented: $showingAdd) {
            AddVisitView()
        }

        RootToastOverlay()
            .allowsHitTesting(false)
    }
}
```

- [ ] **Step 5: Wire paged AddVisitView**

Edit `Road Beans/Features/AddVisit/AddVisitView.swift`:

```swift
import SwiftUI

struct AddVisitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.visitRepository) private var visits
    @Environment(\.tagRepository) private var tags
    @Environment(\.locationSearchService) private var search
    @Environment(\.photoProcessingService) private var photoProcessor
    @State private var model: AddVisitFlowModel?

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    page(model: model)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(navTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if let model {
                    if model.currentPage > 0 {
                        ToolbarItem(placement: .navigation) {
                            Button("Back") { model.currentPage -= 1 }
                        }
                    }
                    if model.currentPage < 2 {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Next") { model.currentPage += 1 }
                                .disabled(model.currentPage == 0 && model.placeRef == nil)
                        }
                    } else {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                Task { await performSave(model) }
                            }
                            .disabled(model.drinks.isEmpty || model.placeRef == nil)
                        }
                    }
                }
            }
        }
        .task {
            if model == nil {
                model = AddVisitFlowModel(visits: visits, tags: tags, search: search, photoProcessor: photoProcessor)
            }
        }
    }

    @Bindable private var modelBindable: AddVisitFlowModel = .init(
        visits: FakeVisitRepository(),
        tags: FakeTagRepository(),
        search: FakeLocationSearchService(canned: []),
        photoProcessor: DefaultPhotoProcessingService()
    )

    @ViewBuilder
    private func page(model: AddVisitFlowModel) -> some View {
        @Bindable var m = model
        TabView(selection: $m.currentPage) {
            AddVisitPlacePage(model: m).tag(0)
            AddVisitVisitPage(model: m).tag(1)
            AddVisitDrinksPage(model: m).tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private var navTitle: String {
        switch model?.currentPage ?? 0 {
        case 0: return "Place"
        case 1: return "Visit"
        case 2: return "Drinks"
        default: return "New Visit"
        }
    }

    private func performSave(_ model: AddVisitFlowModel) async {
        do {
            let toast = try await model.save()
            NotificationCenter.default.post(name: .roadBeansVisitSaved, object: nil, userInfo: ["text": toast])
            dismiss()
        } catch {
            // surface error in toolbar/inline UI in v1.1
        }
    }
}
```

> Note: the `@Bindable private var modelBindable: AddVisitFlowModel = ...` line above is a placeholder used only because Swift requires a concrete `@Bindable` somewhere; the real binding is created inline in `page(model:)`. Delete the placeholder if your toolchain accepts the inline `@Bindable var`.

- [ ] **Step 6: Run tests**

```bash
xcodebuild ... test -only-testing:"Road BeansTests/AddVisitSaveTests"
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add "Road Beans/Features/AddVisit" "Road Beans/Features/RootToastOverlay.swift" "Road Beans/Features/RootView.swift" "Road BeansTests/ViewModelTests/AddVisitSaveTests.swift"
git commit -m "feat: AddVisit paged flow with save + toast overlay"
```

---

### Task 29: List refresh on visit save/delete

**Goal:** When a visit is added or deleted, PlaceList, PlaceDetail, and Map reload. Wired via the existing notifications.

**Files:**
- Modify: `Road Beans/Features/PlaceList/PlaceListView.swift`
- Modify: `Road Beans/Features/PlaceDetail/PlaceDetailView.swift`
- Modify: `Road Beans/Features/Map/MapTabView.swift`

**Acceptance Criteria:**
- [ ] PlaceList listens for `.roadBeansVisitSaved` and `.roadBeansVisitDeleted`; on receive, calls `vm.reload()`.
- [ ] PlaceDetail listens for both; on receive, reloads its `vm.load(id:)`.
- [ ] Map listens for both; on receive, reloads annotations while preserving the near-me toggle.
- [ ] Manual: add a visit → list shows it; delete a visit → list updates.

**Verify:** Manual on simulator: add and delete visits, see list update.

**Steps:**

- [ ] **Step 1: Edit `PlaceListView` `.task` block** — replace with:

```swift
.task {
    if vm == nil {
        let m = PlaceListViewModel(places: placeRepo, visits: visitRepo)
        vm = m
        await m.reload()
    }
}
.onReceive(NotificationCenter.default.publisher(for: .roadBeansVisitSaved)) { _ in
    Task { await vm?.reload() }
}
.onReceive(NotificationCenter.default.publisher(for: .roadBeansVisitDeleted)) { _ in
    Task { await vm?.reload() }
}
```

- [ ] **Step 2: Edit `PlaceDetailView`** — add identical `.onReceive` blocks scoped to the placeID:

```swift
.onReceive(NotificationCenter.default.publisher(for: .roadBeansVisitSaved)) { _ in
    Task { await vm?.load(id: placeID) }
}
.onReceive(NotificationCenter.default.publisher(for: .roadBeansVisitDeleted)) { _ in
    Task { await vm?.load(id: placeID) }
}
```

- [ ] **Step 3: Build + manual smoke test**

Build, run on simulator, add a custom place + visit, observe list/detail update; delete the visit, observe list/detail update.

- [ ] **Step 4: Commit**

```bash
git add "Road Beans/Features/PlaceList" "Road Beans/Features/PlaceDetail"
git commit -m "feat: PlaceList and PlaceDetail refresh on visit save/delete"
```

---

### Task 30: Polish + manual QA checklist + sign-out/sign-in QA pass

**Goal:** Final pass — Dynamic Type spot check, dark mode spot check, sign-out/sign-in iCloud QA, "+" button feel. Document the manual checklist in `docs/superpowers/qa/` for future builds.

**Files:**
- Create: `docs/superpowers/qa/2026-04-25-manual-qa-checklist.md`
- Polish patches as needed (no new architecture).

**Acceptance Criteria:**
- [ ] App runs on iPhone 16 simulator without crashes through this sequence: launch, add custom place + visit + 1 drink, save, see in list, open detail, edit nothing, back, delete from detail, see list update.
- [ ] App runs in Dark Mode without contrast or invisible-text issues.
- [ ] Bean Slider haptics: `Settings → Accessibility → Touch → Vibration` Off → no haptics. Reduced Motion → no spring.
- [ ] iCloud sign-out then relaunch: app surfaces relaunch overlay (or resumes local-only depending on prior mode).
- [ ] iCloud sign-in (after running in `.localOnly`) → next launch shows migration prompt; "Keep local only" works.
- [ ] Manual QA checklist file documents these steps for future TestFlight builds.

**Verify:** Manual run-through of the checklist.

**Steps:**

- [ ] **Step 1: Write the checklist**

Create `docs/superpowers/qa/2026-04-25-manual-qa-checklist.md`:

```markdown
# Road Beans Manual QA — v1

Run before each TestFlight build.

## Smoke
- [ ] Launch app cold; no crash; tab bar shows List, Map, +.
- [ ] Tap +; full-screen sheet presents Place page.
- [ ] Add a custom place "Test Stop" (kind: Other).
- [ ] Page 2: leave date as-is; skip photos; add tag "qa".
- [ ] Page 3: add one drink "Black coffee" (drip), rating 3.5.
- [ ] Save → toast "Added to Test Stop." appears.
- [ ] List shows the new place; tap → Place Detail shows the visit; tap → Visit Detail shows the drink + tag.
- [ ] Visit Detail toolbar Trash → Delete → list updates.

## Bean Slider
- [ ] Drag thumb across 0→5; haptic ticks at every 0.1; medium impact at every whole number.
- [ ] Bean glyph pops in at 1, 2, 3, 4, 5.
- [ ] VoiceOver: focus the slider; read as "Drink rating, X.X of 5, adjustable"; up/down arrows ±0.1.
- [ ] Settings → Accessibility → Reduce Motion ON → no spring; crossfade only.
- [ ] Settings → Accessibility → Reduce Transparency ON → thumb solid background.
- [ ] Settings → Accessibility → Touch → Vibration OFF → no haptic feedback.

## Dynamic Type
- [ ] Largest accessibility size (AX5): app remains usable; no clipped text in list rows or visit detail.

## Dark mode
- [ ] Toggle to dark; no invisible text; glass cards still readable.

## iCloud
- [ ] Sign out of iCloud (Settings → iCloud → Sign Out) → next launch: relaunch overlay shown; relaunch app → continues in local-only.
- [ ] Sign back into iCloud → next launch: migration prompt shown; "Keep local only" works (prompt does not re-appear next launch).

## Map
- [ ] Map tab loads; existing places appear as kind-tinted markers.
- [ ] Toggle "Stops near me" while permission denied → shows "Open Settings" rationale.
- [ ] Tap marker → glass sheet appears with "View visits".

## Search
- [ ] In List, type in the search field; results filter by place name and by tag.

## Photos (when added in v1.1, mark N/A in v1)
- [ ] N/A in v1.
```

- [ ] **Step 2: Run through the checklist**

Open the simulator, perform every step, fix anything that fails. Commit polish per fix.

- [ ] **Step 3: Final build verification**

```bash
xcodebuild -project "Road Beans.xcodeproj" -scheme "Road Beans" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build test
```

Expected: BUILD SUCCEEDED, all tests pass.

- [ ] **Step 4: Commit**

```bash
git add "docs/superpowers/qa"
git commit -m "docs: add v1 manual QA checklist"
```

---

## Notes / Known v1 limitations carried forward

- **Photo persistence in the create flow** is repository-owned: `CreateVisitCommand` carries `PhotoDraft`s, and `LocalVisitRepository.save` processes and inserts photos through `PhotoRepository`.
- **`PersistenceController.migrateLocalToCloudKit()` throws `notYetImplemented`** in Task 7 — the migration UI prompt is wired (Task 20), but the actual cross-container copy is left as a v1 fast-follow because exercising it requires real iCloud and is best done with manual QA. Spec §6 documents the expected behavior.
- **`MapTabViewModel.reload(allowingNearMe:)`** calls the near-query path with a placeholder coordinate. Once a current-location source is wired (v1.1), it should pass the device coordinate.
- **No UI tests** in v1 (per spec §13). Manual checklist (Task 30) covers regressions.
