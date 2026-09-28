# ios-architect-skill

Two agent skills for iOS work in Swift 6 and SwiftUI:

- **ios-architect**: features and apps with Clean Architecture (Domain/Data/Presentation), GRDB, networking,
  navigation and deep links, Foundation Models, design tokens, Swift Testing, and Swift Concurrency.
- **ios-visual**: deterministic simulator screenshots, visual regression, and design comparison.

The skill text is short: guardrails plus pointers. The code it points to lives in `ios-architect/templates/`,
a Tuist app (iOS 26, Swift 6, GRDB) that builds and passes its tests, so the examples are compiled code, not prose.

## Install

```bash
npx skills add https://github.com/alesanabriav7/ios-architect-skill
```

Or copy `ios-architect/` and `ios-visual/` into `.claude/skills/`.

## Verify the templates

```bash
ios-architect/scripts/verify-templates.sh            # default simulator: iPhone 17 Pro
ios-architect/scripts/verify-templates.sh "iPhone 17"
```

The script runs `tuist install`, `tuist generate`, and `xcodebuild test` twice: once with default isolation,
and once with `SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor` plus approachable concurrency. It needs Xcode 26+, Tuist 4, and an iOS 26+ simulator.
Run it after any change under `templates/`.

## Layout

```
ios-architect/
  SKILL.md              guardrails and a map to the templates
  references/           persistence, concurrency and testing, platform, UI, new app
  templates/            the compiled reference app and its tests
  scripts/              verify-templates.sh
  evals/                behavioral evals (run results in evals/README.md)
ios-visual/
  SKILL.md
```

## License

MIT
