---
name: ios-persistence
description: >
  ONLY for isolated database operations — no Domain/Data/Presentation scaffolding. Use
  when someone has a focused database or local storage task: setting up a database,
  adding or changing a column or table, writing a query, making a view auto-update when
  data changes, or caching data locally (API responses, images, user content). The user
  might say "save this to disk", "add a column for avatarURL", "the list should update
  automatically", "how do I query entries by date?", "set up the database", "cache the
  API responses", "add a local cache to reduce network calls", or "the data isn't
  persisting between launches".
  Not for building a full feature. When someone says "add offline support to a feature"
  or "make this feature work without internet", that is a full feature change handled by
  ios-architect, which includes DB patterns as part of the scaffold.
license: MIT
allowed-tools: Read Bash(swift:*) Bash(tuist:*)
metadata:
  author: alesanabriav7
  version: "1.0.0"
---

# iOS Persistence

Emit compile-ready GRDB code. Never produce N+1 queries. Keep all database access in the Data layer.

## Load Strategy

Always read `references/persistence.md`.

## Execution Contract

1. Domain layer: repository protocol only — no GRDB imports.
2. Data layer: `FetchableRecord` + `PersistableRecord` records, repository implementation, `DatabaseManager` usage.
3. Migrations are append-only — never modify existing migration identifiers.
4. Aggregates must be computed in SQL (`GROUP BY`, `SUM`, `COUNT`) — never in Swift loops.
5. Use `ValueObservation` for list views that need live updates.
6. Validate with a targeted build after changes.

## Sister Skills

- **ios-architect** — app/feature scaffolding, Domain/Data/Presentation layers
- **ios-testing** — Swift Testing, mock repositories, DI patterns
- **ios-platform** — networking, navigation, privacy, Foundation Models
