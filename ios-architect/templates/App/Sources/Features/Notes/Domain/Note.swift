import Foundation

nonisolated struct Note: Identifiable, Hashable, Sendable {
    let id: String
    var title: String
    var body: String
    var isPinned: Bool
    let createdAt: Date
    var updatedAt: Date

    static func new(title: String, body: String, now: Date) throws(NoteError) -> Note {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { throw .emptyTitle }
        return Note(
            id: UUID().uuidString,
            title: title,
            body: body.trimmingCharacters(in: .whitespacesAndNewlines),
            isPinned: false,
            createdAt: now,
            updatedAt: now
        )
    }
}

nonisolated struct NoteStats: Equatable, Sendable {
    var total = 0
    var pinned = 0
}

nonisolated enum NoteError: Error, Equatable {
    case emptyTitle
}
