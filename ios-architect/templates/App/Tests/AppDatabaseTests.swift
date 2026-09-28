import Foundation
import GRDB
import Testing
@testable import SampleApp

struct AppDatabaseTests {
    @Test func migratingTwiceIsANoOp() throws {
        let queue = try DatabaseQueue()
        try AppDatabase.migrator.migrate(queue)
        try AppDatabase.migrator.migrate(queue)
        let applied = try queue.read { try AppDatabase.migrator.appliedIdentifiers($0) }
        #expect(applied == ["v1_createNote", "v2_addNoteIsPinned"])
    }

    @Test func upgradeKeepsExistingRows() throws {
        let queue = try DatabaseQueue()
        try AppDatabase.migrator.migrate(queue, upTo: "v1_createNote")
        try queue.write { db in
            try db.execute(
                sql: "INSERT INTO note (id, title, body, createdAt, updatedAt) VALUES ('a', 'Old', '', ?, ?)",
                arguments: [Date(), Date()]
            )
        }

        try AppDatabase.migrator.migrate(queue)

        let note = try queue.read { try NoteRecord.fetchOne($0, key: "a") }
        #expect(note?.title == "Old")
        #expect(note?.isPinned == false)
    }
}
