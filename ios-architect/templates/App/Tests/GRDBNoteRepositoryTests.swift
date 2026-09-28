import Foundation
import Testing
@testable import SampleApp

struct GRDBNoteRepositoryTests {
    let repository: GRDBNoteRepository

    init() throws {
        repository = GRDBNoteRepository(database: try .inMemory())
    }

    @Test(.timeLimit(.minutes(1)))
    func observationEmitsInitialValueThenChanges() async throws {
        let note = try Note.new(title: "First", body: "", now: .now)
        var emissions: [[Note.ID]] = []

        for try await notes in repository.observeAll() {
            emissions.append(notes.map(\.id))
            if emissions.count == 1 { try await repository.save(note) }
            if emissions.count == 2 { break }
        }

        #expect(emissions == [[], [note.id]])
    }

    @Test func statsAreComputedInSQL() async throws {
        var pinned = try Note.new(title: "A", body: "", now: .now)
        pinned.isPinned = true
        try await repository.save(pinned)
        try await repository.save(Note.new(title: "B", body: "", now: .now))

        #expect(try await repository.stats() == NoteStats(total: 2, pinned: 1))
    }

    @Test func deleteRemovesTheNote() async throws {
        let note = try Note.new(title: "Gone", body: "", now: .now)
        try await repository.save(note)
        try await repository.delete(id: note.id)

        #expect(try await repository.stats().total == 0)
    }
}
