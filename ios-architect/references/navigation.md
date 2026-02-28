# Navigation Architecture

Use this file when setting up app navigation, deep linking, or multi-column layouts.

## NavigationStack with Programmatic NavigationPath

Centralize navigation state in a single observable router. All push/pop operations go through this object.

```swift
import SwiftUI

@Observable
@MainActor
final class AppRouter {
    var path = NavigationPath()

    func navigate(to route: AppRoute) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
```

## Type-Safe Routing with Hashable Enums

Define all push destinations in a single `Hashable` enum. Add associated values for entity-level routes.

```swift
enum AppRoute: Hashable {
    case {feature}Detail({Entity})
    case {feature}Edit({Entity})
    case settings
}
```

Wire destinations with `navigationDestination(for:)` on the root stack:

```swift
NavigationStack(path: $router.path) {
    {Feature}ListView()
        .navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .{feature}Detail(let item):
                {Feature}DetailView(item: item)
            case .{feature}Edit(let item):
                {Entity}EditView(item: item)
            case .settings:
                SettingsView()
            }
        }
}
```

## NavigationSplitView for iPad/Mac Multi-Column

Use `NavigationSplitView` when the app requires a sidebar on iPad or Mac. It auto-collapses to stack navigation on iPhone -- no conditional logic needed.

```swift
struct AdaptiveRootView: View {
    @State private var selectedFeature: AppFeature? = .{feature}
    @State private var router = AppRouter()

    var body: some View {
        NavigationSplitView {
            List(AppFeature.allCases, selection: $selectedFeature) { feature in
                Label(feature.title, systemImage: feature.icon)
            }
            .navigationTitle("{AppName}")
        } detail: {
            NavigationStack(path: $router.path) {
                if let selectedFeature {
                    selectedFeature.rootView
                }
            }
        }
    }
}

enum AppFeature: String, CaseIterable, Identifiable {
    case {feature}
    case settings

    var id: String { rawValue }
    var title: String { /* ... */ }
    var icon: String { /* ... */ }

    @MainActor @ViewBuilder
    var rootView: some View {
        switch self {
        case .{feature}: {Feature}ListView()
        case .settings: SettingsView()
        }
    }
}
```

## Router Injection via Environment

Expose the router through `EnvironmentValues` so any child view can trigger navigation without passing closures.

```swift
extension EnvironmentValues {
    @Entry var router: AppRouter = AppRouter()
}

// In App root:
ContentView()
    .environment(\.router, router)

// In any child view:
@Environment(\.router) private var router
```

## TabView with Per-Tab Router

Use a `TabView` when the app has distinct top-level sections. Each tab gets its own `AppRouter` instance so push/pop state is independent across tabs.

```swift
enum AppTab: String, CaseIterable, Identifiable {
    case {feature}
    case search
    case settings

    var id: String { rawValue }
    var title: String { /* ... */ }
    var icon: String { /* ... */ }
}

@Observable
@MainActor
final class TabRouter {
    var selectedTab: AppTab = .{feature}
    private(set) var routers: [AppTab: AppRouter] = [:]

    init() {
        for tab in AppTab.allCases {
            routers[tab] = AppRouter()
        }
    }

    func router(for tab: AppTab) -> AppRouter {
        routers[tab]!
    }
}
```

Wire the root `TabView` so each tab owns a `NavigationStack` bound to its dedicated router:

```swift
struct TabRootView: View {
    @State private var tabRouter = TabRouter()

    var body: some View {
        TabView(selection: $tabRouter.selectedTab) {
            ForEach(AppTab.allCases) { tab in
                let router = tabRouter.router(for: tab)
                NavigationStack(path: Binding(
                    get: { router.path },
                    set: { router.path = $0 }
                )) {
                    tab.rootView
                        .navigationDestination(for: AppRoute.self) { route in
                            route.destinationView
                        }
                }
                .tabItem {
                    Label(tab.title, systemImage: tab.icon)
                }
                .tag(tab)
                .environment(\.router, router)
            }
        }
    }
}

extension AppTab {
    @MainActor @ViewBuilder
    var rootView: some View {
        switch self {
        case .{feature}: {Feature}ListView()
        case .search: SearchView()
        case .settings: SettingsView()
        }
    }
}
```

## Modal and Sheet Presentation

Model sheets as a dedicated enum on `AppRouter`. Use an optional `@Published` property so SwiftUI can drive `.sheet(item:)` automatically.

```swift
enum AppSheet: Identifiable {
    case {feature}Create
    case {feature}Edit({Entity})

    var id: String {
        switch self {
        case .{feature}Create:
            return "{feature}Create"
        case .{feature}Edit(let item):
            return "{feature}Edit-\(item.id)"
        }
    }
}
```

Extend `AppRouter` with sheet state and presentation helpers:

```swift
extension AppRouter {
    var activeSheet: AppSheet? {
        get { _activeSheet }
        set { _activeSheet = newValue }
    }

    func present(sheet: AppSheet) {
        _activeSheet = sheet
    }

    func dismissSheet() {
        _activeSheet = nil
    }
}

// Add stored property in AppRouter class body:
// var _activeSheet: AppSheet?
```

Attach `.sheet(item:)` to the root view so modals are managed in one place:

```swift
NavigationStack(path: $router.path) {
    {Feature}ListView()
        .navigationDestination(for: AppRoute.self) { route in
            route.destinationView
        }
}
.sheet(item: $router.activeSheet) { sheet in
    NavigationStack {
        switch sheet {
        case .{feature}Create:
            {Feature}CreateView()
        case .{feature}Edit(let item):
            {Feature}EditView(item: item)
        }
    }
}
```

Trigger presentation from any child view through the environment-injected router:

```swift
@Environment(\.router) private var router

Button("New {Feature}") {
    router.present(sheet: .{feature}Create)
}
```

## Deep Linking: URL to Route Parsing

Map incoming URLs to routes. Handle async entity resolution in the `onOpenURL` handler, not inside the initializer.

```swift
extension AppRoute {
    init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let host = components.host else { return nil }

        switch host {
        case "{feature}":
            guard let id = components.queryItems?.first(where: { $0.name == "id" })?.value else {
                return nil
            }
            // Resolve entity from ID -- caller must handle async lookup
            return nil // Placeholder: resolve in onOpenURL handler
        case "settings":
            self = .settings
        default:
            return nil
        }
    }
}

// In App:
.onOpenURL { url in
    if let route = AppRoute(url: url) {
        router.navigate(to: route)
    }
}
```

## Adaptive Layout Guidance

- Use `NavigationSplitView` when iPad/Mac multi-column is required.
- Use `NavigationStack` when the app is iPhone-only or single-column.
- Use `@Environment(\.horizontalSizeClass)` to adjust content density (compact vs regular).
- Keep navigation state in `AppRouter` so it survives across layout changes.
