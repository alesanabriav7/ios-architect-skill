---
name: ios-architect
description: Scaffold modern iOS apps and features with Clean Architecture, MVVM, SwiftUI, GRDB, Swift Concurrency, and modular local packages. Use when creating a new iOS app, adding a feature/service/model/migration/design system component/package, or enforcing Domain/Data/Presentation separation. Load only the minimum references needed for the task.
---

# iOS Architect Skill

Token-efficient architecture skill for modern iOS scaffolding.

## Read Order

1. Always read `references/intake.md`.
2. Read only the references required by build type.
3. Generate compile-ready code and validate.

## Build Type to Reference Map

### 1) New app from scratch

Read:

- `references/new-app-scaffold.md`
- `references/feature-scaffold.md`
- `references/database-and-migrations.md`
- `references/design-system.md`
- `references/testing-concurrency-di.md`

### 2) New feature module

Read:

- `references/feature-scaffold.md`

Optional:

- `references/database-and-migrations.md` when persistence changes are required
- `references/design-system.md` when new shared UI components are required
- `references/testing-concurrency-di.md` when adding tests or concurrency-sensitive logic

### 3) New shared service or model

Read:

- `references/testing-concurrency-di.md`

Optional:

- `references/database-and-migrations.md` when DB-backed

### 4) New design system component

Read:

- `references/design-system.md`

### 5) New database migration

Read:

- `references/database-and-migrations.md`

### 6) New local SPM package

Read:

- `references/new-app-scaffold.md`
- `references/testing-concurrency-di.md`

## Non-Negotiables

- Use strict Domain/Data/Presentation boundaries.
- Use modern APIs (`@Observable`, `@MainActor`, async/await, Swift Testing).
- Replace placeholders with concrete names.
- Avoid unsafe initialization paths (`try!`) in generated architecture code.
- Run validation commands relevant to the scope and report results.

## Validation Baseline

- New Tuist app: run `tuist generate` and build at least one scheme.
- Existing module/feature: run targeted build or tests.
- If validation cannot run, state exactly what was blocked.
