# Persistence (GRDB)

Reference code: `templates/App/Sources/Core/Database/AppDatabase.swift`, `Features/Notes/Data/`, `App/Tests/AppDatabaseTests.swift`, `GRDBNoteRepositoryTests.swift`.

## Setup

- Inject an `AppDatabase` value from the composition root. Use `DatabasePool` for a file in Application Support
  (or an App Group container when widgets or extensions share it), and an in-memory `DatabaseQueue` for tests and previews.
- With Tuist, raise GRDB's deployment target in `Tuist/Package.swift` `targetSettings`. Xcode 26+ rejects GRDB's declared iOS 13.

## Migrations

- Migrations are append-only. Register new ones at the end with descriptive IDs, and never edit, rename, or reorder a shipped migration.
- A new `NOT NULL` column needs a default. Backfill with SQL inside the migration, never in app code at launch.
- Don't enable `eraseDatabaseOnSchemaChange`: it deletes real data on any device running a debug build.
- Test every schema change: migrating twice is a no-op, and data written at the previous version survives (`migrate(_:upTo:)`, then insert, then migrate).

## Records and queries

- Records live in Data, are `nonisolated`, and map to Domain models. GRDB types never leave Data.
- Compute aggregates in SQL (`COUNT`, `SUM`, `GROUP BY`). Never run a query per row inside a Swift loop.
  Load children with associations (`including(all:)`) or one join.
- Add indexes on columns you filter, join, or sort on. Every list query has a deterministic `ORDER BY`.
- A user action is one `writer.write` transaction. Reads go through `reader.read`.
- Store money as integer minor units (or `Decimal` text), never `Double`.

## Live updates

- Return GRDB's own sequence (`ValueObservation.values(in:)`) as `any AsyncSequence<[T], any Error>` (see `observeAll()`).
  Don't wrap it in an `AsyncThrowingStream` fed by an inner `Task`: cancelling the consumer then leaves that task running.
- The view model consumes it in an `async` method called from `.task`. SwiftUI cancels the task, which ends the observation.
  When the query depends on state (a filter, a selected ID), use `.task(id: thatState)`: SwiftUI cancels and restarts it when the value changes.
  Don't keep the `Task` in the view model and cancel it in `deinit`: that fails to compile under `@MainActor`, and `[weak self]` plus a strong loop leaks.

## Cache vs. database

- Server-owned data you only display goes in `URLCache` or a file cache in `Caches/`, which the OS may purge.
- User-owned, queryable, or offline-editable data goes in GRDB. In offline-first sync the local database is the source of truth.
  Track unsynced local edits explicitly (for example a `syncState` column) and never let a remote payload overwrite them silently.
