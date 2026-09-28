# Concurrency and Testing

Reference code: every template compiles as Swift 6 in both default and MainActor-by-default isolation. See `App/Tests/` for the test patterns.

## Read the settings before diagnosing

Check `SWIFT_VERSION`, `SWIFT_STRICT_CONCURRENCY`, `SWIFT_DEFAULT_ACTOR_ISOLATION`, and `SWIFT_APPROACHABLE_CONCURRENCY`
(in `Project.swift`, `project.pbxproj`, or `Package.swift` `swiftSettings`). The same code gives different diagnostics under each combination.
If you can't read them, state the assumption.

## Rules

- View models and UI state are `@MainActor`. Domain models, records, repositories, and services are `Sendable` value types or actors.
- In MainActor-by-default modules, mark Domain and Data types and protocols `nonisolated`. Otherwise their conformances
  (Codable, GRDB records, `@Generable`) become main-actor isolated and break inside database or background closures.
- Shared mutable state goes in an `actor`, or in a `Mutex` from Synchronization for synchronous access.
  `@unchecked Sendable` and `nonisolated(unsafe)` need a written proof of safety next to them, not a hope.
- `@concurrent` applies only to `async` functions. Use it to move async work off the caller's actor.
- Prefer structured concurrency (`async let`, task groups, `.task`) over `Task {}`. Avoid `Task.detached` unless you need to drop the actor and priority.
- `DispatchQueue.main.async` has no place in new code.

## Diagnostics

| Message | Usual cause | Fix |
|---|---|---|
| "Sending 'x' risks causing data races" | Non-Sendable value crosses an isolation boundary | Make it a Sendable value type, keep it on one actor, or pass a copy |
| "Main actor-isolated … from a nonisolated context" | UI or MainActor-default type used from a background closure | Isolate the caller to `@MainActor`, or mark the callee's type `nonisolated` if it has no UI state |
| "Static property … is not concurrency-safe" | Mutable `static var` | Make it `let`, isolate it to `@MainActor`, or move it into an actor or instance |
| "Type does not conform to Sendable" | Class with mutable state crosses actors | Use a struct or actor, or a `final class` with only `let` Sendable properties |
| Flaky async test | Asserting right after starting a `Task` | Await the result, or poll with a deadline (`eventually` in `NotesViewModelTests.swift`) |

Fix one category, build, then continue. Don't batch unrelated isolation changes.

## Tests

- Use Swift Testing (`import Testing`, `@Test`, `#expect`, `#require`, parameterized `arguments:`). Keep XCTest only in files that already use it.
- Prefer the real implementation with in-memory storage (a GRDB `DatabaseQueue`) over mocks. Use a small fake only to force failures
  (`FailingNoteRepository`), or at a system boundary (the `transport` closure of `APIClient`).
- Inject time (`now:`), IDs, and network. Never sleep for a fixed time to wait for work. Put a time limit on tests that could hang.
- Spend tests where bugs are likely: SQL queries and mapping, migrations, failure paths the user sees, and concurrency invariants
  (for example "5 concurrent 401s produce 1 refresh"). Don't add tests that only restate trivial code.
- A test only counts if it fails when the behavior breaks. When adding a guard, break the code once and watch the test fail.
