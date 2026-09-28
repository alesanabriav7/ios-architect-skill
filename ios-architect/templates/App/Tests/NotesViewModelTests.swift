import Foundation
import Testing
@testable import SampleApp

@MainActor
struct NotesViewModelTests {
    let repository: GRDBNoteRepository
    let viewModel: NotesViewModel

    init() throws {
        repository = GRDBNoteRepository(database: try .inMemory())
        viewModel = NotesViewModel(repository: repository, titleSuggester: FixedTitleSuggester())
    }

    @Test func addingANoteUpdatesTheObservedList() async throws {
        let observation = Task { await viewModel.observe() }
        defer { observation.cancel() }

        #expect(await viewModel.add(title: "  Milk  ", body: "") == nil)

        try await eventually { viewModel.notes.map(\.title) == ["Milk"] }
        #expect(viewModel.stats == NoteStats(total: 1, pinned: 0))
        #expect(viewModel.hasLoaded)
    }

    @Test func emptyTitleIsRejectedWithoutSaving() async throws {
        #expect(await viewModel.add(title: "   ", body: "text") == "Title is required.")
        #expect(try await repository.stats().total == 0)
    }

    @Test func repositoryFailureSurfacesAMessage() async {
        let failing = NotesViewModel(repository: FailingNoteRepository(), titleSuggester: FixedTitleSuggester())
        await failing.observe()
        #expect(failing.errorMessage == "Couldn't load notes.")
        #expect(failing.hasLoaded)
    }
}

/// Waits for main-actor state driven by another task. Fails instead of hanging.
@MainActor
func eventually(timeout: Duration = .seconds(2), _ condition: () -> Bool) async throws {
    let deadline = ContinuousClock.now + timeout
    while !condition() {
        guard ContinuousClock.now < deadline else {
            Issue.record("Condition not met within \(timeout)")
            return
        }
        try await Task.sleep(for: .milliseconds(10))
    }
}

struct FailingNoteRepository: NoteRepository {
    struct Failure: Error {}

    func observeAll() -> any AsyncSequence<[Note], any Error> {
        AsyncThrowingStream { $0.finish(throwing: Failure()) }
    }

    func stats() async throws -> NoteStats { throw Failure() }
    func save(_ note: Note) async throws { throw Failure() }
    func delete(id: Note.ID) async throws { throw Failure() }
}

@MainActor
struct NotesObservationLifetimeTests {
    @Test(.timeLimit(.minutes(1)))
    func cancellingTheTaskEndsObservation() async throws {
        let viewModel = NotesViewModel(
            repository: GRDBNoteRepository(database: try .inMemory()),
            titleSuggester: FixedTitleSuggester()
        )
        let observation = Task { await viewModel.observe() }
        try await eventually { viewModel.hasLoaded }

        observation.cancel()
        await observation.value
    }
}
