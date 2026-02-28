# Navigation Architecture

Use this file when setting up app navigation, deep linking, or multi-column layouts.

## NavigationStack with Typed Route Stack

Centralize navigation state in a single observable router using a typed `[AppRoute]` array instead of the type-erased `NavigationPath`. This enables stack introspection for deep links, screenshot automation, and test assertions. All push/pop operations go through this object.

```swift
import SwiftUI

@Observable
@MainActor
final class AppRouter {
    var stack: [AppRoute] = []
    var activeSheet: AppSheet?
    var activeFullScreenCover: AppSheet?
    var activeConfirmation: ConfirmationState?

    func navigate(to route: AppRoute) {
        stack.append(route)
    }

    func pop() {
        guard !stack.isEmpty else { return }
        stack.removeLast()
    }

    func popToRoot() {
        stack.removeAll()
    }

    /// Replace the entire stack atomically. Used by deep links and the screenshot harness
    /// to jump to an arbitrary screen without animating through intermediate states.
    func resetAndNavigate(to routes: [AppRoute]) {
        stack = routes
    }

    func present(sheet: AppSheet) {
        activeSheet = sheet
    }

    func present(fullScreenCover: AppSheet) {
        activeFullScreenCover = fullScreenCover
    }

    func dismissSheet() {
        activeSheet = nil
    }

    func dismissFullScreenCover() {
        activeFullScreenCover = nil
    }

    func presentConfirmation(_ state: ConfirmationState) {
        activeConfirmation = state
    }

    func dismissConfirmation() {
        activeConfirmation = nil
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
NavigationStack(path: $router.stack) {
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
            NavigationStack(path: $router.stack) {
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
        guard let router = routers[tab] else {
            fatalError("Router not found for tab \(tab). This is a programmer error.")
        }
        return router
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
                    get: { router.stack },
                    set: { router.stack = $0 }
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

Model sheets as a dedicated enum on `AppRouter`. Use an optional property so SwiftUI can drive `.sheet(item:)` automatically.

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

Attach `.sheet(item:)` to the root view so modals are managed in one place:

```swift
NavigationStack(path: $router.stack) {
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

## Overlay Modeling: Full-Screen Covers and Confirmations

`AppSheet` is reused for both sheets and full-screen covers. SwiftUI presents at most one sheet **or** one full-screen cover at a time per view hierarchy level — never both simultaneously.

### Full-Screen Cover Wiring

```swift
NavigationStack(path: $router.stack) {
    tab.rootView
        .navigationDestination(for: AppRoute.self) { route in
            route.destinationView
        }
}
.sheet(item: $router.activeSheet) { sheet in
    sheet.content
}
.fullScreenCover(item: $router.activeFullScreenCover) { cover in
    cover.content
}
```

### Confirmation Dialog State

Model confirmation dialogs as a dedicated struct so the router can drive them declaratively:

```swift
struct ConfirmationState: Identifiable {
    let id = UUID().uuidString
    let title: String
    let message: String
    let destructiveLabel: String
    let onConfirm: @MainActor () -> Void

    init(
        title: String,
        message: String,
        destructiveLabel: String = "Delete",
        onConfirm: @escaping @MainActor () -> Void
    ) {
        self.title = title
        self.message = message
        self.destructiveLabel = destructiveLabel
        self.onConfirm = onConfirm
    }
}
```

Attach to the same root view:

```swift
.confirmationDialog(
    router.activeConfirmation?.title ?? "",
    isPresented: Binding(
        get: { router.activeConfirmation != nil },
        set: { if !$0 { router.dismissConfirmation() } }
    ),
    titleVisibility: .visible
) {
    if let confirmation = router.activeConfirmation {
        Button(confirmation.destructiveLabel, role: .destructive) {
            confirmation.onConfirm()
            router.dismissConfirmation()
        }
        Button("Cancel", role: .cancel) {
            router.dismissConfirmation()
        }
    }
} message: {
    Text(router.activeConfirmation?.message ?? "")
}
```

Trigger from any child view:

```swift
router.presentConfirmation(ConfirmationState(
    title: "Delete {Entity}?",
    message: "This action cannot be undone.",
    destructiveLabel: "Delete"
) {
    Task { await viewModel.delete(item) }
})
```

## Screen Manifest for Automation

Every distinct screen is registered in a parameterless `CaseIterable` enum. This enables the screenshot harness (see `testing-concurrency-di.md`) to iterate all screens without knowing their construction details.

```swift
enum AppScreen: String, CaseIterable, Identifiable {
    case {feature}List
    case {feature}Detail
    case {feature}CreateSheet
    case {feature}EditSheet
    case settings
    // Add one case per distinct screen in the app

    var id: String { rawValue }
}
```

Each case maps to a `ScreenPath` that describes the full navigation state needed to reach it — tab, stack routes, and optional overlay. Entity-dependent screens use `.fixture` data from `PreviewFixture` (see `feature-scaffold.md`).

```swift
struct ScreenPath {
    let tab: AppTab?
    let routes: [AppRoute]
    let sheet: AppSheet?
    let fullScreenCover: AppSheet?

    init(
        tab: AppTab? = nil,
        routes: [AppRoute] = [],
        sheet: AppSheet? = nil,
        fullScreenCover: AppSheet? = nil
    ) {
        self.tab = tab
        self.routes = routes
        self.sheet = sheet
        self.fullScreenCover = fullScreenCover
    }
}

extension AppScreen {
    var tab: AppTab? {
        switch self {
        case .{feature}List, .{feature}Detail,
             .{feature}CreateSheet, .{feature}EditSheet:
            return .{feature}
        case .settings:
            return .settings
        }
    }

    var navigationPath: ScreenPath {
        switch self {
        case .{feature}List:
            return ScreenPath(tab: .{feature})
        case .{feature}Detail:
            return ScreenPath(tab: .{feature}, routes: [.{feature}Detail(.fixture)])
        case .{feature}CreateSheet:
            return ScreenPath(tab: .{feature}, sheet: .{feature}Create)
        case .{feature}EditSheet:
            return ScreenPath(tab: .{feature}, sheet: .{feature}Edit(.fixture))
        case .settings:
            return ScreenPath(tab: .settings)
        }
    }
}
```

### Navigating to a Screen Programmatically

`TabRouter` exposes a single method that drives tab switch + stack reset + overlay presentation in one call:

```swift
extension TabRouter {
    func navigate(to screen: AppScreen) {
        let path = screen.navigationPath

        // Switch tab if specified
        if let tab = path.tab {
            selectedTab = tab
        }

        // Reset stack to the target routes
        let targetRouter = router(for: selectedTab)
        targetRouter.resetAndNavigate(to: path.routes)

        // Present overlay if needed
        targetRouter.activeSheet = path.sheet
        targetRouter.activeFullScreenCover = path.fullScreenCover
    }
}
```

## Deep Linking

Deep links resolve a URL into a fully typed navigation destination, fetch any required entities asynchronously, then hand off to `TabRouter` for atomic tab switch + stack reset + overlay presentation.

### Destination Model

The resolved output of a deep link — decoupled from the raw URL:

```swift
enum DeepLinkDestination {
    case route(tab: AppTab, routes: [AppRoute])
    case sheet(tab: AppTab, sheet: AppSheet)
}
```

### Resolver Protocol

```swift
import Foundation

protocol DeepLinkResolverProtocol: Sendable {
    func resolve(_ url: URL) async throws -> DeepLinkDestination?
}
```

### Resolver Implementation

The resolver parses the URL, performs async entity fetches when needed, and returns a typed destination. Supports both custom URL schemes (`{appscheme}://`) and universal links (`https://{domain}/`).

```swift
import Foundation
import os

final class DeepLinkResolver: DeepLinkResolverProtocol, Sendable {
    private let repository: {Entity}RepositoryProtocol

    init(repository: {Entity}RepositoryProtocol) {
        self.repository = repository
    }

    func resolve(_ url: URL) async throws -> DeepLinkDestination? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            Logger.navigation.warning("Malformed deep link URL: \(url)")
            return nil
        }

        // Normalize: custom scheme uses host, universal links use first path component
        let segment = components.host ?? components.path.split(separator: "/").first.map(String.init)
        let queryItems = components.queryItems ?? []

        switch segment {
        case "{feature}":
            guard let id = queryItems.first(where: { $0.name == "id" })?.value else {
                return .route(tab: .{feature}, routes: [])
            }
            guard let entity = try await repository.fetchByID(id) else {
                Logger.navigation.warning("Deep link entity not found: \(id)")
                return .route(tab: .{feature}, routes: [])
            }
            return .route(tab: .{feature}, routes: [.{feature}Detail(entity)])

        case "{feature}-new":
            return .sheet(tab: .{feature}, sheet: .{feature}Create)

        case "settings":
            return .route(tab: .settings, routes: [])

        default:
            Logger.navigation.info("Unrecognized deep link segment: \(segment ?? "nil")")
            return nil
        }
    }
}

extension Logger {
    static let navigation = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "{AppName}",
        category: "Navigation"
    )
}
```

### TabRouter Deep Link Handling

```swift
extension TabRouter {
    func handle(destination: DeepLinkDestination) {
        switch destination {
        case .route(let tab, let routes):
            selectedTab = tab
            let targetRouter = router(for: tab)
            targetRouter.dismissSheet()
            targetRouter.dismissFullScreenCover()
            targetRouter.resetAndNavigate(to: routes)

        case .sheet(let tab, let sheet):
            selectedTab = tab
            let targetRouter = router(for: tab)
            targetRouter.resetAndNavigate(to: [])
            targetRouter.present(sheet: sheet)
        }
    }
}
```

### App-Level Wiring

Handle both custom URL schemes and universal links at the app root:

```swift
@main
struct {AppName}App: App {
    @State private var tabRouter = TabRouter()
    private let deepLinkResolver = DeepLinkResolver(
        repository: {Entity}Repository()
    )

    var body: some Scene {
        WindowGroup {
            TabRootView(tabRouter: tabRouter)
                .onOpenURL { url in
                    Task {
                        do {
                            guard let destination = try await deepLinkResolver.resolve(url) else { return }
                            tabRouter.handle(destination: destination)
                        } catch {
                            Logger.navigation.error("Deep link resolution failed: \(error)")
                        }
                    }
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    guard let url = activity.webpageURL else { return }
                    Task {
                        do {
                            guard let destination = try await deepLinkResolver.resolve(url) else { return }
                            tabRouter.handle(destination: destination)
                        } catch {
                            Logger.navigation.error("Universal link resolution failed: \(error)")
                        }
                    }
                }
        }
    }
}
```

## Adaptive Layout Guidance

- Use `NavigationSplitView` when iPad/Mac multi-column is required.
- Use `NavigationStack` when the app is iPhone-only or single-column.
- Use `@Environment(\.horizontalSizeClass)` to adjust content density (compact vs regular).
- Keep navigation state in `AppRouter` so it survives across layout changes.
