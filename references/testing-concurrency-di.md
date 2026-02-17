# Testing, Concurrency, and DI

Use this file for quality gates, thread-safety, and dependency wiring.

## Concurrency Rules

- View models: `@Observable` + `@MainActor`.
- Repository protocols: `Sendable`.
- Repository implementations: `final class` + `Sendable`.
- Shared mutable caches: `actor`.
- Async work: `async/await` with `async throws`.
- Avoid Combine and completion handlers for new code.

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

## Minimal Test Coverage Expectations

For each new feature:

- View model happy path + failure path.
- Repository mapping and filtering logic.
- Critical business service logic.
- At least one integration-style test for persistence-backed flows when feasible.
- If AI is used: availability + fallback behavior, and prompt-builder unit tests.
