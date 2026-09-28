---
name: ios-visual
description: >
  Captures deterministic iOS simulator screenshots and compares them with baselines or designs: visual
  regression, layout shifts, dark mode and Dynamic Type variants. For taste or "looks off", also use
  visual-product-quality. Not for code changes (ios-architect).
---

# iOS Visual

This skill proves what the screen shows. It does not judge whether the design is good.

## 1. Know the app's launch contract

Read the repo (`screenshots/*.json`, `AGENTS.md`, and the app entry point reading `ProcessInfo.processInfo.environment`) to find its env vars
for deterministic data and for opening a screen. In `ios-architect/templates` these are `APP_USE_PREVIEW_DATA=1` and `APP_INITIAL_ROUTE=<deep link>`.
Each app names its own (Cifro uses `CIFRO_*`). If the app has no such contract, captures aren't reproducible: say so, and use `ios-architect` to add one.

## 2. Capture

Deterministic: build, install, fixed status bar, launch env, capture.

```bash
screenshots-ios --context screenshots/<screen>.json            # first screen builds
screenshots-ios --context screenshots/<next>.json --skip-build  # remaining screens reuse the build
screenshots-ios --scheme <S> --workspace <W>.xcworkspace --name <screen> --output-dir screenshots/current \
  --launch-env APP_USE_PREVIEW_DATA=1 --launch-env APP_INITIAL_ROUTE=<url>
```

- `screenshots-ios` is on `PATH`. Otherwise run `npx tsx ~/dev/screenshots-ios/src/capture.ts`.
- Output is `<outputDir>/<name>-<timestamp>.png`. Pair files by `<name>` prefix, not by exact filename.
- For a quick look at an app that's already running, with no determinism, use `xcrun simctl io booted screenshot <path>.png`.
  Check first with `xcrun simctl list devices booted`.
- Variants: `xcrun simctl ui booted appearance dark|light`, and `xcrun simctl ui booted content_size extra-extra-extra-large`
  (reset to `large` afterwards). Record which variant each file shows.

## 3. Compare

Read every image at full resolution. Compare only the same screen, device model, iOS runtime, appearance, text size, and data.
A different runtime changes system chrome (bars, buttons, status bar). Report that as a mismatch and recapture the baseline on the runtime you use.
Classify each screen:

- **Unchanged**: no visible delta. This does not mean the screen looks good.
- **Intended delta**: the change matches what was requested.
- **Regression**: an unintended change. Name the element, what moved or changed, and the likely SwiftUI cause.
- **Invalid capture**: wrong state, data, device, or variant, so the comparison can't be trusted. Recapture.

Always check truncation and clipping, overlap with safe areas and bars, and missing or extra elements, plus loading, empty, and error states when they're in scope.
To compare against a design, or for any quality judgment, load `visual-product-quality`.

## 4. Baselines need approval

Never copy captures into `screenshots/baseline/`, stage them, or call the UI approved on your own.
Present the exact files, side by side or as a contact sheet, and wait for the user's explicit approval of those files.
