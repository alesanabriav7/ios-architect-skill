# Design System and UI Rules

Use this file when creating shared UI primitives or feature UI components.

## Core Rules

- Use semantic tokens for color, typography, spacing, radius, elevation, and motion.
- Never hard-code visual constants inside feature views when a token exists.
- Keep components reusable and data-driven (no view-model coupling).
- Bake in accessibility by default: Dynamic Type, contrast, VoiceOver labels, and minimum hit size.
- Prefer modern SwiftUI APIs (`foregroundStyle`, `clipShape(.rect(...))`, `Button` for tap actions).
- If Liquid Glass is required, also apply `references/liquid-glass.md` for API, availability, and fallback rules.

## Token System

### Semantic Color Template

```swift
import SwiftUI

public extension Color {
    static let appBackground = Color("appBackground")
    static let appSurface = Color("appSurface")
    static let appSurfaceElevated = Color("appSurfaceElevated")
    static let sheetBackground = Color("sheetBackground")

    static let textPrimary = Color("textPrimary")
    static let textSecondary = Color("textSecondary")
    static let textMuted = Color("textMuted")

    static let accentPrimary = Color("accentPrimary")
    static let accentSuccess = Color("accentSuccess")
    static let accentError = Color("accentError")
    static let accentWarning = Color("accentWarning")

    static let strokeSubtle = Color("strokeSubtle")
    static let focusRing = Color("focusRing")
}
```

Provide light and dark variants in asset catalogs for each token.

### Typography Hierarchy

Use a strict role-based scale so hierarchy is predictable and consistent:

| Role | Token | Primary Usage |
|------|-------|----------------|
| Display | `dsDisplay` | KPI hero numbers and splash titles |
| Screen title | `dsTitle` | Navigation titles and card headlines |
| Section title | `dsHeadline` | Grouped list section headings |
| Body primary | `dsBody` | Default reading text |
| Body secondary | `dsBodySecondary` | Supporting descriptions |
| Label | `dsLabel` | Input labels and row metadata |
| Caption | `dsCaption` | Hints and tertiary metadata |
| Numeric emphasis | `dsNumericEmphasis` | Amounts, totals, balances |
| Numeric body | `dsNumericBody` | Inline numeric values |

```swift
import SwiftUI

public extension Font {
    static let dsDisplay = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let dsTitle = Font.system(.title3, design: .default).weight(.semibold)
    static let dsHeadline = Font.system(.headline, design: .default).weight(.semibold)
    static let dsBody = Font.system(.body, design: .default)
    static let dsBodySecondary = Font.system(.callout, design: .default)
    static let dsLabel = Font.system(.subheadline, design: .default).weight(.medium)
    static let dsCaption = Font.system(.caption, design: .default)

    static let dsNumericEmphasis = Font.system(.title3, design: .monospaced).weight(.semibold)
    static let dsNumericBody = Font.system(.body, design: .monospaced).weight(.medium)
}
```

If product fonts are required, always use `.custom(_, size: _, relativeTo: _)` so Dynamic Type scaling is preserved.

### Spacing, Radius, and Motion Template

```swift
import SwiftUI

public enum Space {
    public static let xs: CGFloat = 4
    public static let s: CGFloat = 8
    public static let m: CGFloat = 12
    public static let l: CGFloat = 16
    public static let xl: CGFloat = 24
}

public enum Radius {
    public static let s: CGFloat = 10
    public static let m: CGFloat = 12
    public static let l: CGFloat = 16
    public static let xl: CGFloat = 20
}

public enum Motion {
    public static let quick = Animation.easeInOut(duration: 0.18)
    public static let standard = Animation.easeInOut(duration: 0.24)

    /// Applies the given animation only when Reduce Motion is off.
    /// All animation call sites must use this helper instead of
    /// `withAnimation` directly to honor the user's motion preference.
    public static func animate<Result>(
        _ animation: Animation = .standard,
        _ body: () throws -> Result
    ) rethrows -> Result {
        if UIAccessibility.isReduceMotionEnabled {
            return try body()
        } else {
            return try withAnimation(animation, body)
        }
    }
}
```

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
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(Space.l)
            .background(Color.appSurface)
            .clipShape(.rect(cornerRadius: Radius.l))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.l)
                    .stroke(Color.strokeSubtle, lineWidth: 1)
            )
    }
}
```

### FAB Template

```swift
import SwiftUI

public struct {Prefix}GlassFAB: View {
    private let symbol: String
    private let label: LocalizedStringKey
    private let action: () -> Void

    public init(
        symbol: String = "plus",
        label: LocalizedStringKey = "Add",
        action: @escaping () -> Void
    ) {
        self.symbol = symbol
        self.label = label
        self.action = action
    }

    public var body: some View {
        if #available(iOS 26.0, *) {
            Button(action: action) {
                Image(systemName: symbol)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                    .frame(width: 56, height: 56)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Circle())
            .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
        } else {
            Button(action: action) {
                Image(systemName: symbol)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                    .frame(width: 56, height: 56)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(Color.strokeSubtle, lineWidth: 1))
                    .shadow(color: .black.opacity(0.22), radius: 8, y: 4)
            }
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
        }
    }
}
```

### Text Field Template

```swift
import SwiftUI

public struct {Prefix}TextField: View {
    private let title: LocalizedStringKey
    private let prompt: LocalizedStringKey
    @Binding private var text: String

    public init(
        _ title: LocalizedStringKey,
        prompt: LocalizedStringKey = "",
        text: Binding<String>
    ) {
        self.title = title
        self.prompt = prompt
        self._text = text
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            Text(title)
                .font(.dsLabel)
                .foregroundStyle(Color.textSecondary)

            TextField("", text: $text, prompt: Text(prompt))
                .font(.dsBody)
                .padding(.horizontal, Space.l)
                .padding(.vertical, Space.m)
                .background(Color.appSurfaceElevated)
                .clipShape(.rect(cornerRadius: Radius.m))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.m)
                        .stroke(Color.strokeSubtle, lineWidth: 1)
                )
                .accessibilityLabel(title)
        }
    }
}
```

### Amount Input Template

```swift
import SwiftUI

public struct {Prefix}AmountInput: View {
    private let title: LocalizedStringKey
    @Binding private var value: String

    public init(_ title: LocalizedStringKey, value: Binding<String>) {
        self.title = title
        self._value = value
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            Text(title)
                .font(.dsLabel)
                .foregroundStyle(Color.textSecondary)

            TextField("0.00", text: $value)
                .keyboardType(.decimalPad)
                .font(.dsNumericEmphasis)
                .padding(.horizontal, Space.l)
                .padding(.vertical, Space.m)
                .background(Color.appSurfaceElevated)
                .clipShape(.rect(cornerRadius: Radius.m))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.m)
                        .stroke(Color.strokeSubtle, lineWidth: 1)
                )
        }
        .accessibilityHint("Enter amount in your local currency format")
    }
}
```

### Section Header Template

```swift
import SwiftUI

public struct {Prefix}SectionHeader: View {
    private let title: LocalizedStringKey
    private let actionTitle: LocalizedStringKey?
    private let action: (() -> Void)?

    public init(
        _ title: LocalizedStringKey,
        actionTitle: LocalizedStringKey? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.dsHeadline)
                .foregroundStyle(Color.textPrimary)

            Spacer()

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.dsLabel)
                    .foregroundStyle(Color.accentPrimary)
            }
        }
    }
}
```

### Progress Bar Template

```swift
import SwiftUI

public struct {Prefix}ProgressBar: View {
    private let progress: Double

    public init(progress: Double) {
        self.progress = progress
    }

    public var body: some View {
        let clamped = progress.clamped(to: 0...1)
        Capsule()
            .fill(Color.appSurfaceElevated)
            .frame(height: 8)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(Color.accentPrimary)
                    .frame(maxWidth: .infinity, maxHeight: 8, alignment: .leading)
                    .scaleEffect(x: clamped, y: 1, anchor: .leading)
            }
            .accessibilityLabel("Progress")
            .accessibilityValue(Text("\(Int(clamped * 100)) percent"))
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
```

## Localization

- All user-facing strings must use `String(localized:)` (in Swift code) or `LocalizedStringKey` (in SwiftUI views). Never use raw string literals for text displayed to users.
- Use String Catalogs (`.xcstrings`) as the default localization format for new projects. Xcode auto-extracts localizable strings during builds.
- Never concatenate strings to form sentences — use string interpolation with localized keys to preserve word order across languages:

```swift
// Correct
String(localized: "\(count) items remaining")

// Wrong — breaks in RTL and reordering languages
String(localized: "Items") + ": " + "\(count)"
```

- Pluralization: use String Catalogs' built-in plural rules (`.stringsdict` replacement). Define `zero`, `one`, `other` variants directly in the `.xcstrings` file.
- RTL layout: test all screens with right-to-left languages (Arabic, Hebrew). Use `.leading`/`.trailing` instead of `.left`/`.right` for alignment. SwiftUI handles mirroring automatically when using standard layout APIs.
- Format dates, numbers, and currencies with `FormatStyle` APIs — they respect the user's locale automatically:

```swift
Text(item.createdAt, format: .dateTime.month().day())
Text(amount, format: .currency(code: currencyCode))
```

## Accessibility and Content Rules

- Tap targets: minimum 44x44 points.
- Text truncation: define `lineLimit` and priority for critical fields.
- Decorative images/icons must be hidden from VoiceOver.
- All controls need explicit accessibility labels and hints when intent is not obvious.
- Respect Dynamic Type in all reusable components.

## Navigation Defaults

- Root: `TabView` for top-level sections.
- Feature internals: `NavigationStack` for hierarchy.
- If Liquid Glass is enabled, keep native search and tab affordances first: `.searchable(...)`, optional `Tab(..., role: .search)`, and `tabViewSearchActivation(_:)` on iOS 26+.
- Do not introduce a shared custom glass search component unless product requirements explicitly need an in-content search field that native `.searchable` cannot satisfy.
- Create/edit flows: sheets with enum routing and `.sheet(item:)`.
- Horizontal period paging: `TabView` with `.page(indexDisplayMode: .never)` when needed.

## Visual Conventions

- Use tokenized values: `Space.l` horizontal padding, `Space.m` row spacing.
- Corners: `Radius.m` for compact controls, `Radius.l` for cards/surfaces.
- Sheets: `.presentationDetents([.medium, .large])` + `.presentationDragIndicator(.visible)`.
- Motion: use `Motion.quick` for micro transitions and `Motion.standard` for list/sheet state changes. Always apply animations through `Motion.animate(_:_:)` instead of calling `withAnimation` directly — this ensures Reduce Motion is respected.

## Quality Gates

- Add `#Preview` for each shared component (light, dark, and large text size variants).
- Add snapshot tests for key reusable components where visual regressions are expensive.
- Add one accessibility-focused UI test for each critical flow.
