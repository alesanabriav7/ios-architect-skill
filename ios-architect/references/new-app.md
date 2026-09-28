# New app from scratch

1. Copy `templates/Project.swift`, `Tuist.swift`, `Tuist/Package.swift`, and `.gitignore`. Rename the app, bundle IDs, and URL scheme.
   Drop the `TUIST_MAIN_ACTOR_DEFAULT` switch, or keep `SWIFT_DEFAULT_ACTOR_ISOLATION` fixed if the team wants MainActor-by-default.
2. Deployment target: the current iOS major minus one unless the user says otherwise. Don't pin `compatibleXcodeVersions` to a single major,
   because the next Xcode then refuses to generate the project.
3. Start from `templates/App/Sources/`: `SampleApp.swift` (entry point, launch options, failure screen), `AppEnvironment.swift` (composition root),
   `Router.swift`, `AppDatabase.swift`, then one feature slice. Remove the parts the app doesn't need (networking, Foundation Models, design system).
4. Run `tuist install && tuist generate --no-open`, then `xcodebuild test` on a simulator. Deliver only after both succeed, together with the command output.
5. Keep generated files out of Git (`*.xcodeproj`, `*.xcworkspace`, `Derived/`, `Tuist/.build/`).
