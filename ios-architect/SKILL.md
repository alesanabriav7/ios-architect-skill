---
name: ios-architect
description: >
  Builds and changes iOS Swift 6/SwiftUI code: features, Clean Architecture layers, GRDB migrations
  and queries, API clients, deep links, Foundation Models, privacy manifests, design tokens, Liquid Glass,
  Swift Testing, and Sendable or actor-isolation errors. Not for simulator screenshots (ios-visual).
---

# iOS Architect

## 1. The existing project wins

The user's instructions come first, then the repo's conventions, then this skill. If they conflict, say which line of this skill you're setting aside.
Before writing code in an existing repo, read its `AGENTS.md`/`CLAUDE.md` and the closest existing feature.
Its conventions (DI, naming, tokens, file layout, build/test/lint commands) override everything below.
Use `templates/` only where the repo has no precedent, and adapt it to the repo's names.

## 2. Verified templates

`templates/` is a Tuist app (iOS 26, Swift 6) that builds and passes its tests in both default and
MainActor-by-default isolation. Read the file for the concern at hand. Copy the pattern, not the `Note` names.

| Concern | Files (under `templates/`) |
|---|---|
| Feature slice | `App/Sources/Features/Notes/{Domain,Data,Presentation}/` |
| Database, migrations | `App/Sources/Core/Database/AppDatabase.swift`, `App/Tests/AppDatabaseTests.swift` |
| Live list (ValueObservation → view model) | `GRDBNoteRepository.swift`, `NotesViewModel.swift`, `NotesView.swift` |
| API client, token refresh, Keychain | `App/Sources/Core/Networking/`, `App/Tests/APIClientTests.swift` |
| Deep links, navigation, launch options | `App/Sources/App/Router.swift`, `SampleApp.swift`, `App/Tests/RoutingTests.swift` |
| Composition root, preview data | `App/Sources/App/AppEnvironment.swift`, `NoteFixtures.swift` |
| Screenshot launch contexts (for `ios-visual`) | `screenshots/*.json` |
| Foundation Models with fallback | `FoundationModelsTitleSuggester.swift` |
| Design tokens, shared component | `DesignSystem/Sources/` |
| Tuist project | `Project.swift`, `Tuist.swift`, `Tuist/Package.swift` |

## 3. Guardrails

- **Domain**: models and protocols, Foundation only. **Data**: GRDB, URLSession, FoundationModels, Keychain.
  **Presentation**: SwiftUI views and `@MainActor @Observable` view models. Framework types never cross into Domain.
- Code belongs to the feature that uses it. Move it to `Shared/<Capability>/` only once two features consume it.
  Never create `Shared/Models`, `Shared/Data`, or other catch-all folders.
- One composition root picks concrete implementations. No singletons, and no default arguments that open the database.
- Create only the layers the task needs. A service with no UI gets no view.
- Every screen needs loading, empty, error, and long-text states. User-facing errors are localized messages, never `error.localizedDescription`.

Read the reference for the area you are touching:

- GRDB, migrations, queries, caching, offline → `references/persistence.md`
- Concurrency errors, isolation, tests and fakes → `references/concurrency-and-testing.md`
- Networking, auth, deep links, navigation, Foundation Models, privacy → `references/platform.md`
- Design system, components, Liquid Glass, accessibility, localization → `references/ui.md`
- New app from scratch → `references/new-app.md`

## 4. Prove it

- Build and test with the repo's own commands. With a Tuist/Xcode app, use
  `xcodebuild test -workspace <X>.xcworkspace -scheme <X> -destination 'platform=iOS Simulator,name=<device>'`;
  `swift test` only works for Swift packages.
- Test the behavior at risk: migrations (run twice, upgrade existing rows), queries, and async or concurrent code (no sleeps).
  Skip tests that only restate the implementation.
- Read `git diff` before reporting. Generators (`tuist generate`) can rewrite committed project files, for example resetting
  version and build numbers. Revert whatever the task didn't ask to change.
- For visible UI changes, capture the affected screens with `ios-visual`.
- Report the commands you ran and their results. Code is not "compile-ready" until it has been built.
- After editing `templates/`, run `scripts/verify-templates.sh`. It needs Xcode 26+, Tuist 4, and an iOS 26+ simulator.
