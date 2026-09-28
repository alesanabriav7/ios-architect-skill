import Foundation
import GRDB

nonisolated struct GRDBNoteRepository: NoteRepository {
    let database: AppDatabase

    /// Returns GRDB's own async sequence: no wrapper task, so cancelling the consumer stops the observation.
    func observeAll() -> any AsyncSequence<[Note], any Error> {
        ValueObservation
            .tracking { db in
                try NoteRecord
                    .order(Column("isPinned").desc, Column("updatedAt").desc)
                    .fetchAll(db)
                    .map(\.note)
            }
            .values(in: database.reader)
    }

    /// Aggregates run in SQL, never as a Swift loop issuing one query per row.
    func stats() async throws -> NoteStats {
        try await database.reader.read { db in
            let row = try Row.fetchOne(
                db,
                sql: "SELECT COUNT(*) AS total, COALESCE(SUM(isPinned), 0) AS pinned FROM note"
            )
            return NoteStats(total: row?["total"] ?? 0, pinned: row?["pinned"] ?? 0)
        }
    }

    func save(_ note: Note) async throws {
        try await database.writer.write { db in
            try NoteRecord(note).save(db)
        }
    }

    func delete(id: Note.ID) async throws {
        _ = try await database.writer.write { db in
            try NoteRecord.deleteOne(db, key: id)
        }
    }
}
