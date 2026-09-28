import Foundation
import FoundationModels

nonisolated struct FoundationModelsTitleSuggester: NoteTitleSuggesting {
    func suggestTitle(for body: String) async -> String {
        let fallback = Self.fallbackTitle(for: body)
        // Availability changes at runtime (model downloading, Apple Intelligence toggled): check per call.
        guard case .available = SystemLanguageModel.default.availability else { return fallback }
        do {
            let session = LanguageModelSession(
                instructions: "Write a short title for the user's note. Use the note's language."
            )
            let response = try await session.respond(to: body, generating: SuggestedTitle.self)
            let title = response.content.title.trimmingCharacters(in: .whitespacesAndNewlines)
            return title.isEmpty ? fallback : title
        } catch {
            return fallback
        }
    }

    static func fallbackTitle(for body: String) -> String {
        let firstLine = body.split(whereSeparator: \.isNewline).first.map(String.init) ?? ""
        let trimmed = firstLine.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? String(localized: "Untitled") : String(trimmed.prefix(40))
    }
}

@Generable
nonisolated struct SuggestedTitle {
    @Guide(description: "A title of at most six words, no quotes")
    let title: String
}
