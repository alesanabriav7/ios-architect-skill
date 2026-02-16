# Design System and UI Rules

Use this file when creating shared UI primitives or feature UI components.

## Core Rules

- Use semantic tokens (`Color.appBackground`, `Color.textPrimary`, etc.).
- Provide light and dark variants in asset catalogs.
- Prefer system typography unless a product-specific font is required.
- Keep components reusable and data-driven (no view model coupling).
- Bake in accessibility (Dynamic Type, contrast, VoiceOver labels).

## Semantic Color Template

```swift
import SwiftUI

public extension Color {
    static let appBackground = Color("appBackground")
    static let appSurface = Color("appSurface")
    static let sheetBackground = Color("sheetBackground")
    static let textPrimary = Color("textPrimary")
    static let textSecondary = Color("textSecondary")
    static let textMuted = Color("textMuted")
    static let accentSuccess = Color("accentSuccess")
    static let accentError = Color("accentError")
    static let accentWarning = Color("accentWarning")
}
```

## Typography Template

```swift
import SwiftUI

public extension Font {
    static func dataDisplay(size: CGFloat) -> Font {
        .custom("JetBrainsMono-Bold", size: size)
    }

    static func dataBody(size: CGFloat) -> Font {
        .custom("JetBrainsMono-Medium", size: size)
    }

    static let uiLabel = Font.system(size: 14, weight: .medium)
    static let uiBody = Font.system(size: 16, weight: .regular)
    static let uiCaption = Font.system(size: 12, weight: .regular)
    static let uiButton = Font.system(size: 16, weight: .semibold)
    static let uiTitle = Font.system(size: 20, weight: .bold)
}
```

If no custom monospace font is bundled, use `.system(.body, design: .monospaced)`.

## Component Baselines

Required shared components (as needed per app):

- `{Prefix}Card`
- `{Prefix}GlassFAB`
- `{Prefix}TextField`
- `{Prefix}AmountInput`
- `{Prefix}SectionHeader`
- `{Prefix}ProgressBar`

### Card Template

```swift
import SwiftUI

public struct {Prefix}Card<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(16)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
    }
}
```

### FAB Template

```swift
import SwiftUI

public struct {Prefix}GlassFAB: View {
    let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(Color.textPrimary)
                .frame(width: 56, height: 56)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
        }
        .accessibilityLabel("Add")
    }
}
```

## Navigation Defaults

- Root: `TabView` for top-level sections.
- Feature internals: `NavigationStack` for hierarchy.
- Create/edit flows: sheets with enum routing.
- Horizontal period paging: `TabView` with `.page(indexDisplayMode: .never)` when needed.

## Visual Conventions

- Corners: 12 for compact surfaces, 16 for cards.
- Spacing: 16 horizontal, 12 between repeated cards/rows.
- Sheets: `.presentationDetents([.medium, .large])` + visible drag indicator.
- Motion: minimal and purposeful (`.default` or short `.easeInOut`).
