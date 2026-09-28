# UI: design system, Liquid Glass, accessibility, localization

Reference code: `templates/DesignSystem/Sources/`, `templates/App/Sources/Features/Notes/Presentation/`. For detailed SwiftUI API questions, also use `swiftui-expert-skill` if it's available.

## Design system

- Tokens (spacing, radius, semantic colors) live in the design-system module. Feature views use tokens and system text styles, not literal values.
- Asset colors in a framework must name the framework bundle (`Color("Name", bundle: .designSystem)`).
  In a Swift package use `Bundle.module`. Without the bundle the color renders clear, and nothing warns you.
- A component moves to the design system only when two features use it. Components take data and closures, never view models.
- Add a `#Preview` for each shared component, including dark mode and a large Dynamic Type size.

## Liquid Glass (iOS 26+)

- Standard bars, toolbars, tab bars, sheets, and controls get glass from the system. Don't restyle them.
- For custom controls, use `.buttonStyle(.glass)` or `.buttonStyle(.glassProminent)`. For custom floating surfaces, use `.glassEffect(_:in:)`,
  and group nearby glass surfaces with `GlassEffectContainer`.
- Put glass on the navigation and controls layer, not on content or list rows. Don't stack glass on glass or add shadows to it.
- Gate these APIs with `#available(iOS 26, *)` only when the deployment target is below 26. Otherwise the fallback branch is dead code.

## Accessibility and layout

- Support Dynamic Type everywhere: no fixed heights on text containers. Test long text and the largest accessibility size.
- Tap targets are at least 44×44 pt. Give icon-only buttons a label (`Button("Add", systemImage: "plus")` gives one for free).
  Hide decorative images from VoiceOver.
- Don't express state with color alone. Respect Reduce Motion with `@Environment(\.accessibilityReduceMotion)`.

## Localization

- User-facing text uses `LocalizedStringKey` in SwiftUI or `String(localized:)` in code, stored in a String Catalog.
  Use catalog plural variants, and never build sentences by concatenation.
- Format numbers, currency, and dates with `FormatStyle` (`.currency(code:)`, `.dateTime`), never with hand-built strings.
