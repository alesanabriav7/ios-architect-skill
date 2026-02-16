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
│   │   ├── Models/
│   │   ├── Data/
│   │   └── Services/
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

## Scaffolding Order

1. Tuist files (`Project.swift`, `Tuist.swift`) with bundle ID and default iOS 18+ target.
2. Local packages (`{Prefix}Database`, `{Prefix}DesignSystem`, optional shared packages).
3. App entry (`{AppName}App.swift`) and root navigation (`ContentView.swift`).
4. Shared models/services required by first feature.
5. First feature Domain/Data/Presentation stack.
6. Tests for service and view-model behavior.
7. Asset catalogs and design tokens.

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
