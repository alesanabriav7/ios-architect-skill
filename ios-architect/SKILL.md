---
name: ios-architect
description: Scaffold modern iOS apps and features with Clean Architecture, MVVM, SwiftUI, GRDB, Swift Concurrency, optional Apple Foundation Models integration, and modular local packages. Use when creating a new iOS app, adding a feature/service/model/migration/design system component/package, or enforcing Domain/Data/Presentation separation with feature-local ownership by default and shared modules only for true cross-domain concerns. Read only the minimal reference files needed for the requested build type, then generate compile-ready files and validate. ALWAYS use this skill whenever the user wants to build an iOS app from scratch, add a new feature or module to an existing iOS app, create a Swift Package, add a GRDB migration, scaffold Domain/Data/Presentation layers, refactor iOS code into clean architecture, set up offline-first persistence, create an API-only feature, add a shared cross-domain service, set up screenshot automation or preview data, or restructure an iOS codebase — even if they don't explicitly mention "architecture" or "clean architecture". Any request involving iOS app creation, iOS feature scaffolding, iOS module structure, favorites/settings/analytics features, or splitting code into layers should trigger this skill.
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
- If screenshots or UI/snapshot testing: `references/screenshots.md`

### New feature

- `references/feature-scaffold.md`
- If persistence changes: `references/database-and-migrations.md`
- If tests/concurrency concerns: `references/testing-concurrency-di.md`
- If screenshots or UI/snapshot testing: `references/screenshots.md`

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
- If networking implementation (API client setup, token management, retry/offline), navigation/routing overhaul, privacy audit, or on-device AI → use the `ios-platform` skill. Feature scaffolding (Domain/Data/Presentation structure) stays in this skill.

## Shared Placement Rule

- Default all model/repository/view-model ownership to the feature that uses it.
- Use `Shared` only for true cross-domain capabilities consumed by at least two domains/features (e.g. Settings).
- Keep shared capabilities domain-scoped (`Shared/Settings/...`) with their own Domain/Data/Presentation split.
- Never create catch-all buckets such as `Shared/Models` or `Shared/Data`.

## Execution Contract

1. Run intake first (build type, name, flow, fields, data source, integrations, test scope).
   - If the user does not answer intake questions (e.g., non-interactive context), state safe defaults and proceed to generation immediately. Never stop at intake.
2. Generate ALL three layers for every feature — Domain, Data, AND Presentation:
   - **Domain** — model struct(s) + repository protocol
   - **Data** — repository implementation (+ records if persistence is used)
   - **Presentation** — at least one ViewModel (`@Observable @MainActor`) AND at least one SwiftUI View that consumes it
   - Skipping the Presentation layer is never acceptable. Every feature must have a working View + ViewModel.
   - Keep each layer in the owning feature by default; only promote to shared for proven cross-domain reuse.
3. For new-app scaffolds: generate Tuist config AND app code (entry point, root navigation, first feature with all three layers) in the same response. Never stop after emitting only project configuration files.
4. Use modern APIs (`@Observable`, `@MainActor`, Swift Concurrency, Swift Testing).
5. Validate generated output:
   - New Tuist app: `tuist generate` + one build
   - Feature/module changes: targeted build/tests
6. Report created files, validations run, and assumptions.

## Sister Skills

- **ios-design-system** — design tokens, UI components, Liquid Glass styling
- **ios-platform** — networking, navigation, privacy, Foundation Models
