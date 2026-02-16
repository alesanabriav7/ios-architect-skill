---
name: ios-architect
description: Scaffold modern iOS apps and features with Clean Architecture, MVVM, SwiftUI, GRDB, Swift Concurrency, and modular local packages. Use when creating a new iOS app, adding a feature/service/model/migration/design system component/package, or enforcing Domain/Data/Presentation separation. Read only the minimal reference files needed for the requested build type, then generate compile-ready files and validate.
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
- New feature:
`references/feature-scaffold.md`
If persistence changes: `references/database-and-migrations.md`
If custom UI components: `references/design-system.md`
If tests/concurrency concerns: `references/testing-concurrency-di.md`
- New shared service or shared model:
`references/testing-concurrency-di.md`
If DB-backed: `references/database-and-migrations.md`
- New design system component:
`references/design-system.md`
- New database migration:
`references/database-and-migrations.md`
- New local SPM package:
`references/new-app-scaffold.md`
`references/testing-concurrency-di.md`

Do not bulk-load all references when the task is narrow.

## Execution Contract

1. Run intake first (build type, name, flow, fields, data source, integrations, test scope).
2. Generate complete, compile-ready files with concrete names.
3. Keep Clean Architecture boundaries strict:
- Domain: models and protocols only
- Data: repository implementations and records
- Presentation: SwiftUI views, view models, feature UI components
4. Use modern APIs (`@Observable`, `@MainActor`, Swift Concurrency, Swift Testing).
5. Validate generated output:
- New Tuist app: `tuist generate` + one build
- Feature/module changes: targeted build/tests
6. Report created files, validations run, and assumptions.
