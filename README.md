# ios-architect-skill

A multi-skill toolkit for scaffolding modern iOS apps with Clean Architecture, MVVM, SwiftUI, GRDB, Swift Concurrency, and modular local packages.

Works with any LLM-powered coding agent.

## Who Is This For?

iOS developers who want to scaffold new apps or features following strict Clean Architecture boundaries with feature-local ownership, GRDB persistence, and modern Swift APIs.

## Install

### Option A — Skills CLI

```bash
npx skills add https://github.com/alesanabriav7/ios-architect-skill
```

### Option B — Claude Code Plugin Marketplace

```
/plugin marketplace add ios-architect
```

### Option C — Manual

Clone the repo and copy the skill directories into your project's `.claude/skills/` folder:

```bash
git clone https://github.com/alesanabriav7/ios-architect-skill.git
cp -r ios-architect-skill/ios-architect .claude/skills/
cp -r ios-architect-skill/ios-design-system .claude/skills/
cp -r ios-architect-skill/ios-platform .claude/skills/
cp -r ios-architect-skill/ios-persistence .claude/skills/
cp -r ios-architect-skill/ios-testing .claude/skills/
cp -r ios-architect-skill/ios-visual .claude/skills/
```

## Skills

### ios-architect

Scaffold apps and features with Clean Architecture (Domain/Data/Presentation), MVVM, GRDB, and Swift Concurrency.

- New app scaffolding — Tuist project, Clean Architecture layers, GRDB database, and test targets
- Feature scaffolding — Domain models, repository protocols/implementations, view models, SwiftUI views
- Database & migrations — GRDB schema migrations with versioned migrators
- Error taxonomy — typed domain errors with propagation patterns

### ios-design-system

Design tokens, reusable components, theming, and accessibility.

- Design tokens — Spacing, color, radius, and typography scales
- Components — Reusable SwiftUI components with accessibility built in
- Theming — Light/dark mode color palettes
- Liquid Glass — iOS 26+ styling with version-gated fallbacks

### ios-platform

Networking, navigation, privacy compliance, and on-device AI integration.

- Networking — URLSession API clients with async/await, retry, and offline-first
- Navigation — Type-safe routing with deep linking support
- Privacy & compliance — Privacy manifests, account deletion flows
- Foundation Models — On-device AI with runtime availability checks

### ios-persistence

Focused GRDB operations without full feature scaffolding.

- Schema setup — DatabaseManager, migrations, table definitions
- Queries — Fetch, insert, update, delete with proper Data-layer isolation
- ValueObservation — Auto-updating queries for reactive UI
- Local caching — API response and image caching patterns

### ios-testing

Tests, mocks, concurrency fixes, and dependency injection — not feature building.

- Unit & integration tests — Swift Testing with compile-ready assertions
- Mocks — Actor-based fake implementations for repositories and services
- Concurrency — Sendable conformance, actor isolation, Swift 6 fixes
- DI wiring — Dependency injection setup for testability

### ios-visual

Screenshot capture and visual regression against designs or references.

- Simulator screenshots — Capture any screen via `simctl`
- Visual diff — Compare current UI against a reference image using Claude vision
- Layout validation — Detect broken spacing, clipped content, or misaligned elements
- Pre-merge regression — Catch visual regressions before merging a PR

## Skill Structure

```
ios-architect/
├── SKILL.md
└── references/
    ├── intake.md
    ├── new-app-scaffold.md
    ├── feature-scaffold.md
    ├── database-and-migrations.md
    ├── testing-concurrency-di.md
    ├── error-taxonomy.md
    └── screenshots.md

ios-design-system/
├── SKILL.md
└── references/
    ├── design-system.md
    └── liquid-glass.md

ios-platform/
├── SKILL.md
└── references/
    ├── networking.md
    ├── navigation.md
    ├── privacy-and-compliance.md
    └── foundation-models.md

ios-persistence/
├── SKILL.md
└── references/
    └── persistence.md

ios-testing/
├── SKILL.md
└── references/
    └── testing.md

ios-visual/
├── SKILL.md
└── references/
    └── visual-qa.md
```

## Usage

Tell your AI assistant:

> Create a new iOS app called BudgetTracker with expense tracking and categories.

> Add a Favorites feature to my iOS app with local GRDB persistence.

> Build a reusable card component with Liquid Glass styling.

> Set up URLSession networking with token refresh for my iOS app.

> Add a column for avatarURL to the users table.

> Write tests for my ExpenseViewModel.

> Does the home screen match my Figma design?

## License

[MIT](LICENSE)
