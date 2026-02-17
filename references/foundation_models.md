# Foundation Models (On-Device AI) Reference

Use this file when a feature requires Apple Foundation Models integration.

Scope:

- iOS 26.0+ on-device generation
- Clean Architecture placement for AI flows
- Structured output with `@Generable`
- Availability, fallback, privacy, and testing patterns

Note: SDK signatures can evolve. Validate final APIs against the current Apple docs and Xcode autocomplete for your toolchain.

## Availability and Feature Gating

Always gate Foundation Models by both compile-time and runtime checks.

```swift
#if canImport(FoundationModels)
import FoundationModels
#endif

func canUseOnDeviceAI() -> Bool {
    guard #available(iOS 26.0, *) else { return false }
    return SystemLanguageModel.default.availability == .available
}
```

Runtime fallback is required:

- `.available`: show AI-enhanced experiences.
- `.unavailable`: use deterministic non-AI templates or rules.

## Layer Placement (Clean Architecture)

Use this split for AI features:

- Domain: input/output models + protocol (`Sendable`)
- Data: Foundation Models implementation + prompt builder + DTO mapping
- Presentation: view models and views consuming the domain protocol

Suggested structure:

```text
Features/{Feature}/
├── Domain/
│   ├── Models/
│   │   ├── {Feature}InsightInput.swift
│   │   └── {Feature}Insight.swift
│   └── Interfaces/
│       └── {Feature}InsightGeneratorProtocol.swift
├── Data/
│   ├── Generators/
│   │   └── FoundationModels{Feature}InsightGenerator.swift
│   ├── Prompting/
│   │   └── {Feature}PromptBuilder.swift
│   └── DTO/
│       └── Generated{Feature}Insight.swift
└── Presentation/
    ├── ViewModels/
    └── Views/
```

## Domain Protocol Template

```swift
import Foundation

struct {Feature}InsightInput: Sendable, Equatable {
    let contextSummary: String
    let keyValues: [String: String]
}

struct {Feature}Insight: Sendable, Equatable {
    let summary: String
    let suggestion: String
    let tone: Tone

    enum Tone: String, Sendable, Equatable {
        case positive
        case neutral
        case warning
    }
}

protocol {Feature}InsightGeneratorProtocol: Sendable {
    func generate(from input: {Feature}InsightInput) async throws -> {Feature}Insight
}
```

## Data-Layer Foundation Models Template

Keep Foundation Models types out of Domain. Map generated DTOs to domain models.

```swift
import Foundation
import FoundationModels

@Generable
struct Generated{Feature}Insight {
    @Guide(description: "One concise summary sentence")
    let summary: String

    @Guide(description: "One specific next action")
    let suggestion: String

    @Guide(.anyOf(["positive", "neutral", "warning"]))
    let tone: String

    func toDomain() -> {Feature}Insight {
        let mappedTone = {Feature}Insight.Tone(rawValue: tone) ?? .neutral
        return {Feature}Insight(summary: summary, suggestion: suggestion, tone: mappedTone)
    }
}

final class FoundationModels{Feature}InsightGenerator: {Feature}InsightGeneratorProtocol, Sendable {
    private let instructions: String

    init(instructions: String = "Return concise, factual guidance.") {
        self.instructions = instructions
    }

    func generate(from input: {Feature}InsightInput) async throws -> {Feature}Insight {
        let session = LanguageModelSession {
            instructions
        }

        let prompt = buildPrompt(from: input)
        let response = try await session.respond(
            to: prompt,
            generating: Generated{Feature}Insight.self,
            options: GenerationOptions(temperature: 0.2)
        )

        return response.content.toDomain()
    }

    private func buildPrompt(from input: {Feature}InsightInput) -> String {
        let keyValueLines = input.keyValues
            .sorted { $0.key < $1.key }
            .map { "\($0.key): \($0.value)" }
            .joined(separator: "\n")

        return """
        Context:
        \(input.contextSummary)

        Values:
        \(keyValueLines)
        """
    }
}
```

## Streaming Pattern

Use streaming when progressive UI feedback matters.

```swift
let session = LanguageModelSession { "Return concise guidance." }
let stream = session.streamResponse(
    to: prompt,
    generating: Generated{Feature}Insight.self
)

for try await partial in stream {
    // partial is Generated{Feature}Insight.PartiallyGenerated
    // update view state incrementally
}

let final = try await stream.collect()
let insight = final.content.toDomain()
```

Rules:

- Do not run concurrent requests against the same `LanguageModelSession`.
- Prefer one new session per request for stateless insight generation.
- Cancel in-flight work when user input changes rapidly.

## Availability + Fallback Strategy

Use AI as an enhancement, not as the only path.

```swift
@MainActor
@Observable
final class {Feature}ViewModel {
    private let aiGenerator: {Feature}InsightGeneratorProtocol
    private let fallbackGenerator: {Feature}InsightGeneratorProtocol

    var insight: {Feature}Insight?
    var isGenerating = false
    var aiEnabled = false

    init(
        aiGenerator: {Feature}InsightGeneratorProtocol,
        fallbackGenerator: {Feature}InsightGeneratorProtocol
    ) {
        self.aiGenerator = aiGenerator
        self.fallbackGenerator = fallbackGenerator
        self.aiEnabled = canUseOnDeviceAI()
    }

    func generateInsight(input: {Feature}InsightInput) async {
        isGenerating = true
        defer { isGenerating = false }

        do {
            let generator = aiEnabled ? aiGenerator : fallbackGenerator
            insight = try await generator.generate(from: input)
        } catch {
            insight = try? await fallbackGenerator.generate(from: input)
        }
    }
}
```

## Prompting Rules

- Send summarized/aggregated context, not raw event dumps.
- Never include secrets, raw identifiers, or unnecessary PII.
- Keep prompts deterministic in structure (stable keys/order).
- Keep output schema small; every generated property adds latency.

## Error Handling

Map model-level errors to user-safe domain outcomes.

```swift
do {
    let response = try await session.respond(to: prompt, generating: Generated{Feature}Insight.self)
} catch let error as LanguageModelSession.GenerationError {
    switch error {
    case .exceededContextWindowSize:
        // reduce prompt size and retry with summarized context
    case .guardrailViolation, .refusal:
        // show deterministic fallback insight
    case .decodingFailure:
        // retry once with stricter instructions or fallback
    case .concurrentRequests, .rateLimited:
        // backoff/debounce and retry
    case .assetsUnavailable:
        // mark AI unavailable and fallback
    @unknown default:
        // fallback
        break
    }
}
```

## Performance Rules

- Call `prewarm()` ahead of first expected generation.
- Debounce generation for live-edit flows.
- Use `GenerationOptions(temperature: 0.0...0.3)` for stable product copy.
- Keep response token budgets tight for card-style UI.

## Privacy and Product Rules

- Document AI usage and fallback behavior in feature specs.
- Treat output as assistive copy; never bypass core business validation.
- Keep deterministic fallback content functionally equivalent.
- Log only telemetry-safe metadata (latency, success/failure), not raw prompts unless policy allows.

## Testing Strategy

Test behavior without requiring model availability.

- Unit test prompt builder output (shape, key ordering, redaction).
- Unit test DTO-to-domain mapping and tone fallback.
- Unit test view model behavior for:
  - AI available
  - AI unavailable
  - AI error -> fallback
- Use mock generators for deterministic tests.

Mock template:

```swift
import Foundation

struct Mock{Feature}InsightGenerator: {Feature}InsightGeneratorProtocol {
    var result: Result<{Feature}Insight, Error>

    func generate(from input: {Feature}InsightInput) async throws -> {Feature}Insight {
        try result.get()
    }
}
```

## Integration Checklist

- [ ] `#available(iOS 26.0, *)` and runtime availability checks are present.
- [ ] Domain protocol exists; view models do not depend directly on `LanguageModelSession`.
- [ ] Fallback generator is implemented and exercised.
- [ ] Prompt excludes sensitive/raw data.
- [ ] Output schema is minimal and mapped to domain types.
- [ ] Streaming paths handle cancellation and finalization.
- [ ] AI and fallback states are tested.

## Sources

- [Apple Developer Documentation — FoundationModels](https://developer.apple.com/documentation/FoundationModels)
- [Meet the Foundation Models framework — WWDC25 Session 286](https://developer.apple.com/videos/play/wwdc2025/286/)
- [Deep dive into the Foundation Models framework — WWDC25 Session 301](https://developer.apple.com/videos/play/wwdc2025/301/)
- [Code-along: Bring on-device AI to your app — WWDC25 Session 259](https://developer.apple.com/videos/play/wwdc2025/259/)
