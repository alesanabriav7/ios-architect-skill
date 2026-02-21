# ios-architect

A skill for scaffolding modern iOS apps and features with Clean Architecture, MVVM, SwiftUI, GRDB, Swift Concurrency, and modular local packages.

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

Clone the repo and symlink or copy the `ios-architect/` directory into your project's `.claude/skills/` folder:

```bash
git clone https://github.com/alesanabriav7/ios-architect-skill.git
cp -r ios-architect-skill/ios-architect .claude/skills/ios-architect
```

## What the Skill Offers

- **New app scaffolding** — Tuist project, Clean Architecture layers, GRDB database, design system, and test targets
- **Feature scaffolding** — Domain models, repository protocols/implementations, GRDB records, view models, SwiftUI views
- **Database & migrations** — GRDB schema migrations with versioned migrators
- **Design system** — Reusable SwiftUI components, color tokens, typography
- **Networking** — URLSession-based API clients with async/await
- **Navigation** — Coordinator pattern with deep linking support
- **Testing** — Swift Testing, concurrency patterns, dependency injection
- **Privacy & compliance** — Privacy manifests, required reason APIs
- **Foundation Models** — On-device AI with deterministic fallback
- **Liquid Glass** — iOS 26+ Liquid Glass styling with version-gated fallbacks

## Skill Structure

```
ios-architect/
├── SKILL.md
└── references/
    ├── intake.md
    ├── new-app-scaffold.md
    ├── feature-scaffold.md
    ├── database-and-migrations.md
    ├── design-system.md
    ├── testing-concurrency-di.md
    ├── networking.md
    ├── navigation.md
    ├── privacy-and-compliance.md
    ├── foundation-models.md
    └── liquid-glass.md
```

## Usage

Tell your AI assistant:

> Use the ios-architect skill. I want to build a new app called BudgetTracker.

> Use the ios-architect skill. I need a new Subscriptions feature with title, amount, billing cycle, and next billing date.

> Use the ios-architect skill. Add Liquid Glass styling to the finance dashboard.

## License

[MIT](LICENSE)
