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

## Sister Skills

- **ios-architect** — app/feature scaffolding, Domain/Data/Presentation layers
- **ios-persistence** — GRDB setup, migrations, ValueObservation
- **ios-platform** — networking, navigation, Foundation Models
