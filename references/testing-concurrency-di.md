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

protocol {Entity}RepositoryProtocol: Sendable {
    func fetchAll() async throws -> [{Entity}]
}

final class {Entity}Repository: {Entity}RepositoryProtocol, Sendable {
    func fetchAll() async throws -> [{Entity}] { [] }
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
    amount: Decimal = 10.00,
    date: Date = .now,
    category: String = "General",
    createdAt: Date = .now
) -> {Entity} {
    {Entity}(
        id: id,
        title: title,
        amount: amount,
        date: date,
        category: category,
        createdAt: createdAt
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
    func fetch(for month: Date) async throws -> [{Entity}] { items }
}
```

## Minimal Test Coverage Expectations

For each new feature:

- View model happy path + failure path.
- Repository mapping and filtering logic.
- Critical business service logic.
- At least one integration-style test for persistence-backed flows when feasible.
