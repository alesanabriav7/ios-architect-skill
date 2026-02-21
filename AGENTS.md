# Contributing to ios-architect

## Architecture Rules

- **Clean Architecture boundaries are strict.** Domain contains models and protocols only. Data contains repository implementations and records. Presentation contains SwiftUI views, view models, and feature UI components.
- **Feature-local by default.** All models, repositories, and view models belong to the feature that owns them. Only promote to `Shared/` when two or more features depend on the same capability.
- **No catch-all buckets.** Never create `Shared/Models`, `Shared/Data`, or similar generic groupings.

## Code Style

- Use modern Swift APIs: `@Observable`, `@MainActor`, Swift Concurrency, Swift Testing.
- No opinionated formatting rules — follow whatever the project already uses.
- Generated code must be compile-ready with concrete names (no placeholders).

## Skill Structure

- `ios-architect/SKILL.md` is the skill entry point with frontmatter and load strategy.
- `ios-architect/references/` contains domain-specific reference files loaded on demand.
- Only load the references needed for the current task. Do not bulk-load all references.

## Adding References

1. Create a new `.md` file in `ios-architect/references/`.
2. Add it to the load strategy in `SKILL.md` under the appropriate build type.
3. Keep references focused on a single concern (e.g., networking, navigation, testing).
