---
name: ios-platform
description: >
  Use when someone needs to connect the app to a backend, set up navigation infrastructure,
  handle platform compliance, or add on-device AI. This covers: calling a REST or GraphQL
  API, handling authentication and token refresh, setting up URLSession, implementing deep
  links, building iPad split-view layouts, adding Foundation Models for on-device AI, and
  App Store privacy manifests. The user might say "call this API", "handle token refresh",
  "set up deep links", "add on-device AI", "I need a privacy manifest", or "build the
  iPad layout with a sidebar". Not for: building the feature's Domain/Data/Presentation
  layers (ios-architect), storing data locally (ios-persistence), or UI components
  (ios-design-system).
license: MIT
allowed-tools: Read Bash(swift:*)
metadata:
  author: alesanabriav7
  version: "1.0.0"
---

# iOS Platform

Emit compile-ready code following Clean Architecture (Domain protocol + Data implementation).

## Load Strategy

Read only the reference(s) relevant to the request:

- API/networking → `references/networking.md`
- Routing/deep linking/iPad navigation → `references/navigation.md`
- Privacy/compliance → `references/privacy-and-compliance.md`
- On-device AI → `references/foundation-models.md`

Do not bulk-load all references when the task is narrow.

## Execution Contract

1. Emit compile-ready code following Clean Architecture (Domain protocol + Data implementation).
2. Keep framework imports (`URLSession`, `FoundationModels`, etc.) in the Data layer only.
3. Domain layer contains only protocols and models — no platform imports.
4. If the request requires a full feature module (not just infra setup), reference the `ios-architect` skill for scaffolding and architecture boundaries.
5. If on-device AI is included, enforce runtime availability checks and deterministic fallback.

## Sister Skills

- **ios-architect** — app/feature scaffolding, architecture boundaries, persistence, testing
- **ios-design-system** — design tokens, UI components, Liquid Glass styling
