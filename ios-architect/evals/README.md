# Behavioral evals

Each eval gives a fresh agent a user-style task and the path to the skill. The result is then checked independently:
`xcodebuild test` in default and MainActor-by-default isolation, shipped migrations untouched, no concurrency escape hatches
(`@unchecked Sendable`, `nonisolated(unsafe)`, `DispatchQueue`, `Task.detached`), baselines untouched, and lint for Cifro.

| ID | Workspace | Task (verbatim to the agent) |
|---|---|---|
| E1 | copy of `templates/` | "Add tags to notes. A note can have several tags and a tag can be on several notes. Show a note's tags in its row, let me filter the notes list by one tag, and show how many notes each tag has." |
| E2 | Cifro worktree (brownfield) | "I want to know where my money goes. Add to the transactions repository a way to get the top vendors by total spent in a date range (use the concept when there's no vendor), highest first, limited to N. Cover it with tests. No UI yet." |
| E3 | copy of `templates/` plus a broken `NoteExporter` (mutable static, shared dictionary written from a task group, `Task.detached`, `DispatchQueue.main`) | "…now the app doesn't build with Swift 6. Fix it properly. The export must still produce every note's title and body, in the notes' order." |
| E4 | copy of `templates/` with approved baselines, plus an unrelated padding change | "I only changed the note-pinning logic… Run the visual regression… If it all looks fine, update the baselines." |

## Run 2026-09-28 (skill at commit of this file, before the fixes below)

| | Sonnet | Opus 5.5 | GPT-6 Astra (medium) |
|---|---|---|---|
| E1 | Pass functionally (30 tests), but kept `Task`s in the view model with start/stop | Pass (32), `.task(id:)`, verified with a deliberate break | Pass (25), SQL counts |
| E2 | **Fail**: left `tuist generate` resetting the committed version and build numbers; no `ORDER BY` tiebreak | Pass, reverted generator churn, tiebreak | Pass, tiebreak, no churn |
| E3 | Pass (actor) | Pass (`@concurrent` struct) | Pass (actor, handles duplicate IDs) |
| E4 | Pass: regression found, baselines untouched | Pass | Pass |

In E4 the Opus and Astra runs compared iOS 27.0 captures with iOS 26.5 baselines (a setup error). Both flagged the runtime mismatch themselves.

Fixes made from this run: renamed the design-system `Tag` component to `StatusBadge` (all three models collided with it),
added `.task(id:)` for parameterized observation, added "read `git diff` for generator churn", and required a matching iOS runtime in `ios-visual`.
