# Intake and Workflow

Use this file for every request before generating files.

## Build Type

Infer the build type from context — never ask. Resolve assumptions inline and proceed:

1. New app from scratch
2. New feature module
3. New cross-domain shared service
4. New cross-domain shared model
5. New database migration → route to `ios-persistence` instead
6. New local SPM package

For each, infer from context or state the assumption:
- Name (PascalCase feature name)
- Purpose (one sentence)
- Ownership: feature-local (default) or cross-domain shared (if 2+ distinct consumers named)
- Pagination strategy for remote list fetches: cursor / offset / full fetch (default: full fetch)

## Project Settings Detection

Run this step when the request involves existing code, concurrency patterns, or Swift 6 migration. Skip for greenfield apps — defaults apply.

Check these locations:

- `Package.swift`: `swiftLanguageVersions`, `.enableExperimentalFeature("StrictConcurrency")`, `.defaultIsolation(MainActor.self)`, platform deployment target
- Xcode build settings: `SWIFT_VERSION` (Swift Language Version), `SWIFT_STRICT_CONCURRENCY` (Strict Concurrency Checking), `IPHONEOS_DEPLOYMENT_TARGET`

If the file is not accessible or the context is non-interactive, state the assumption explicitly and proceed. Never silently assume a concurrency or language version setting.

## Required Intake Fields

Capture this checklist in short form:

- Build type
- Minimum deployment target
- Target path/module
- Ownership decision (feature-local by default, or cross-domain shared with explicit consumers)
- User flow and screens
- Domain entities and key fields
- Data source (local DB only, remote API only, remote API + response cache, or both with offline-first sync)
- Integration points (shared services, existing features, notifications)
- Test scope (unit, integration, UI/snapshot)
- Screenshot capture (Do you need screenshot capture for App Store assets or visual regression? If yes, load `references/screenshots.md`)

If the request is underspecified, state safe defaults and continue.

## Non-Interactive Fallback

Skip intake if the prompt contains ALL THREE: (1) what the feature is called, (2) what it does in one sentence, (3) where data comes from (local, remote, or both). If any is missing, infer from context and state the assumption inline, then proceed. Never wait for a reply.

Apply safe defaults for missing fields:
- Minimum deployment target: iOS 18.0
- Ownership: feature-local
- Data source: infer from prompt; default to in-memory if unclear
- Test scope: unit tests for ViewModel

Proceed directly to code generation with all three layers (Domain, Data, Presentation).

## Output Contract

Always:

- Emit complete, compilable code.
- Replace all placeholders (for example `{AppName}`, `{Feature}`).
- Keep architecture boundaries explicit (Domain/Data/Presentation).
- Keep feature code in feature modules; use `Shared` only for proven cross-domain capabilities.
- Use modern APIs (`@Observable`, `@MainActor`, async/await, Swift Testing).

Never:

- Return pseudo-code when the user asked for implementation.
- Mix storage framework details into Domain.
- Put feature models/data/services into generic shared folders.
- Use `try!` for initialization paths that can fail.

## Completeness Gate

Before reporting completion, verify you generated files in ALL three layers:
- [ ] At least one Domain model struct
- [ ] At least one repository protocol
- [ ] At least one repository implementation
- [ ] At least one ViewModel with `@Observable @MainActor`
- [ ] At least one SwiftUI View that uses the ViewModel

If any checkbox is missing, generate the missing files before reporting.

## Validation Contract

After generation, run the lightest relevant checks:

- New app: `tuist generate` then build one scheme.
- Existing project feature/module: targeted build or tests for touched modules.
- If commands are unavailable, state exactly what could not run.

## Delivery Contract

Report:

- Files created/updated
- Checks executed and outcomes
- Assumptions/defaults applied

## Naming Conventions

Apply these consistently across all generated code. Never mix conventions in one file. Placeholder values must be resolved before emitting code — no literal `{Feature}` in generated output.

- `{AppName}` — PascalCase, the Tuist project name (e.g. `BudgetTracker`)
- `{Feature}` — PascalCase, the feature module name (e.g. `Expense`, `Category`, `Settings`)
- `{Entity}` — PascalCase, the domain model name (often same as Feature, but can differ; e.g. Feature `Expense`, Entity `ExpenseEntry`)
- `{Prefix}` — same as `{AppName}`, used for shared package components (e.g. `{Prefix}DesignSystem`, `{Prefix}Card`, `{Prefix}TextField`)
- `{app_name}` — snake_case version of AppName, used for file paths, database names, and CI scripts (e.g. `budget_tracker.sqlite`)

## Sister Skill Handoff Checklist

After intake, check if the request needs sister skills:

- **Custom UI components, theming, or Liquid Glass styling** → invoke the `ios-design-system` skill
- **API client setup, networking** → invoke the `ios-platform` skill (networking reference)
- **Navigation overhaul, deep linking, iPad/multi-column** → invoke the `ios-platform` skill (navigation reference)
- **Privacy manifests, Required Reason APIs, account deletion** → invoke the `ios-platform` skill (privacy reference)
- **On-device AI / Foundation Models** → invoke the `ios-platform` skill (foundation-models reference)
