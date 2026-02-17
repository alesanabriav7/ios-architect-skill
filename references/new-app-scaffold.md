# New App Scaffold

Use this file when scaffolding a new app or adding new local packages.

## Target Structure

```text
{AppName}/
├── Project.swift
├── Tuist.swift
├── {AppName}/
│   ├── {AppName}App.swift
│   ├── ContentView.swift
│   ├── Features/
│   │   └── {Feature}/
│   │       ├── Domain/
│   │       │   ├── Models/
│   │       │   └── Interfaces/
│   │       ├── Data/
│   │       │   ├── Repositories/
│   │       │   └── Records/
│   │       └── Presentation/
│   │           ├── Views/
│   │           ├── ViewModels/
│   │           └── Components/
│   ├── Shared/
│   │   ├── Settings/
│   │   │   ├── Domain/
│   │   │   ├── Data/
│   │   │   └── Presentation/ (optional)
│   │   └── Core/
│   │       └── Services/
│   └── Assets.xcassets/
├── {Prefix}Database/
├── {Prefix}DesignSystem/
├── {Prefix}SharedComponents/
├── {Prefix}Notifications/   (optional)
└── {AppName}Tests/
```

Naming:

- `{Prefix}`: 2-3 uppercase letters derived from app name.
- Keep module names explicit and singular by feature concept.

Ownership rule:

- Default all app models/services/repositories to their owning feature module.
- Add `Shared` modules only when reused by at least two features/domains.
- Model shared code as domain modules (for example `Shared/Settings/...`) with clear layer boundaries.
- Never create generic buckets like `Shared/Models` or `Shared/Data`.

## Scaffolding Order

1. Tuist files (`Project.swift`, `Tuist.swift`) with bundle ID and default iOS 18+ target.
2. Local packages (`{Prefix}Database`, `{Prefix}DesignSystem`, optional cross-domain packages).
3. App entry (`{AppName}App.swift`) and root navigation (`ContentView.swift`).
4. First feature Domain/Data/Presentation stack.
5. Shared cross-domain modules only when reused by at least two features (for example `Settings`).
6. Tests for service and view-model behavior.
7. Asset catalogs and design tokens.
8. Optional: if MVP includes on-device AI, scaffold AI contracts and fallback services (see `references/foundation_models.md`).
9. Optional: if MVP includes Liquid Glass, scaffold shared glass components plus iOS 26+ fallback styling (see `references/liquid-glass.md`).

## App Entry Template

```swift
import SwiftUI

@main
struct {AppName}App: App {
    init() {
        do {
            try DatabaseManager.makeShared()
        } catch {
            fatalError("Database initialization failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## Root Navigation Baseline

Prefer `TabView` at app root for top-level sections. Use `NavigationStack` inside features for hierarchical flows.
If Liquid Glass is enabled, prefer native search/tab behavior first (`.searchable`, optional search tab role + `tabViewSearchActivation(_:)` on iOS 26+) and keep search/filter state scoped to the active tab.
