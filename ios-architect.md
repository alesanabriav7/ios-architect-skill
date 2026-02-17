---
name: ios-architect
description: Scaffold modern iOS apps and features with Clean Architecture, MVVM, SwiftUI, GRDB, Swift Concurrency, optional Apple Foundation Models integration, and modular local packages. Use when creating a new iOS app, adding a feature/service/model/migration/design system component/package, or enforcing Domain/Data/Presentation separation with feature-local ownership by default and shared modules only for true cross-domain concerns. Load only the minimum references needed for the task.
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

Optional:

- `references/foundation_models.md` when on-device AI features are part of MVP
- `references/liquid-glass.md` when iOS 26+ Liquid Glass styling is requested

### 2) New feature module

Read:

- `references/feature-scaffold.md`

Optional:

- `references/database-and-migrations.md` when persistence changes are required
- `references/design-system.md` when new shared UI components are required
- `references/testing-concurrency-di.md` when adding tests or concurrency-sensitive logic
- `references/foundation_models.md` when adding Apple Foundation Models generation/streaming
- `references/liquid-glass.md` when the feature explicitly needs Liquid Glass styling

### 3) New cross-domain shared service or model (for example Settings)

Read:

- `references/testing-concurrency-di.md`

Optional:

- `references/database-and-migrations.md` when DB-backed
- `references/foundation_models.md` when the service uses Apple Foundation Models

### 4) New design system component

Read:

- `references/design-system.md`
Optional:

- `references/liquid-glass.md` when the component uses Liquid Glass APIs

### 5) New database migration

Read:

- `references/database-and-migrations.md`

### 6) New local SPM package

Read:

- `references/new-app-scaffold.md`
- `references/testing-concurrency-di.md`

## Non-Negotiables

- Use strict Domain/Data/Presentation boundaries.
- Keep Domain/Data/Presentation in the owning feature by default.
- Use `Shared` only for true cross-domain modules consumed by at least two features/domains.
- Preserve layer split inside shared modules (`Shared/Settings/Domain`, `Shared/Settings/Data`, `Shared/Settings/Presentation` when needed).
- Never use generic buckets like `Shared/Models`, `Shared/Data`, or `Shared/Services`.
- Use modern APIs (`@Observable`, `@MainActor`, async/await, Swift Testing).
- For AI features, require explicit availability checks and deterministic fallback paths.
- Replace placeholders with concrete names.
- Avoid unsafe initialization paths (`try!`) in generated architecture code.
- Run validation commands relevant to the scope and report results.

## Validation Baseline

- New Tuist app: run `tuist generate` and build at least one scheme.
- Existing module/feature: run targeted build or tests.
- If validation cannot run, state exactly what was blocked.
