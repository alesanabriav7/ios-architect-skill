---
name: ios-architect
description: Scaffold modern iOS apps and features with Clean Architecture, MVVM, SwiftUI, GRDB, Swift Concurrency, optional Apple Foundation Models integration, and modular local packages. Use when creating a new iOS app, adding a feature/service/model/migration/design system component/package, or enforcing Domain/Data/Presentation separation with feature-local ownership by default and shared modules only for true cross-domain concerns. Read only the minimal reference files needed for the requested build type, then generate compile-ready files and validate.
---

# iOS Architect

Keep token usage low by loading only the references needed for the current request.

## Load Strategy

1. Always read `references/intake.md`.
2. Read only the relevant references:
- New app from scratch:
`references/new-app-scaffold.md`
`references/feature-scaffold.md`
`references/database-and-migrations.md`
`references/design-system.md`
`references/testing-concurrency-di.md`
`references/privacy-and-compliance.md`
Optional: `references/networking.md` when the app has API-backed features.
Optional: `references/navigation.md` when deep linking or iPad/multi-column is required.
Optional: `references/foundation_models.md` for on-device AI features.
Optional: `references/liquid-glass.md` when iOS 26+ Liquid Glass styling is requested.
- New feature:
`references/feature-scaffold.md`
If persistence changes: `references/database-and-migrations.md`
If custom UI components: `references/design-system.md`
If tests/concurrency concerns: `references/testing-concurrency-di.md`
If API-backed: `references/networking.md`
If navigation/deep linking changes: `references/navigation.md`
If on-device AI generation/streaming is required: `references/foundation_models.md`.
If Liquid Glass styling is required: `references/liquid-glass.md`.
- New cross-domain shared service or shared model (for example Settings):
`references/testing-concurrency-di.md`
If DB-backed: `references/database-and-migrations.md`
If API-backed: `references/networking.md`
If the service uses Apple Foundation Models: `references/foundation_models.md`.
- New design system component:
`references/design-system.md`
If the component uses Liquid Glass: `references/liquid-glass.md`.
- New database migration:
`references/database-and-migrations.md`
- New local SPM package:
`references/new-app-scaffold.md`
`references/testing-concurrency-di.md`

Do not bulk-load all references when the task is narrow.

Shared placement rule:

- Default all model/repository/view-model ownership to the feature that uses it.
- Use `Shared` only for true cross-domain capabilities consumed by at least two domains/features (for example Settings).
- Keep shared capabilities domain-scoped (`Shared/Settings/...`) with their own Domain/Data/Presentation split.
- Never create catch-all buckets such as `Shared/Models` or `Shared/Data`.

## Execution Contract

1. Run intake first (build type, name, flow, fields, data source, integrations, test scope).
2. Generate complete, compile-ready files with concrete names.
3. Keep Clean Architecture boundaries strict:
- Domain: models and protocols only
- Data: repository implementations and records
- Presentation: SwiftUI views, view models, feature UI components
Keep each layer in the owning feature by default, and only promote to shared for proven cross-domain reuse.
4. Use modern APIs (`@Observable`, `@MainActor`, Swift Concurrency, Swift Testing).
If AI is included, enforce runtime availability checks and deterministic fallback.
5. Validate generated output:
- New Tuist app: `tuist generate` + one build
- Feature/module changes: targeted build/tests
6. Report created files, validations run, and assumptions.
