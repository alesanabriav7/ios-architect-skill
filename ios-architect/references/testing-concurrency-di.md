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

## Screenshot Automation and Visual QA

Automated screenshots capture every screen in the app for visual regression testing. The `AppScreen` manifest (see `navigation.md`) is the single source of truth for what screens exist. `PreviewFixture` data (see `feature-scaffold.md`) ensures every capture is deterministic — same data, same layout, every run.

### App-Side Contract

The app must support two environment variables so external capture tools can drive it:

1. **Preview mode** — switches to deterministic in-memory data instead of real persistence:

```swift
let usePreview = ProcessInfo.processInfo.environment["APP_USE_PREVIEW_DATA"] == "1"
```

2. **Screen navigation** — jumps to a specific screen on launch:

```swift
#if DEBUG
extension TabRootView {
    func applyScreenshotHook() -> some View {
        self.onAppear {
            if let screenName = ProcessInfo.processInfo.environment["SCREENSHOT_SCREEN"],
               let screen = AppScreen(rawValue: screenName) {
                tabRouter.navigate(to: screen)
            }
        }
    }
}
#endif
```

Each `AppScreen` case maps to one screenshot. When adding a new screen to `AppScreen`, the screenshot pipeline automatically picks it up — no separate configuration needed.

### Preview Repositories

In preview mode, replace real data sources with in-memory implementations seeded from `PreviewFixture`:

```swift
actor Preview{Entity}Repository: {Entity}RepositoryProtocol {
    private var items: [{Entity}]

    init() {
        self.items = {Entity}.fixtures
    }

    func fetchAll() async throws -> [{Entity}] { items }
    func fetchByID(_ id: String) async throws -> {Entity}? { items.first { $0.id == id } }
    func save(_ item: {Entity}) async throws { items.append(item) }
    func delete(_ item: {Entity}) async throws { items.removeAll { $0.id == item.id } }
    func fetch(matching filter: {Entity}Filter) async throws -> [{Entity}] { items }
}
```

Wire at the app root:

```swift
let repository: {Entity}RepositoryProtocol = usePreview
    ? Preview{Entity}Repository()
    : {Entity}Repository(dbManager: dbManager)
```

### Capture Configuration

Each `AppScreen` case needs a corresponding JSON config file that tells the capture tool which env vars to pass. One file per screen, stored in `screenshots/`:

```json
{
  "scheme": "{AppScheme}",
  "screenshotName": "{feature}List",
  "outputDir": "screenshots/current",
  "launchEnv": {
    "APP_USE_PREVIEW_DATA": "1",
    "SCREENSHOT_SCREEN": "{feature}List"
  }
}
```

The mapping from `AppScreen` to config is mechanical:

| `AppScreen` case | `SCREENSHOT_SCREEN` value | Extra env vars |
|---|---|---|
| `.{feature}List` | `{feature}List` | — |
| `.{feature}Detail` | `{feature}Detail` | — |
| `.{feature}CreateSheet` | `{feature}CreateSheet` | — |
| `.{feature}EditSheet` | `{feature}EditSheet` | — |
| `.settings` | `settings` | — |

For screens that need additional state (e.g., a specific filter pre-selected, dark mode), add extra env vars to `launchEnv` and read them in the app.

When adding a new `AppScreen` case:
1. Add the case to the enum and wire its `ScreenPath` (see `navigation.md`).
2. Create a new JSON config file in `screenshots/` with the matching `SCREENSHOT_SCREEN` value.
3. Add it to the batch capture script so it runs with `--skip-build` after the first screen.

### Running the Capture

Before creating or running a capture script, the agent must detect how the project captures screenshots:

1. **Check for an existing capture script** — look for `screenshots/capture-all.sh`, a `screenshots` npm script in `package.json`, or a `Makefile` target.
2. **Check for a capture tool** — look for screenshot tool references in `package.json` dependencies, `CLAUDE.md`, `README.md`, or shell scripts in the project.
3. **Ask the user** if nothing is found — "How do you capture screenshots? Do you have a tool or script for this?"

Never assume a specific runtime (Node, Python, Ruby) is installed. If the project uses a Node-based tool, verify `npx` or `node` is available before invoking it. If it uses a Swift-based tool, verify `swift` is available. If no tool exists, fall back to `xcrun simctl io booted screenshot` as a baseline — it requires only Xcode.

### Batch Capture Script

Build once, then reuse the build for remaining screens. The capture tool should support a skip-build flag:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

SCREENS=({feature}List {feature}Detail {feature}CreateSheet {feature}EditSheet settings)

for i in "${!SCREENS[@]}"; do
  skip=""
  [[ "$i" -gt 0 ]] && skip="--skip-build"
  # Replace with the project's capture tool invocation:
  <capture-tool> --context "$SCRIPT_DIR/${SCREENS[$i]}.json" $skip
done
```

### Screenshot Output Layout

Screenshots are saved to a known directory with predictable names derived from `AppScreen.rawValue`:

```
{project}/
├── screenshots/
│   ├── {feature}List.json        # Capture configs
│   ├── {feature}Detail.json
│   ├── settings.json
│   ├── capture-all.sh
│   ├── baseline/                  # Last approved set (committed to repo)
│   │   ├── {feature}List.png
│   │   ├── {feature}Detail.png
│   │   ├── {feature}CreateSheet.png
│   │   └── settings.png
│   └── current/                   # Latest capture (gitignored)
│       ├── {feature}List.png
│       ├── {feature}Detail.png
│       ├── {feature}CreateSheet.png
│       └── settings.png
```

- `baseline/` — committed to the repo. Represents the last visually approved state.
- `current/` — gitignored. Generated each capture run. Compared against baseline.

### Visual QA Workflow

After UI changes, capture screenshots and compare against baseline. The agent performing visual QA should follow this process:

**1. Read both images for each screen:**

For every file in `screenshots/current/`, read the corresponding `screenshots/baseline/` image.

**2. Compare each pair and check for:**

- **Layout shifts** — did spacing, alignment, or sizing change unexpectedly?
- **Missing or extra elements** — did a button disappear, did a new element appear that shouldn't be there?
- **Text content** — is the fixture data rendering correctly? Are labels, titles, and values present?
- **State correctness** — does the detail screen show the entity? Does the empty state show the right message? Is the correct tab selected?
- **Design system compliance** — are fonts, colors, spacing consistent with the design tokens?
- **Truncation and clipping** — is any text cut off? Are elements overlapping?

**3. Report findings per screen:**

For each screen, report one of:
- **Pass** — no visual changes, or changes are intentional and correct.
- **Expected change** — visual change detected, consistent with the code change being reviewed.
- **Regression** — unintended visual change that needs fixing.

**4. Approve or reject:**

If all screens pass, copy `current/` to `baseline/` and commit.

### When to Capture Screenshots

- After any Presentation-layer change (views, view models, design system tokens).
- After adding a new screen (new `AppScreen` case).
- Before submitting a PR that touches UI.
- After resolving merge conflicts in view files.

### Mock Deep Link Resolver

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

### Xcode Preview with Direct Router State

For rapid iteration in previews, set the router stack directly using fixture data:

```swift
#Preview("{Feature} Detail") {
    let router = AppRouter()
    router.stack = [.{feature}Detail(.fixture)]

    return NavigationStack(path: .constant(router.stack)) {
        EmptyView()
            .navigationDestination(for: AppRoute.self) { route in
                route.destinationView
            }
    }
}
```

## Minimal Test Coverage Expectations

For each new feature:

- View model happy path + failure path.
- Repository mapping and filtering logic.
- Critical business service logic.
- At least one integration-style test for persistence-backed flows when feasible.
- If AI is used: availability + fallback behavior, and prompt-builder unit tests.
