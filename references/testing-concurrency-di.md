# Testing, Concurrency, and DI

Use this file for quality gates, thread-safety, and dependency wiring.

## Concurrency Rules

- View models: `@Observable` + `@MainActor`.
- Repository protocols: `Sendable`.
- Repository implementations: `final class` + `Sendable`.
- Shared mutable caches: `actor`.
- Async work: `async/await` with `async throws`.
- Avoid Combine and completion handlers for new code.
- Prefer actors over `@unchecked Sendable` with manual synchronization.

## Swift 6.2 Approachable Concurrency

Swift 6.2 introduces `defaultIsolation` to reduce annotation noise. Adopt incrementally.

### Module-Level Default Isolation

Set `MainActor` as the default isolation for your app/feature modules in `Package.swift`:

```swift
.target(
    name: "{AppName}",
    dependencies: [...],
    swiftSettings: [.defaultIsolation(MainActor.self)]
)
```

With this setting, all types in the module are implicitly `@MainActor`. The explicit `@MainActor` annotation on ViewModels becomes optional (but harmless to keep for clarity).

### `@concurrent` Attribute

Use `@concurrent` to explicitly move async work off the main actor. This replaces the previous pattern of implicitly dispatching to the global concurrent executor:

```swift
@concurrent
func fetchFromNetwork() async throws -> [Item] {
    // Runs off the main actor even with defaultIsolation(MainActor.self)
    let (data, _) = try await session.data(from: url)
    return try decoder.decode([Item].self, from: data)
}
```

### `nonisolated` Semantics in 6.2

In Swift 6.2, `nonisolated` inherits the caller's actor context — it no longer implies "runs off-actor." To explicitly run off-actor, combine both:

```swift
@concurrent nonisolated
func processData(_ input: Data) -> Result {
    // Guaranteed to run off the calling actor
}
```

Use plain `nonisolated` only for synchronous computed properties or protocol conformances where caller-context inheritance is correct.

### Incremental Migration Path

1. Enable `-strict-concurrency=complete` in Swift 5 language mode first.
2. Fix all warnings (missing `Sendable`, data races, isolation gaps).
3. Flip to Swift 6 language mode per module once warnings are resolved.
4. Optionally add `defaultIsolation(MainActor.self)` to reduce annotation noise in UI-heavy modules.

### Caution: `@unchecked Sendable`

Avoid `@unchecked Sendable` — it silences the compiler without guaranteeing safety. Prefer:
- `actor` for types with mutable shared state.
- `@MainActor` for UI-bound types.
- Value types (`struct`, `enum`) which are implicitly `Sendable` when all stored properties are `Sendable`.

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
    func fetchAll() async throws -> [{Entity}]
    func fetch(matching filter: {Entity}Filter) async throws -> [{Entity}]
}

final class {Entity}Repository: {Entity}RepositoryProtocol, Sendable {
    func save(_ item: {Entity}) async throws { }
    func delete(_ item: {Entity}) async throws { }
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

## Foundation Models DI Pattern (When AI Is Used)

Never couple `LanguageModelSession` directly to view models. Inject a protocol from Domain and keep Foundation Models in Data.

```swift
import Foundation

protocol {Feature}InsightGeneratorProtocol: Sendable {
    func generate(from input: {Feature}InsightInput) async throws -> {Feature}Insight
}

@Observable
@MainActor
final class {Feature}ViewModel {
    private let insightGenerator: {Feature}InsightGeneratorProtocol
    private let fallbackGenerator: {Feature}InsightGeneratorProtocol

    init(
        insightGenerator: {Feature}InsightGeneratorProtocol,
        fallbackGenerator: {Feature}InsightGeneratorProtocol
    ) {
        self.insightGenerator = insightGenerator
        self.fallbackGenerator = fallbackGenerator
    }
}
```

When AI is unavailable or generation fails, use fallback generator behavior from the same protocol.

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

## Mock AI Generator

```swift
import Foundation

struct Mock{Feature}InsightGenerator: {Feature}InsightGeneratorProtocol {
    var result: Result<{Feature}Insight, Error>

    func generate(from input: {Feature}InsightInput) async throws -> {Feature}Insight {
        try result.get()
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

## Minimal Test Coverage Expectations

For each new feature:

- View model happy path + failure path.
- Repository mapping and filtering logic.
- Critical business service logic.
- At least one integration-style test for persistence-backed flows when feasible.
- If AI is used: availability + fallback behavior, and prompt-builder unit tests.
