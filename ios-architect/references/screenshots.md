# Screenshot Automation and Visual QA

Use this file when the user requests screenshot capture, visual regression testing, or App Store asset generation.

## Overview

Automated screenshots capture every screen in the app for visual regression testing. The `AppScreen` manifest (see `navigation.md` in the `ios-platform` skill) is the single source of truth for what screens exist. `PreviewFixture` data (see `feature-scaffold.md`) ensures every capture is deterministic — same data, same layout, every run.

## What ios-architect Generates

When screenshots are in scope (intake specifies "UI/snapshot" test scope or screenshots are requested), ios-architect generates these artifacts before handing off to ios-visual:

| Artifact | Location | Description |
|---|---|---|
| `Preview{Entity}Repository` | `Features/{Feature}/Data/` | In-memory repository seeded from `{Entity}.fixtures` |
| JSON config files | `screenshots/` | One per `AppScreen` case; each has `scheme`, `screenshotName`, `outputDir`, `launchEnv` |
| `APP_USE_PREVIEW_DATA` hook | App entry point | Reads env var to switch to preview repositories |
| `SCREENSHOT_SCREEN` env var hook | `TabRootView.applyScreenshotHook()` | Jumps directly to target screen on launch |
| `PreviewFixture` conformance | Domain models | Fixed IDs and fixed dates for deterministic output |
| `screenshots/capture-all.sh` | `screenshots/` | Batch script that iterates all JSON configs |

**ios-visual depends on these artifacts.** It captures and analyzes — it does not generate fixtures, configs, or env var hooks. If any artifact is missing, ios-architect must scaffold it first.

## App-Side Wiring Contract

The app must support two environment variables so external capture tools can drive it:

### Preview Mode Toggle

Switches to deterministic in-memory data instead of real persistence:

```swift
let usePreview = ProcessInfo.processInfo.environment["APP_USE_PREVIEW_DATA"] == "1"
```

### Screen Navigation

Jumps to a specific screen on launch:

```swift
#if DEBUG
extension TabRootView {
    func applyScreenshotHook() -> some View {
        self.onAppear {
            if let screenName = ProcessInfo.processInfo.environment["SCREENSHOT_SCREEN"],
               let screen = AppScreen(rawValue: screenName) {
                tabRouter.navigate(to: screen)
            }
        }
    }
}
#endif
```

Each `AppScreen` case maps to one screenshot. When adding a new screen to `AppScreen`, the screenshot pipeline automatically picks it up — no separate configuration needed.

### Modal/Sheet Triggers

For screens that present modals or sheets, use additional env vars:

```swift
if ProcessInfo.processInfo.environment["SCREENSHOT_SHOW_SHEET"] == "1" {
    viewModel.activeSheet = .new
}
```

## Preview Repositories

In preview mode, replace real data sources with in-memory implementations seeded from `PreviewFixture`:

```swift
actor Preview{Entity}Repository: {Entity}RepositoryProtocol {
    private var items: [{Entity}]

    init() {
        self.items = {Entity}.fixtures
    }

    func fetchAll() async throws -> [{Entity}] { items }
    func fetchByID(_ id: String) async throws -> {Entity}? { items.first { $0.id == id } }
    func save(_ item: {Entity}) async throws { items.append(item) }
    func delete(_ item: {Entity}) async throws { items.removeAll { $0.id == item.id } }
    func fetch(matching filter: {Entity}Filter) async throws -> [{Entity}] { items }
}
```

Wire at the app root:

```swift
let repository: {Entity}RepositoryProtocol = usePreview
    ? Preview{Entity}Repository()
    : {Entity}Repository(dbManager: dbManager)
```

### Static Seed Data Requirements

Preview fixtures must use deterministic, stable values for consistent screenshots:

- Fixed IDs (e.g., `"fixture-1"`, not `UUID()`)
- Fixed dates (e.g., `Date(timeIntervalSince1970: 1_700_000_000)`, not `Date()`)
- No randomness in any field
- See `PreviewFixture` protocol in `feature-scaffold.md`

## Capture Configuration

Each `AppScreen` case needs a corresponding JSON config file that tells the capture tool which env vars to pass. One file per screen, stored in `screenshots/`:

```json
{
  "scheme": "{AppScheme}",
  "screenshotName": "{feature}List",
  "outputDir": "screenshots/current",
  "launchEnv": {
    "APP_USE_PREVIEW_DATA": "1",
    "SCREENSHOT_SCREEN": "{feature}List"
  }
}
```

The mapping from `AppScreen` to config is mechanical:

| `AppScreen` case | `SCREENSHOT_SCREEN` value | Extra env vars |
|---|---|---|
| `.{feature}List` | `{feature}List` | — |
| `.{feature}Detail` | `{feature}Detail` | — |
| `.{feature}CreateSheet` | `{feature}CreateSheet` | `SCREENSHOT_SHOW_SHEET=1` |
| `.{feature}EditSheet` | `{feature}EditSheet` | `SCREENSHOT_SHOW_SHEET=1` |
| `.settings` | `settings` | — |

For screens that need additional state (e.g., a specific filter pre-selected, dark mode), add extra env vars to `launchEnv` and read them in the app.

When adding a new `AppScreen` case:
1. Add the case to the enum and wire its `ScreenPath` (see `navigation.md`).
2. Create a new JSON config file in `screenshots/` with the matching `SCREENSHOT_SCREEN` value.
3. The batch capture script discovers configs automatically — no manual update needed.

## Running the Capture

Before creating or running a capture script, the agent must detect how the project captures screenshots:

1. **Check for an existing capture script** — look for `screenshots/capture-all.sh`, a `screenshots` npm script in `package.json`, or a `Makefile` target.
2. **Check for a capture tool** — look for screenshot tool references in `package.json` dependencies, `CLAUDE.md`, `README.md`, or shell scripts in the project.
3. **Ask the user** if nothing is found — "How do you capture screenshots? Do you have a tool or script for this?"

Never assume a specific runtime (Node, Python, Ruby) is installed. If the project uses a Node-based tool, verify `npx` or `node` is available before invoking it. If it uses a Swift-based tool, verify `swift` is available. If no tool exists, fall back to `xcrun simctl io booted screenshot` as a baseline — it requires only Xcode.

## Batch Capture Script

Build once, then reuse the build for remaining screens. The capture tool should support a skip-build flag:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# Discover screens dynamically from JSON config files in screenshots/
CONFIGS=("$SCRIPT_DIR"/*.json)
if [[ ${#CONFIGS[@]} -eq 0 || ! -e "${CONFIGS[0]}" ]]; then
  echo "No screenshot configs found in $SCRIPT_DIR" >&2
  exit 1
fi

for i in "${!CONFIGS[@]}"; do
  skip=""
  [[ "$i" -gt 0 ]] && skip="--skip-build"
  # Replace with the project's capture tool invocation:
  <capture-tool> --context "${CONFIGS[$i]}" $skip
done
```

## Screenshot Output Layout

Screenshots are saved to a known directory with predictable names derived from `AppScreen.rawValue`:

```
{project}/
├── screenshots/
│   ├── {feature}List.json        # Capture configs
│   ├── {feature}Detail.json
│   ├── settings.json
│   ├── capture-all.sh
│   ├── baseline/                  # Last approved set (committed to repo)
│   │   ├── {feature}List.png
│   │   ├── {feature}Detail.png
│   │   ├── {feature}CreateSheet.png
│   │   └── settings.png
│   └── current/                   # Latest capture (gitignored)
│       ├── {feature}List.png
│       ├── {feature}Detail.png
│       ├── {feature}CreateSheet.png
│       └── settings.png
```

- `baseline/` — committed to the repo. Represents the last visually approved state.
- `current/` — gitignored. Generated each capture run. Compared against baseline.

## Visual QA Workflow

After UI changes, capture screenshots and compare against baseline. The agent performing visual QA should follow this process:

**1. Read both images for each screen:**

For every file in `screenshots/current/`, read the corresponding `screenshots/baseline/` image.

**2. Compare each pair and check for:**

- **Layout shifts** — did spacing, alignment, or sizing change unexpectedly?
- **Missing or extra elements** — did a button disappear, did a new element appear that shouldn't be there?
- **Text content** — is the fixture data rendering correctly? Are labels, titles, and values present?
- **State correctness** — does the detail screen show the entity? Does the empty state show the right message? Is the correct tab selected?
- **Design system compliance** — are fonts, colors, spacing consistent with the design tokens?
- **Truncation and clipping** — is any text cut off? Are elements overlapping?

**3. Report findings per screen:**

For each screen, report one of:
- **Pass** — no visual changes, or changes are intentional and correct.
- **Expected change** — visual change detected, consistent with the code change being reviewed.
- **Regression** — unintended visual change that needs fixing.

**4. Approve or reject:**

If all screens pass, copy `current/` to `baseline/` and commit.

## When to Capture Screenshots

- After any Presentation-layer change (views, view models, design system tokens).
- After adding a new screen (new `AppScreen` case).
- Before submitting a PR that touches UI.
- After resolving merge conflicts in view files.

## Integration with Feature Scaffold

When intake specifies "UI/snapshot" test scope or screenshots are explicitly requested:

1. Generate `Preview{Entity}Repository` alongside the real repository implementation.
2. Generate a sample JSON context file for the feature's main screen in `screenshots/`.
3. Add the `APP_USE_PREVIEW_DATA` toggle to the app entry point if not already present.
4. Ensure all domain models have `PreviewFixture` conformance with deterministic data.

## Xcode Preview with Direct Router State

For rapid iteration in previews, set the router stack directly using fixture data:

```swift
#Preview("{Feature} Detail") {
    let router = AppRouter()
    router.stack = [.{feature}Detail(.fixture)]

    return NavigationStack(path: .constant(router.stack)) {
        EmptyView()
            .navigationDestination(for: AppRoute.self) { route in
                route.destinationView
            }
    }
}
```
