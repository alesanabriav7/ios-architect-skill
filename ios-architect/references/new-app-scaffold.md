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
│   ├── Resources/
│   │   └── Localizable.xcstrings
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
8. Optional: if MVP includes on-device AI, scaffold AI contracts and fallback services (see `references/foundation-models.md`).
9. Optional: if MVP includes Liquid Glass, scaffold shared glass components plus iOS 26+ fallback styling (see `references/liquid-glass.md`).

## .gitignore

```gitignore
# Xcode
DerivedData/
xcuserdata/
*.xcworkspace

# Tuist
Tuist/.build/

# Swift Package Manager
.build/
.swiftpm/

# macOS
.DS_Store
```

## Project.swift Template

```swift
import ProjectDescription

let project = Project(
    name: "{AppName}",
    settings: .settings(
        base: ["SWIFT_VERSION": "6.0"],
        defaultSettings: .recommended
    ),
    targets: [
        .target(
            name: "{AppName}",
            destinations: .iOS,
            product: .app,
            bundleId: "com.{organization}.{appname}",
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": .dictionary([:]),
            ]),
            deploymentTargets: .iOS("18.0"),
            sources: ["{AppName}/**"],
            resources: ["{AppName}/Resources/**", "{AppName}/Assets.xcassets/**"],
            dependencies: [
                .target(name: "{Prefix}DesignSystem"),
                .target(name: "{Prefix}SharedComponents"),
                // Include database dependency only when using local persistence
                // .target(name: "{Prefix}Database"),
            ]
        ),
        .target(
            name: "{AppName}Tests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.{organization}.{appname}.tests",
            deploymentTargets: .iOS("18.0"),
            sources: ["{AppName}Tests/**"],
            dependencies: [
                .target(name: "{AppName}"),
            ]
        ),
    ]
)
```

### Local Framework Targets

Add these targets to the `targets` array alongside the app and test targets:

```swift
// Design system — colors, typography, spacing tokens, reusable UI components
.target(
    name: "{Prefix}DesignSystem",
    destinations: .iOS,
    product: .framework,
    bundleId: "com.{organization}.{appname}.designsystem",
    deploymentTargets: .iOS("18.0"),
    sources: ["{Prefix}DesignSystem/**"],
    resources: ["{Prefix}DesignSystem/Resources/**"]
),

// Shared UI components — composed from DesignSystem tokens
.target(
    name: "{Prefix}SharedComponents",
    destinations: .iOS,
    product: .framework,
    bundleId: "com.{organization}.{appname}.sharedcomponents",
    deploymentTargets: .iOS("18.0"),
    sources: ["{Prefix}SharedComponents/**"],
    dependencies: [
        .target(name: "{Prefix}DesignSystem"),
    ]
),

// Database — include only when using local persistence (GRDB)
.target(
    name: "{Prefix}Database",
    destinations: .iOS,
    product: .framework,
    bundleId: "com.{organization}.{appname}.database",
    deploymentTargets: .iOS("18.0"),
    sources: ["{Prefix}Database/**"],
    dependencies: [
        .external(name: "GRDB"),
    ]
),
```

Info.plist rules for SwiftUI apps:

- **Always include** `"UILaunchScreen": .dictionary([:])` — modern replacement for `LaunchScreen.storyboard`, required for SwiftUI-only apps.
- **Never include** `UIApplicationSceneManifest` or `UISceneConfigurations` — those are legacy UIKit scene patterns. SwiftUI handles scene management automatically via `@main` + `App` protocol.

Conditional dependencies — uncomment or add based on the data source mode chosen for the project:

| Data Source Mode | Dependency |
|---|---|
| Local (GRDB/SwiftData) | `.target(name: "{Prefix}Database")` |
| Remote only | `.external(name: "SomeNetworkLib")` |
| Remote + cache (SWR) | `.external(name: "SomeNetworkLib")` -- no DB needed |
| Hybrid (local + sync) | Both local DB and network |
| Notifications | `.target(name: "{Prefix}Notifications")` |

## Tuist.swift Template

```swift
import ProjectDescription

let tuist = Tuist(
    compatibleXcodeVersions: .upToNextMajor("16.0"),
    swiftVersion: "6.0"
)
```

## Tuist/Package.swift Template

Declare external dependencies here. Tuist resolves them via SPM under the hood.

```swift
// swift-tools-version: 6.0
@preconcurrency import PackageDescription

#if TUIST
import struct ProjectDescription.PackageSettings

let packageSettings = PackageSettings(
    productTypes: [
        "GRDB": .framework,
    ]
)
#endif

let package = Package(
    name: "{AppName}Dependencies",
    dependencies: [
        // Include only when using local persistence
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.0.0"),
    ]
)
```

After creating or updating this file, run `tuist install` to fetch dependencies.

## App Entry Template

### With Local Database

Use when the project uses GRDB for local persistence:

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

### Without Local Database

Use for API-only or in-memory data source modes:

```swift
import SwiftUI

@main
struct {AppName}App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## Root Navigation Baseline

Prefer `TabView` at app root for top-level sections. Use `NavigationStack` inside features for hierarchical flows.
If iPad/multi-column navigation is required, use `NavigationSplitView` at the root — see `references/navigation.md` for patterns and templates. `NavigationSplitView` auto-collapses to stack navigation on iPhone.
If Liquid Glass is enabled, prefer native search/tab behavior first (`.searchable`, optional search tab role + `tabViewSearchActivation(_:)` on iOS 26+) and keep search/filter state scoped to the active tab.

### ContentView.swift Template

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("{Feature}", systemImage: "list.bullet") {
                {Feature}View()
            }
        }
    }
}
```

Add additional `Tab` entries as features are added. Each tab wraps a feature's root view with its own `NavigationStack` managed internally.

## iPad and Multi-Platform

When targeting iPad or multiple Apple platforms:

- Use `NavigationSplitView` for multi-column layouts on iPad/Mac (see `references/navigation.md`).
- Use `#if os(iOS)` / `#if os(macOS)` for platform-specific code paths.
- Use `@Environment(\.horizontalSizeClass)` to adjust content density between compact (iPhone) and regular (iPad) size classes:

```swift
@Environment(\.horizontalSizeClass) private var sizeClass

var columns: [GridItem] {
    sizeClass == .compact
        ? [GridItem(.flexible())]
        : [GridItem(.flexible()), GridItem(.flexible())]
}
```

- Test with both compact and regular size classes in previews.
- Keep navigation state in a shared `AppRouter` so it survives layout changes between split and stack modes.

## Asset Catalog

- **AppIcon**: Supply a single 1024×1024 PNG in `Assets.xcassets/AppIcon.appiconset`. iOS 18+ generates all required sizes automatically. Use the Xcode asset editor for validation.
- **Semantic colors**: Define in `{Prefix}DesignSystem` package resources, not in the app's `Assets.xcassets`. This keeps color tokens co-located with the design system and importable by all modules.
- **No boilerplate needed**: Xcode and Tuist auto-generate `Contents.json` files. Do not manually create or edit them.
