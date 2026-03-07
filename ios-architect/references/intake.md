# Intake and Workflow

Use this file for every request before generating files.

## Build Type Prompt

Ask:

1. New app from scratch
2. New feature module
3. New cross-domain shared service
4. New cross-domain shared model
5. New database migration
6. New local SPM package

Then ask:

- What is it called?
- What does it do?
- Which fields and behaviors are required?
- Is it feature-owned or cross-domain shared? If shared, which 2+ features/domains consume it?
- If fetching lists from a remote API, what pagination strategy is used (cursor / offset / full fetch)?

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

If the request is underspecified, state safe defaults and continue.

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

## Sister Skill Handoff Checklist

After intake, check if the request needs sister skills:

- **Custom UI components, theming, or Liquid Glass styling** → invoke the `ios-design-system` skill
- **API client setup, networking** → invoke the `ios-platform` skill (networking reference)
- **Navigation overhaul, deep linking, iPad/multi-column** → invoke the `ios-platform` skill (navigation reference)
- **Privacy manifests, Required Reason APIs, account deletion** → invoke the `ios-platform` skill (privacy reference)
- **On-device AI / Foundation Models** → invoke the `ios-platform` skill (foundation-models reference)
