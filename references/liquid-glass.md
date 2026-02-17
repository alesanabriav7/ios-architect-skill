# Liquid Glass (iOS 26+) Reference

Use this file when a feature or app should adopt Liquid Glass styling.

Scope:

- Native SwiftUI Liquid Glass adoption for iOS 26+
- Clean Architecture placement for glass styling decisions
- Availability and fallback rules for iOS < 26
- Native search and tab behavior for Liquid Glass apps

Note: API signatures can evolve. Validate final signatures in your toolchain (Xcode autocomplete + SDK interface) before shipping.

## Table of Contents

- [Adoption Defaults](#adoption-defaults)
- [Architecture Placement (Clean)](#architecture-placement-clean)
- [Availability and Fallback](#availability-and-fallback)
- [API Reference Map (Verified)](#api-reference-map-verified)
- [Native Liquid Glass by UI Part](#native-liquid-glass-by-ui-part)
- [Custom Surface Pattern (When Native Is Not Enough)](#custom-surface-pattern-when-native-is-not-enough)
- [Performance and Accessibility](#performance-and-accessibility)
- [Integration Checklist](#integration-checklist)
- [Sources](#sources)

## Adoption Defaults

- Adopt Liquid Glass only when product/design explicitly asks for it.
- Use native system controls and containers first; they inherit platform styling best.
- For search, default to native `.searchable(...)` rather than a custom glass search component.
- For tab-driven search, use native tab semantics (`role: .search`) and tab search activation on iOS 26+.
- Use custom glass surfaces only when system controls do not satisfy the design requirement.

## Architecture Placement (Clean)

Keep Liquid Glass decisions strictly in Presentation and shared UI modules.

- Domain: no Liquid Glass APIs, no visual styling concerns.
- Data: no Liquid Glass APIs, no UI rendering concerns.
- Presentation: Liquid Glass APIs are allowed.
- Design system package: host reusable glass primitives for shared surfaces/actions.

## Availability and Fallback

Two fallback modes are required:

- Native controls (`.searchable`, `TabView`, `Button`): no custom fallback branch needed for basic rendering; system adapts per OS.
- iOS 26-only APIs (`.glassEffect`, `.tabViewSearchActivation`, `.tabBarMinimizeBehavior`, `.buttonStyle(.glass...)`): always gate with `#available(iOS 26.0, *)` and provide deterministic fallback.

```swift
import SwiftUI

struct PrimaryActionButton: View {
    let title: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        if #available(iOS 26.0, *) {
            Button(title, action: action)
                .buttonStyle(.glassProminent)
        } else {
            Button(title, action: action)
                .buttonStyle(.borderedProminent)
        }
    }
}
```

## API Reference Map (Verified)

Use these native APIs as the default toolkit:

- `View.searchable(text:placement:prompt:)`
- `Tab(..., role: .search)`
- `View.tabViewSearchActivation(_:)`
- `View.tabBarMinimizeBehavior(_:)`
- `PrimitiveButtonStyle.glass` and `PrimitiveButtonStyle.glassProminent`
- `View.glassEffect(_:in:)`
- `GlassEffectContainer`
- `View.glassEffectID(_:in:)`
- `View.glassEffectTransition(_:)`

## Native Liquid Glass by UI Part

### 1) Search Fields

Default pattern:

- Use `.searchable(...)` in feature screens.
- Keep search query state in the owning feature view model.
- Do not introduce `AppGlassSearchField` (or similar) unless explicitly required.

```swift
import SwiftUI

struct TransactionsView: View {
    @State private var query = ""

    var body: some View {
        NavigationStack {
            List {
                Text("Transaction row")
            }
            .navigationTitle("Transactions")
        }
        .searchable(text: $query, prompt: "Search transactions")
    }
}
```

### 2) Tab Views

Default pattern:

- Keep `TabView` as root for top-level app navigation.
- Use a dedicated search tab only when product behavior expects that model.
- Scope search/filter state per tab.
- On iOS 26+, apply `tabViewSearchActivation(_:)` and optional `tabBarMinimizeBehavior(_:)`.

```swift
import SwiftUI

enum RootTab: Hashable {
    case home
    case search
}

struct RootView: View {
    @State private var selectedTab: RootTab = .home

    private var tabs: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: .home) {
                Text("Home")
            }

            Tab("Search", systemImage: "magnifyingglass", value: .search, role: .search) {
                Text("Search")
            }
        }
    }

    var body: some View {
        if #available(iOS 26.0, *) {
            tabs
                .tabViewSearchActivation(.searchTabSelection)
                .tabBarMinimizeBehavior(.onScrollDown)
        } else {
            tabs
        }
    }
}
```

### 3) Buttons and Primary Actions

Default pattern:

- Use `.buttonStyle(.glassProminent)` for primary actions on iOS 26+.
- Use `.buttonStyle(.glass)` for secondary actions on iOS 26+.
- Fallback to existing semantic button styles on earlier OS versions.

### 4) Custom Surfaces and Cards

Default pattern:

- Use custom `.glassEffect` only when native controls do not meet requirements.
- Group related surfaces with `GlassEffectContainer`.
- Keep layer count low in lists.

```swift
import SwiftUI

struct SummaryCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        if #available(iOS 26.0, *) {
            content
                .padding(16)
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
        } else {
            content
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                )
        }
    }
}
```

### 5) Continuity and Transitions

Default pattern:

- Use `glassEffectID(_:in:)` and `glassEffectTransition(_:)` for intentional glass continuity.
- Use these only where continuity communicates state changes clearly.

## Custom Surface Pattern (When Native Is Not Enough)

Only add a custom in-content search field or bespoke glass component when all conditions are true:

- Product/design explicitly requires behavior not achievable with native `.searchable`.
- The component is reused across at least two screens/features.
- Accessibility behavior (focus, labels, clear action, hit targets) is fully specified.
- iOS 26+ and fallback rendering behavior are both documented.

If any condition is missing, use native controls.

## Performance and Accessibility

- Keep hit targets at least `44x44` points.
- Keep glass layer count low in large scrolling surfaces.
- Do not use glass treatment alone to express state; include text/icons.
- Validate light/dark, Dynamic Type, and VoiceOver behavior.

## Integration Checklist

- [ ] Liquid Glass usage is explicitly requested by product/design.
- [ ] Native controls are used first (`.searchable`, `TabView`, system buttons).
- [ ] Search does not use a custom glass field unless explicitly justified.
- [ ] Tab flows preserve system behavior; search/filter state is scoped per tab.
- [ ] iOS 26-only APIs are gated with `#available(iOS 26.0, *)`.
- [ ] Fallback rendering is deterministic for iOS < 26.
- [ ] Glass APIs are limited to Presentation/shared UI modules.
- [ ] Visual regressions are covered by previews/snapshots.

## Sources

- [Adopting Liquid Glass (Technology Overview)](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)
- [Applying Liquid Glass to custom views (SwiftUI)](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)
- [TabView (SwiftUI)](https://developer.apple.com/documentation/swiftui/tabview)
- [searchable(text:placement:prompt:)](https://developer.apple.com/documentation/swiftui/view/searchable(text:placement:prompt:))
- [Meet Liquid Glass — WWDC25 Session 219](https://developer.apple.com/videos/play/wwdc2025/219/)
- [Adopt Liquid Glass — WWDC25 Session 320](https://developer.apple.com/videos/play/wwdc2025/320/)
- Local SDK verification: `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/SwiftUI.framework/Modules/SwiftUI.swiftmodule/arm64-apple-ios-simulator.swiftinterface`
- Local SDK verification: `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.2.sdk/System/Library/Frameworks/SwiftUICore.framework/Modules/SwiftUICore.swiftmodule/arm64-apple-ios-simulator.swiftinterface`
