import Foundation

/// Composition root: the only place that chooses concrete implementations.
nonisolated struct AppEnvironment: Sendable {
    let notes: any NoteRepository
    let titleSuggester: any NoteTitleSuggesting

    static func live() throws -> AppEnvironment {
        AppEnvironment(
            notes: GRDBNoteRepository(database: try .onDisk()),
            titleSuggester: FoundationModelsTitleSuggester()
        )
    }

    /// Deterministic data for previews, screenshots, and UI tests: in-memory database seeded with fixtures.
    static func preview() throws -> AppEnvironment {
        let database = try AppDatabase.inMemory()
        try database.writer.write { db in
            for note in Note.fixtures {
                try NoteRecord(note).insert(db)
            }
        }
        return AppEnvironment(
            notes: GRDBNoteRepository(database: database),
            titleSuggester: FixedTitleSuggester()
        )
    }
}

nonisolated struct FixedTitleSuggester: NoteTitleSuggesting {
    func suggestTitle(for body: String) async -> String {
        FoundationModelsTitleSuggester.fallbackTitle(for: body)
    }
}
