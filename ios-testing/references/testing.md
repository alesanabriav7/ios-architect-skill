# Testing, Concurrency, and DI

Use this file for Swift Testing patterns, mock repositories, DI wiring, and performance guidance.

## Concurrency Rules

Concurrency rules are defined in `ios-architect/references/testing-concurrency-di.md`. Apply those rules here. The canonical source is that file.

## Dependency Injection Pattern

Use protocol-driven constructor injection with concrete defaults.

```swift
import Foundation

struct {Entity}Filter: Sendable {
    var isCompleted: Bool?
    var searchText: String?
}

protocol {Entity}RepositoryProtocol: Sendable {
    func save(_ item: {Entity}) async throws
    func delete(_ item: {Entity}) async throws
    func fetchByID(_ id: String) async throws -> {Entity}?
    func fetchAll() async throws -> [{Entity}]
    func fetch(matching filter: {Entity}Filter) async throws -> [{Entity}]
}

final class {Entity}Repository: {Entity}RepositoryProtocol, Sendable {
    func save(_ item: {Entity}) async throws { }
    func delete(_ item: {Entity}) async throws { }
    func fetchByID(_ id: String) async throws -> {Entity}? { nil }
    func fetchAll() async throws -> [{Entity}] { [] }
    func fetch(matching filter: {Entity}Filter) async throws -> [{Entity}] { [] }
}

@Observable
@MainActor
final class {Feature}ViewModel {
    private let repository: {Entity}RepositoryProtocol

    init(repository: {Entity}RepositoryProtocol = {Entity}Repository()) {
        self.repository = repository
    }
}
```

Use a DI container only if module count and composition complexity require it.

For Foundation Models DI/mocking patterns, see the `ios-platform` skill.

## Swift Testing Baseline

Use Swift Testing (`import Testing`) for new tests.

```swift
import Testing
@testable import {AppName}

@Suite("{Feature}ViewModel Tests")
struct {Feature}ViewModelTests {
    @Test("loads items from repository")
    @MainActor
    func loadItems_populatesState() async throws {
        let repo = Mock{Entity}Repository(seed: [make{Entity}(), make{Entity}()])
        let vm = {Feature}ViewModel(repository: repo)
        await vm.loadItems()
        #expect(vm.items.count == 2)
    }
}
```

## Test Data Factory

```swift
import Foundation

func make{Entity}(
    id: String = UUID().uuidString,
    title: String = "Test",
    details: String = "",
    isCompleted: Bool = false,
    createdAt: Date = .now,
    updatedAt: Date = .now
) -> {Entity} {
    {Entity}(
        id: id,
        title: title,
        details: details,
        isCompleted: isCompleted,
        createdAt: createdAt,
        updatedAt: updatedAt
    )
}
```

## Mock Repository (Thread-safe)

```swift
actor Mock{Entity}Repository: {Entity}RepositoryProtocol {
    private var items: [{Entity}]

    init(seed: [{Entity}] = []) {
        items = seed
    }

    func save(_ item: {Entity}) async throws { items.append(item) }
    func delete(_ item: {Entity}) async throws { items.removeAll { $0.id == item.id } }
    func fetchByID(_ id: String) async throws -> {Entity}? { items.first { $0.id == id } }
    func fetchAll() async throws -> [{Entity}] { items }
    func fetch(matching filter: {Entity}Filter) async throws -> [{Entity}] {
        items.filter { item in
            let matchesCompletion: Bool = {
                guard let isCompleted = filter.isCompleted else { return true }
                return item.isCompleted == isCompleted
            }()

            let matchesSearch: Bool = {
                guard let searchText = filter.searchText?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !searchText.isEmpty else { return true }
                return item.title.localizedStandardContains(searchText) ||
                       item.details.localizedStandardContains(searchText)
            }()

            return matchesCompletion && matchesSearch
        }
    }
}
```

## Known Pitfalls

### `@State` with `@Observable` Initializer

Unlike `@StateObject`, the initializer of an `@Observable` object stored in `@State` may run multiple times during view lifetime. SwiftUI may recreate the `@State` wrapper during view updates.

- Never perform side effects (network calls, database writes) in `@Observable` initializers.
- Never do expensive work (parsing, file I/O) in `init()`.
- Prefer injecting dependencies externally rather than creating them inside `init()`.

```swift
// Correct — no side effects in init
@Observable
@MainActor
final class {Feature}ViewModel {
    var items: [{Entity}] = []
    private let repository: {Entity}RepositoryProtocol

    init(repository: {Entity}RepositoryProtocol = {Entity}Repository()) {
        self.repository = repository
        // Do NOT call loadItems() here
    }

    func loadItems() async { /* ... */ }
}

// In view — trigger load via .task
struct {Feature}View: View {
    @State private var viewModel = {Feature}ViewModel()

    var body: some View {
        List(viewModel.items) { /* ... */ }
            .task { await viewModel.loadItems() }
    }
}
```

## Performance

- Always profile on real devices — simulators can deviate up to 30% in CPU and memory behavior.
- Use the SwiftUI Instrument in Xcode 26 (Cause & Effect graph) to track unnecessary view updates and identify which state changes trigger re-renders.
- Use `@ObservationIgnored` for stored properties in `@Observable` classes that do not affect the UI (caches, internal flags, logging state). This prevents unnecessary view invalidation.

```swift
@Observable
@MainActor
final class {Feature}ViewModel {
    var items: [{Entity}] = []
    @ObservationIgnored private var lastFetchDate: Date?
    @ObservationIgnored private var retryCount = 0
}
```

- Use `LazyVStack` / `LazyVGrid` for scrollable lists with more than a screenful of content. Eager `VStack` loads all children immediately and causes frame drops on large data sets.
- Use `os_signpost` for custom performance markers in critical code paths:

```swift
import os

let perfLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "{AppName}", category: .pointsOfInterest)

func loadItems() async {
    os_signpost(.begin, log: perfLog, name: "LoadItems")
    defer { os_signpost(.end, log: perfLog, name: "LoadItems") }
    // ...
}
```

- Target 16.67ms frame budget for 60fps. Any work exceeding this on the main thread causes visible jank — offload to `@concurrent` functions or background actors.

## Screenshot Automation and Visual QA

For screenshot capture, preview repositories, visual regression workflows, and batch capture scripts, see `references/screenshots.md`.

## Mock Deep Link Resolver

Use in tests to return predetermined destinations without network or database access:

```swift
actor MockDeepLinkResolver: DeepLinkResolverProtocol {
    private var stubbedResults: [URL: DeepLinkDestination] = [:]

    func stub(url: URL, destination: DeepLinkDestination) {
        stubbedResults[url] = destination
    }

    func resolve(_ url: URL) async throws -> DeepLinkDestination? {
        stubbedResults[url]
    }
}
```

## View Testing

Write view tests for critical user-facing state transitions, not for layout or visual details (leave those to ios-visual).

### When to Write View Tests vs. ViewModel Tests

- **ViewModel tests**: logic, state changes, async flows, error handling — cover these first.
- **View tests**: write only when the view has conditional rendering that a ViewModel test cannot cover, or when a navigation trigger (sheet presentation, navigation push) must be verified at the view level.

### Testing Navigation Triggers

Test sheet presentation and navigation push through ViewModel state — not by inspecting the SwiftUI view hierarchy:

```swift
import Testing
@testable import {AppName}

@Suite("{Feature} Navigation Tests")
struct {Feature}NavigationTests {
    @Test("presents new sheet on FAB tap")
    @MainActor
    func tapFAB_presentsSheet() async throws {
        let vm = {Feature}ViewModel(repository: Mock{Entity}Repository())
        vm.presentNewSheet()
        #expect(vm.activeSheet == .new)
    }

    @Test("dismisses sheet after save")
    @MainActor
    func save_dismissesSheet() async throws {
        let repo = Mock{Entity}Repository()
        let vm = {Feature}ViewModel(repository: repo)
        vm.activeSheet = .new
        let formVM = {Entity}FormViewModel(repository: repo)
        formVM.title = "Test"
        try await formVM.save()
        vm.activeSheet = nil
        #expect(vm.activeSheet == nil)
    }
}
```

### What NOT to Test in Views

- Layout specifics (padding values, frame sizes) — belongs in ios-visual
- Colors, fonts, or spacing tokens — belongs in ios-visual
- Pixel-level appearance — belongs in ios-visual

### Integration with ios-visual

View tests verify behavioral correctness (is the right sheet presented?). ios-visual verifies visual correctness (does it look right?). Both are needed for a complete quality gate.

## Minimal Test Coverage Expectations

For each new feature:

- View model happy path + failure path.
- Repository mapping and filtering logic.
- Critical business service logic.
- At least one integration-style test for persistence-backed flows when feasible.
- If AI is used: see the `ios-platform` skill for AI-specific test patterns.
