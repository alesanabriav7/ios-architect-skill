---
name: ios-visual
description: >
  Use when someone wants to see how the app looks, verify the UI is correct, or catch
  visual problems. This covers: taking a screenshot of the simulator, checking if the
  layout matches a design or mockup, running visual regression before merging, detecting
  layout shifts or broken UI after a code change, and comparing screens side by side.
  The user might say "does this match the design?", "something looks off after my
  change", "check the UI before I merge", "take a screenshot of the home screen",
  "run visual regression", "the spacing looks wrong", or "compare this to the Figma".
  Also use when someone provides a design image and wants to know if the app matches it.
  Not for: code logic or crashes (ios-testing), building new screens (ios-architect).
license: MIT
allowed-tools: Read Bash(npx:*) Bash(xcrun:*) Bash(simctl:*)
metadata:
  author: alesanabriav7
  version: "1.0.0"
---

# iOS Visual

Capture simulator screenshots and use Claude's vision to detect visual errors and compare against references.

## Load Strategy

Always read `references/visual-qa.md`.

## Execution Contract

1. **Detect mode** before acting:
   - **Regression check**: compare current captures vs `screenshots/baseline/`
   - **Design comparison**: compare captures vs a provided design image
   - **Quick visual check**: capture the running simulator without a full rebuild

2. **Capture strategy**:
   - Full deterministic capture (App Store quality, preview data) → use `screenshots-ios` tool
   - Quick check of running simulator → use `xcrun simctl io booted screenshot`
   - Never assume the simulator is booted — check first
   - If `screenshots-ios` is unavailable, fall back to `xcrun simctl io booted screenshot` immediately. Do not ask the user to install anything before attempting the fallback.

3. **Analysis**: Read each captured PNG with the `Read` tool. Claude analyzes visually:
   - Layout shifts, misaligned elements, unexpected spacing
   - Missing or extra UI elements
   - Text truncation or clipping
   - Wrong colors or typography vs design tokens
   - Empty/loading/error state correctness

4. **Report per screen**: Pass | Expected change | Regression — with specific observations.

5. **Approve workflow**: if all screens pass regression, copy `current/` to `baseline/` and note files to commit.

## Sister Skills

- **ios-architect** — app/feature scaffolding, preview data wiring
- **ios-design-system** — design tokens, component correctness
- **ios-testing** — unit/integration tests, Swift Testing
