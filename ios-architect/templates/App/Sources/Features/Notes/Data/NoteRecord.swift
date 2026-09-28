import Foundation
import GRDB

nonisolated struct NoteRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "note"

    var id: String
    var title: String
    var body: String
    var isPinned: Bool
    var createdAt: Date
    var updatedAt: Date
}

nonisolated extension NoteRecord {
    init(_ note: Note) {
        self.init(
            id: note.id,
            title: note.title,
            body: note.body,
            isPinned: note.isPinned,
            createdAt: note.createdAt,
            updatedAt: note.updatedAt
        )
    }

    var note: Note {
        Note(id: id, title: title, body: body, isPinned: isPinned, createdAt: createdAt, updatedAt: updatedAt)
    }
}
