---
name: ios-architect
description: >
  Use when someone is building something new in iOS or organizing existing code into
  proper structure. This covers: creating a new app from scratch, adding a new feature
  or screen, making a feature work offline end-to-end, splitting messy code into layers,
  creating a shared service used by multiple features, or setting up the project skeleton.
  The user might say "create a feature for X", "add a screen that does Y", "how should I
  structure this?", "build an app that tracks Z", "add offline support to this feature",
  "I want the app to work without internet", or "split this into proper layers". Use this
  even if they don't mention architecture — if they want to add or reorganize functionality
  at the feature level, this is the right skill. Not for: isolated DB queries or column
  changes (ios-persistence), writing tests only (ios-testing), visual UI checks
  (ios-visual), or API client setup (ios-platform).
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
- `references/error-taxonomy.md`
- If screenshots or UI/snapshot testing: `references/screenshots.md`

### New feature

- `references/feature-scaffold.md`
- `references/error-taxonomy.md`
- If persistence changes: `references/database-and-migrations.md`
- If tests/concurrency concerns: `references/testing-concurrency-di.md`
- If screenshots or UI/snapshot testing: `references/screenshots.md`

### New cross-domain shared service or model

- `references/testing-concurrency-di.md`
- If DB-backed: `references/database-and-migrations.md`

### New database migration

→ Use the `ios-persistence` skill directly.

### New local SPM package

- `references/new-app-scaffold.md`
- `references/testing-concurrency-di.md`

Do not bulk-load all references when the task is narrow.

### Cross-Skill Handoffs

- **ios-design-system**: invoke when the request mentions a reusable UI component (used by 2+ features), a color/spacing token, theming, or Liquid Glass. Do NOT invoke for a one-off view inside a feature.
- **ios-persistence**: invoke when the request is ONLY about a migration, query optimization, or ValueObservation setup with no Domain/Data/Presentation changes. If Domain/Data layers change alongside persistence, ios-architect handles it and loads `database-and-migrations.md` itself.
- **ios-platform**: invoke when the request is ONLY about the API client, navigation router overhaul, privacy manifest, or Foundation Models integration. Feature scaffolding (Domain/Data/Presentation) stays in ios-architect even if networking is involved.
- **ios-testing**: invoke when the request is ONLY about writing or fixing tests, mocks, or actor isolation errors, with no new feature scaffolding.
- **ios-visual**: invoke when the request involves screenshots, visual regression, or design comparison.

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
3. If screenshots are in scope, generate the full JSON config and env var router hook (one JSON file per `AppScreen` case, plus `APP_USE_PREVIEW_DATA` env var at the app entry point) before handing off to ios-visual.
4. For new-app scaffolds: generate Tuist config AND app code (entry point, root navigation, first feature with all three layers) in the same response. Never stop after emitting only project configuration files.
5. Use modern APIs (`@Observable`, `@MainActor`, Swift Concurrency, Swift Testing).
6. Validate generated output:
   - New Tuist app: `tuist generate` + one build
   - Feature/module changes: targeted build/tests
7. Report created files, validations run, and assumptions.

## Sister Skills

- **ios-design-system** — design tokens, UI components, Liquid Glass styling
- **ios-platform** — networking, navigation, privacy, Foundation Models
- **ios-persistence** — GRDB setup, migrations, ValueObservation
- **ios-testing** — Swift Testing, mock repositories, DI, concurrency
- **ios-visual** — visual regression, pixel-perfect comparison, UI error detection
