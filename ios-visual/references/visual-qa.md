# Visual QA Reference

Use this file for screenshot capture, visual regression, and pixel-perfect design comparison.

## Prerequisites

ios-architect must have already scaffolded the fixture/preview layer before ios-visual can run capture. Verify:

- `Preview{Entity}Repository` exists in the Data layer
- At least one JSON config file exists in `screenshots/`
- The app entry point reads `APP_USE_PREVIEW_DATA` env var
- `AppScreen` enum cases are defined and wired to `navigationPath`

If any prerequisite is missing, invoke `ios-architect` to generate the screenshot scaffold first.

## Tool Availability Check

Before any capture, verify the primary tool is available:

```bash
which screenshots-ios || echo MISSING
```

If MISSING, fall back to `xcrun simctl io booted screenshot` immediately. Log which tool was used in your capture report.

## Capture Tools

### screenshots-ios (deterministic, production-quality)

Your primary capture tool. Builds, installs, launches with preview data, overrides status bar, captures.

```bash
# Single screen — full build
npx tsx "$SCREENSHOTS_IOS_DIR/src/capture.ts" --context screenshots/<screen>.json

# Single screen — skip rebuild (reuse last build)
npx tsx "$SCREENSHOTS_IOS_DIR/src/capture.ts" --context screenshots/<screen>.json --skip-build

# Quick check of already-running simulator
xcrun simctl io booted screenshot /tmp/quick-check.png
```

Set `SCREENSHOTS_IOS_DIR` to the local clone of the `screenshots-ios` tool (e.g. `export SCREENSHOTS_IOS_DIR=~/dev/screenshots-ios`).

Context file fields: `scheme`, `simulator`, `outputDir`, `screenshotName`, `waitSeconds`, `launchEnv`.
Full reference: `$SCREENSHOTS_IOS_DIR/GUIDE.md`.

### Quick capture (no build required)

When the simulator is already running with the right state:

```bash
# Check if a simulator is booted
xcrun simctl list devices | grep Booted

# Capture current simulator screen
xcrun simctl io booted screenshot /tmp/visual-check-$(date +%s).png
```

Use this for fast iteration when the dev has the app open and wants a quick visual check. No deterministic data guarantee — report findings as observations, not regressions.

## Capture Modes

| Mode | Tool | When to Use |
|------|------|-------------|
| **Regression** | `screenshots-ios` | After any UI code change, before PR |
| **Design comparison** | `screenshots-ios` | Matching a Figma/design reference |
| **Quick check** | `xcrun simctl io booted screenshot` | Running app is already in the right state |

## App-Side Requirements

For deterministic captures, the app must support:

- `APP_USE_PREVIEW_DATA=1` → switches to in-memory seed data
- `APP_INITIAL_SCREEN=<screenName>` → navigates to a specific screen on launch
- Optional sheet triggers via additional env vars (e.g., `APP_SHOW_SHEET=1`)

See `ios-architect` references for `PreviewFixture` protocol and wiring contract.

## Visual Analysis Workflow

After capturing, read each PNG with the `Read` tool. Analyze each screen for:

### Layout & Spacing
- Are spacing values consistent with design tokens (`Space.xs`, `Space.md`, etc.)?
- Is content properly aligned (leading/trailing margins, vertical rhythm)?
- Are padding/insets correct around safe area edges?

### Typography
- Are font sizes and weights correct?
- Is text truncating unexpectedly? Check with long fixture strings.
- Is Dynamic Type scaling properly (test with `accessibilityExtraExtraLarge`)?

### Colors & Theming
- Do background colors match the app's color tokens?
- Are interactive elements (buttons, tappable rows) using the correct accent color?
- Does dark/light mode switch correctly?

### UI Completeness
- Are all expected elements visible (titles, CTAs, icons, badges)?
- Are loading/empty/error states correct when triggered?
- Are navigation bars and tab bars rendering correctly?

### Design Token Compliance
- Are corner radii consistent with the design system (`Radius.md`, `Radius.lg`)?
- Are shadows/elevation correct where specified?
- Are icon sizes matching the design grid?

## Regression Workflow

```
screenshots/
├── baseline/           ← last approved set (committed)
│   └── <screen>.png
└── current/            ← latest run (gitignored)
    └── <screen>.png
```

**Step 1**: Capture all screens into `current/`.

```bash
./screenshots/capture-all.sh
```

**Step 2**: For each file in `current/`, read both the current and baseline image with `Read`.

**Step 3**: Compare and classify each screen:
- **Pass** — no visual change, or change is intentional and expected.
- **Expected change** — visual change present, matches the code change being reviewed.
- **Regression** — unintended visual change. Describe exactly what shifted.

**Step 4**: If all pass or expected:
```bash
cp screenshots/current/* screenshots/baseline/
git add screenshots/baseline/
```

## Design Comparison Workflow (Pixel Perfect)

When the user provides a design reference image (Figma export, mockup screenshot, etc.):

1. Read both the captured screenshot and the design image with `Read`.
2. Compare at element level — don't just say "looks different", identify what specifically differs:
   - Element position (is this button 8pt lower than the design?)
   - Size discrepancies (is this card narrower than in the design?)
   - Color mismatches (wrong tint, missing opacity)
   - Typography differences (wrong weight, wrong size)
   - Missing elements (design shows a badge, app doesn't have it)
3. Prioritize findings: P1 (visible to users, must fix) vs P2 (subtle, optional).
4. For each P1 finding, identify the likely SwiftUI code to change.

## Batch Capture Script Pattern

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TOOL="${SCREENSHOTS_IOS_DIR}/src/capture.ts"

cd "$REPO_ROOT"

SCREENS=(home detail settings)

for i in "${!SCREENS[@]}"; do
  screen="${SCREENS[$i]}"
  skip=""
  [[ "$i" -gt 0 ]] && skip="--skip-build"
  npx tsx "$TOOL" --context "$SCRIPT_DIR/${screen}.json" $skip
done
```

## Common Issues

| Symptom | Fix |
|---------|-----|
| Screenshot is blank/black | Increase `waitSeconds` in context file |
| Wrong screen appears | Verify app reads the env var; add debug print in `.onAppear` |
| `No available simulator` | Run `npx tsx "$SCREENSHOTS_IOS_DIR/src/capture.ts" --list-devices` |
| `Built app not found` | Remove `--skip-build` to trigger fresh build |
| Status bar looks wrong | Set `statusBar.enabled: false` for older simulators |
| Capture works but data is wrong | Check `APP_USE_PREVIEW_DATA` is read at app entry point |
