import Foundation
import Observation
import os

@MainActor
@Observable
final class NotesViewModel {
    private(set) var notes: [Note] = []
    private(set) var stats = NoteStats()
    private(set) var hasLoaded = false
    var errorMessage: String?

    private let repository: any NoteRepository
    private let titleSuggester: any NoteTitleSuggesting
    private let now: @Sendable () -> Date
    private let logger = Logger(subsystem: "dev.example.sampleapp", category: "Notes")

    init(
        repository: any NoteRepository,
        titleSuggester: any NoteTitleSuggesting,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.repository = repository
        self.titleSuggester = titleSuggester
        self.now = now
    }

    /// Call from `.task`: SwiftUI cancels it when the view disappears, which ends the observation.
    func observe() async {
        do {
            for try await notes in repository.observeAll() {
                self.notes = notes
                stats = try await repository.stats()
                hasLoaded = true
            }
        } catch is CancellationError {
        } catch {
            logger.error("Observing notes failed: \(error)")
            errorMessage = String(localized: "Couldn't load notes.")
            hasLoaded = true
        }
    }

    /// Returns a user-facing error message, or nil on success.
    func add(title: String, body: String) async -> String? {
        do {
            try await repository.save(Note.new(title: title, body: body, now: now()))
            return nil
        } catch NoteError.emptyTitle {
            return String(localized: "Title is required.")
        } catch {
            logger.error("Saving note failed: \(error)")
            return String(localized: "Couldn't save the note.")
        }
    }

    func togglePin(_ note: Note) async {
        var updated = note
        updated.isPinned.toggle()
        updated.updatedAt = now()
        do {
            try await repository.save(updated)
        } catch {
            logger.error("Pinning note failed: \(error)")
            errorMessage = String(localized: "Couldn't update the note.")
        }
    }

    func delete(_ note: Note) async {
        do {
            try await repository.delete(id: note.id)
        } catch {
            logger.error("Deleting note failed: \(error)")
            errorMessage = String(localized: "Couldn't delete the note.")
        }
    }

    func suggestTitle(for body: String) async -> String {
        await titleSuggester.suggestTitle(for: body)
    }
}
