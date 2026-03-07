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

Clone the repo and symlink or copy the skill directories into your project's `.claude/skills/` folder:

```bash
git clone https://github.com/alesanabriav7/ios-architect-skill.git
cp -r ios-architect-skill/ios-architect .claude/skills/
cp -r ios-architect-skill/ios-design-system .claude/skills/
cp -r ios-architect-skill/ios-platform .claude/skills/
```

## Skills

This repo contains three skills that work together:

### ios-architect

Scaffold apps and features with Clean Architecture (Domain/Data/Presentation), MVVM, GRDB, and Swift Concurrency.

- New app scaffolding — Tuist project, Clean Architecture layers, GRDB database, and test targets
- Feature scaffolding — Domain models, repository protocols/implementations, view models, SwiftUI views
- Database & migrations — GRDB schema migrations with versioned migrators
- Testing — Swift Testing, concurrency patterns, dependency injection

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

## Skill Structure

```
ios-architect/
├── SKILL.md
├── evals.json
└── references/
    ├── intake.md
    ├── new-app-scaffold.md
    ├── feature-scaffold.md
    ├── database-and-migrations.md
    └── testing-concurrency-di.md

ios-design-system/
├── SKILL.md
├── evals.json
└── references/
    ├── design-system.md
    └── liquid-glass.md

ios-platform/
├── SKILL.md
├── evals.json
└── references/
    ├── networking.md
    ├── navigation.md
    ├── privacy-and-compliance.md
    └── foundation-models.md
```

## Usage

Tell your AI assistant:

> Create a new iOS app called BudgetTracker with expense tracking and categories.

> Add a Favorites feature to my iOS app with local GRDB persistence.

> Build a reusable card component with Liquid Glass styling.

> Set up URLSession networking with token refresh for my iOS app.

## Evals

Each skill includes an `evals.json` file with trigger and output quality tests (50 total across 3 skills). These validate that the right skill activates for a given prompt and that generated code meets quality assertions.

| Skill | Trigger | No-trigger | Total |
|---|---|---|---|
| ios-architect | 10 | 10 | 20 |
| ios-design-system | 7 | 7 | 14 |
| ios-platform | 8 | 8 | 16 |

Run evals via the **skill-creator** eval/benchmark mode, or use any LLM eval framework (Promptfoo, Braintrust, etc.) by reading the `evals.json` files.

## License

[MIT](LICENSE)
