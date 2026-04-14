---
name: ios-testing
description: >
  ONLY for test/mock/concurrency/DI work — not for building new features. Use when
  someone wants to test their code, fix a threading or concurrency bug, or set up
  dependency injection. This covers: writing unit or integration tests, creating mock
  or fake implementations, debugging crashes that happen on background threads, fixing
  Swift 6 Sendable errors or actor isolation warnings, wiring dependencies for testability,
  and ensuring thread safety. The user might say "write tests for this", "how do I test
  this viewmodel?", "I'm getting a data race warning", "something crashes intermittently",
  "create a mock for this repository", "fix this Sendable error", or "how do I inject
  this dependency?". Not for: building new features (ios-architect), visual UI problems
  (ios-visual), or standalone database queries (ios-persistence).
license: MIT
allowed-tools: Read Bash(swift:*)
metadata:
  author: alesanabriav7
  version: "1.0.0"
---

# iOS Testing

Emit compile-ready Swift Testing code. All mocks are actor-based. All view models are `@MainActor`.

## Load Strategy

Always read `references/testing.md`.
If the request involves concurrency, Sendable, or actor isolation: also read `ios-architect/references/testing-concurrency-di.md`.

## Execution Contract

1. Use Swift Testing (`import Testing`) for all new tests — no XCTest unless the file already uses it.
2. Mock repositories must be `actor`-based and conform to the same protocol as the real implementation.
3. View models under test must be accessed on `@MainActor`.
4. Never use `@unchecked Sendable` — prefer `actor`, `@MainActor`, or value types.
5. Test data factories use `make{Entity}()` helpers with overridable defaults.
6. Run targeted tests to validate: `swift test --filter <TestSuite>`.

## Project Settings Check

Before diagnosing any concurrency or Sendable issue, read the project's concurrency configuration:

- `Package.swift` — look for `swiftLanguageVersions`, `.enableExperimentalFeature("StrictConcurrency")`, `.defaultIsolation(MainActor.self)`
- Xcode build settings — look for **Swift Language Version** and **Strict Concurrency Checking**
- If settings cannot be read, state the assumption explicitly before proceeding (e.g. "Assuming Swift 5 with no strict concurrency enabled")

## Concurrency Diagnostics

| Symptom | Root Cause | Smallest Fix | Guardrail |
|---|---|---|---|
| "Sending X risks causing data races" | Isolation boundary crossed — reference type sent between actors | Move to actor, or make value type (`struct`) | Don't add `@unchecked Sendable` to silence it |
| "Expression is 'async' but is not marked with 'await'" | Async call missing `await` | Add `await` at the call site | Don't wrap in a new `Task` just to avoid `await` |
| "Call to main actor-isolated … from nonisolated context" | UI code called off `@MainActor` | Annotate caller with `@MainActor` or use `Task { @MainActor in … }` | Don't use `DispatchQueue.main.async` — defeats Swift concurrency |
| "Type X does not conform to Sendable" | Reference type crossing actor boundary | Make `Sendable` (immutable struct/final class), use `actor`, or value type | Don't reach for `@unchecked Sendable` first |
| "Stored property 'X' of Sendable-conforming class is mutable" | Mutable stored property in `Sendable` type | Make `let`, use `actor`, or `nonisolated(unsafe)` only if provably safe | Don't use `nonisolated(unsafe)` as default escape hatch |
| Flaky async test (timing-dependent) | Asserting after `Task` creation before it runs | Use `confirmation` or `await` the result directly | Don't use `sleep` or `Task.yield` to stabilize timing |

## Migration Validation Loop

When migrating to stricter concurrency (Swift 5 → Swift 6 or enabling strict concurrency):

1. Enable `-strict-concurrency=complete` in Swift 5 mode first — do not flip to Swift 6 yet
2. Fix one diagnostic category at a time (isolation, Sendable, etc.) — not all at once
3. Run `swift build` after each category to confirm no regressions introduced
4. Run `swift test --filter <Suite>` to verify test behavior is unchanged
5. Only switch to Swift 6 language mode per module once all warnings are resolved
6. Never batch unrelated concurrency fixes in a single step

## Sister Skills

- **ios-architect** — app/feature scaffolding, Domain/Data/Presentation layers
- **ios-persistence** — GRDB setup, migrations, ValueObservation
- **ios-platform** — networking, navigation, Foundation Models
