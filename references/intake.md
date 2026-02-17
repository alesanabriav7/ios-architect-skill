# Intake and Workflow

Use this file for every request before generating files.

## Build Type Prompt

Ask:

1. New app from scratch
2. New feature module
3. New cross-domain shared service
4. New cross-domain shared model
5. New design system component
6. New database migration
7. New local SPM package

Then ask:

- What is it called?
- What does it do?
- Which fields and behaviors are required?
- Is it feature-owned or cross-domain shared? If shared, which 2+ features/domains consume it?
- Does it require on-device AI (`FoundationModels`)? If yes, single response or streaming?
- Should the UI adopt Liquid Glass (`iOS 26+`) styling? If yes, which screens/components?
- If Liquid Glass is enabled, should search use native `.searchable(...)` (default) or a custom in-content search field (exception)?
- Are there TabView behavior changes (tab set, per-tab search/filter state, tab-level controls)?
- What is the fallback behavior when AI is unavailable?

## Required Intake Fields

Capture this checklist in short form:

- Build type
- Target path/module
- Ownership decision (feature-local by default, or cross-domain shared with explicit consumers)
- User flow and screens
- Domain entities and key fields
- Data source (local DB, API, or both)
- Integration points (shared services, existing features, notifications)
- Test scope (unit, integration, UI/snapshot)
- UI style constraints (standard tokens only, or include Liquid Glass on iOS 26+)
- Liquid Glass scope details (native searchable usage, TabView behavior updates, custom-surface exceptions, fallback expectations)
- AI mode (none, single-shot generation, or streaming)
- AI fallback path (template/rules-based behavior)
- Prompt input boundaries (what data is allowed to be sent to the model)

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
