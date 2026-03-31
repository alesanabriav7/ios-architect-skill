---
name: ios-design-system
description: >
  Use when someone wants to create or update a reusable UI component, set up the app's
  visual language, or apply visual styling. This covers: building reusable buttons, cards,
  or list rows, setting up color tokens, typography, and spacing constants, applying Liquid
  Glass effects, and ensuring components follow the design system. The user might say
  "create a reusable card component", "set up the color palette", "add a glass effect to
  the toolbar", "this button should match the design system", or "build a loading skeleton
  view". Not for: building complete feature screens with business logic (ios-architect),
  or checking if the running app looks correct (ios-visual).
license: MIT
allowed-tools: Read Bash(swift:*)
metadata:
  author: alesanabriav7
  version: "1.0.0"
---

# iOS Design System

Emit compile-ready SwiftUI components using the token system. Validate accessibility (contrast, Dynamic Type).

## Load Strategy

1. Always read `references/design-system.md`.
2. If iOS 26+ or Liquid Glass styling is mentioned, also read `references/liquid-glass.md`.

## Execution Contract

1. Emit compile-ready SwiftUI components using the token system (Space, Radius, Color, font modifiers).
2. Validate accessibility: minimum contrast ratios, Dynamic Type support, VoiceOver labels.
3. Keep components in the design system package — not in feature modules.
4. If the request requires creating a new feature module (not just a component), reference the `ios-architect` skill for architecture placement and scaffolding.

## Sister Skills

- **ios-architect** — app/feature scaffolding, architecture boundaries, persistence, testing
- **ios-platform** — networking, navigation, privacy, Foundation Models
