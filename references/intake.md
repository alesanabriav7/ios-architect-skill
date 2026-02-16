# Intake and Workflow

Use this file for every request before generating files.

## Build Type Prompt

Ask:

1. New app from scratch
2. New feature module
3. New shared service
4. New shared model
5. New design system component
6. New database migration
7. New local SPM package

Then ask:

- What is it called?
- What does it do?
- Which fields and behaviors are required?

## Required Intake Fields

Capture this checklist in short form:

- Build type
- Target path/module
- User flow and screens
- Domain entities and key fields
- Data source (local DB, API, or both)
- Integration points (shared services, existing features, notifications)
- Test scope (unit, integration, UI/snapshot)

If the request is underspecified, state safe defaults and continue.

## Output Contract

Always:

- Emit complete, compilable code.
- Replace all placeholders (for example `{AppName}`, `{Feature}`).
- Keep architecture boundaries explicit (Domain/Data/Presentation).
- Use modern APIs (`@Observable`, `@MainActor`, async/await, Swift Testing).

Never:

- Return pseudo-code when the user asked for implementation.
- Mix storage framework details into Domain.
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
