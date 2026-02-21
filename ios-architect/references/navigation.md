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
