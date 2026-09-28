# Platform: networking, auth, navigation, on-device AI, privacy

## Networking and auth

Reference code: `templates/App/Sources/Core/Networking/`, `App/Tests/APIClientTests.swift`.

- The client is a `Sendable` struct with an injected `transport` closure. Tests stub the closure; there's no URLProtocol global state.
- Map failures to a typed error (transport, unauthorized, HTTP status, decoding) inside Data. Presentation maps errors to localized messages.
- On a 401, refresh once through an actor that single-flights concurrent refreshes, then retry once. A second 401 means signed out.
- Keep access and refresh tokens as separate Keychain items (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`).
  Never store them in UserDefaults or files, and never log them.
- Retry only idempotent requests, and only on transport errors or 5xx, with bounded backoff.

## Navigation and deep links

Reference code: `templates/App/Sources/App/Router.swift`, `SampleApp.swift`, `App/Tests/RoutingTests.swift`.

- Keep one `@MainActor @Observable` router that owns `NavigationStack(path:)` state and sheet flags.
  Inject it with `.environment(router)` and read it with `@Environment(Router.self)`. Don't use an `@Entry` default instance, which fails to compile for MainActor types and hides missing injection.
- Parse custom-scheme links, universal links, and screenshot launch routes with one function (`AppRoute(url:)`).
  Reject unknown schemes and hosts, and test the parser with a table of URLs.
- Show errors from inside a sheet within that sheet. An alert attached to the presenting view doesn't appear while the sheet is up.
- Use `TabView` with a stack per tab for 3–5 top-level sections, and `NavigationSplitView` when iPad needs a sidebar.

## Foundation Models

Reference code: `templates/App/Sources/Features/Notes/Data/FoundationModelsTitleSuggester.swift`.

- Put the Domain protocol in the feature and the `FoundationModels` import in Data only. Every call returns a usable deterministic fallback.
- Check `SystemLanguageModel.default.availability` on each call: the model can be downloading, or Apple Intelligence can be turned off.
- Use one `LanguageModelSession` per independent request, and never send concurrent requests to the same session.
  Use `@Generable` with `@Guide` for structured output and keep the schema small.
- Send summarized context, not raw personal data. Test the fallback and the mapping, not the model's wording.

## Privacy and App Store

- `PrivacyInfo.xcprivacy` declares only the Required Reason APIs the app actually calls, for example `NSPrivacyAccessedAPICategoryUserDefaults` `CA92.1`,
  `…FileTimestamp` `C617.1`, `…DiskSpace` `E174.1`, `…SystemBootTime` `35F9.1`. Check Xcode's privacy report (Organizer → Generate Privacy Report) after adding SDKs.
- If the app lets users create accounts, it must let them delete the account in-app.
  With Sign in with Apple, revocation happens on your server (`POST https://appleid.apple.com/auth/revoke`); there is no client API for it.
- Request App Tracking Transparency only if the app tracks users across other companies' apps or sites. Set `NSPrivacyTracking` to match.
