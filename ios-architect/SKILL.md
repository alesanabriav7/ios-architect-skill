---
name: ios-architect
description: Scaffold modern iOS apps and features with Clean Architecture, MVVM, SwiftUI, GRDB, Swift Concurrency, and modular local packages. Use when creating a new iOS app, adding a feature/service/model/migration/package, or enforcing Domain/Data/Presentation separation with feature-local ownership by default and shared modules only for true cross-domain concerns.
license: MIT
allowed-tools: Read Bash(tuist:*) Bash(swift:*)
metadata:
  author: alesanabriav7
  version: "1.0.0"
---

# iOS Architect

Keep token usage low by loading only the references needed for the current request.

## Load Strategy

1. Always read `references/intake.md` first.
2. Read only the references relevant to the build type:

### New app from scratch

- `references/new-app-scaffold.md`
- `references/feature-scaffold.md`
- `references/database-and-migrations.md`
- `references/testing-concurrency-di.md`

### New feature

- `references/feature-scaffold.md`
- If persistence changes: `references/database-and-migrations.md`
- If tests/concurrency concerns: `references/testing-concurrency-di.md`

### New cross-domain shared service or model

- `references/testing-concurrency-di.md`
- If DB-backed: `references/database-and-migrations.md`

### New database migration

- `references/database-and-migrations.md`

### New local SPM package

- `references/new-app-scaffold.md`
- `references/testing-concurrency-di.md`

Do not bulk-load all references when the task is narrow.

### Cross-Skill Handoffs

- If custom UI components, theming, or Liquid Glass styling → use the `ios-design-system` skill.
- If API-backed features, navigation/routing overhaul, privacy audit, or on-device AI → use the `ios-platform` skill.

## Shared Placement Rule

- Default all model/repository/view-model ownership to the feature that uses it.
- Use `Shared` only for true cross-domain capabilities consumed by at least two domains/features (e.g. Settings).
- Keep shared capabilities domain-scoped (`Shared/Settings/...`) with their own Domain/Data/Presentation split.
- Never create catch-all buckets such as `Shared/Models` or `Shared/Data`.

## Execution Contract

1. Run intake first (build type, name, flow, fields, data source, integrations, test scope).
2. Generate complete, compile-ready files with concrete names.
3. Keep Clean Architecture boundaries strict:
   - **Domain** — models and protocols only
   - **Data** — repository implementations and records
   - **Presentation** — SwiftUI views, view models, feature UI components
   - Keep each layer in the owning feature by default; only promote to shared for proven cross-domain reuse.
4. Use modern APIs (`@Observable`, `@MainActor`, Swift Concurrency, Swift Testing).
5. Validate generated output:
   - New Tuist app: `tuist generate` + one build
   - Feature/module changes: targeted build/tests
6. Report created files, validations run, and assumptions.

## Sister Skills

- **ios-design-system** — design tokens, UI components, Liquid Glass styling
- **ios-platform** — networking, navigation, privacy, Foundation Models
