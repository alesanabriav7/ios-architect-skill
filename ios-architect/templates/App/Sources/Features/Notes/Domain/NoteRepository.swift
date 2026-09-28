import Foundation

nonisolated protocol NoteRepository: Sendable {
    /// Emits the current notes, then again after every change. Ends when the consuming task is cancelled.
    func observeAll() -> any AsyncSequence<[Note], any Error>
    func stats() async throws -> NoteStats
    func save(_ note: Note) async throws
    func delete(id: Note.ID) async throws
}

nonisolated protocol NoteTitleSuggesting: Sendable {
    /// Never throws: callers always get a usable title, from the model or the deterministic fallback.
    func suggestTitle(for body: String) async -> String
}
