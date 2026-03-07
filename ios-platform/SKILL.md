---
name: ios-platform
description: Networking, API clients, navigation, routing, deep linking, privacy manifests, compliance, and on-device AI with Foundation Models for iOS apps. Use when setting up API clients, URLSession, authentication, routing, deep links, NavigationSplitView, privacy manifests, account deletion, Foundation Models, or on-device AI.
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
