import Foundation
import GRDB

/// Owns the connection and the schema. Inject it; never reach for a global.
nonisolated struct AppDatabase: Sendable {
    let writer: any DatabaseWriter
    var reader: any DatabaseReader { writer }

    init(_ writer: any DatabaseWriter) throws {
        self.writer = writer
        try Self.migrator.migrate(writer)
    }

    static func onDisk(fileName: String = "app.sqlite") throws -> AppDatabase {
        let directory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return try AppDatabase(DatabasePool(path: directory.appending(path: fileName).path()))
    }

    static func inMemory() throws -> AppDatabase {
        try AppDatabase(DatabaseQueue())
    }

    /// Append-only: never edit, rename, or reorder a shipped migration.
    /// Avoid `eraseDatabaseOnSchemaChange`; it deletes real data on any device running a debug build.
    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1_createNote") { db in
            try db.create(table: "note") { t in
                t.primaryKey("id", .text)
                t.column("title", .text).notNull()
                t.column("body", .text).notNull().defaults(to: "")
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull().indexed()
            }
        }
        migrator.registerMigration("v2_addNoteIsPinned") { db in
            try db.alter(table: "note") { t in
                t.add(column: "isPinned", .boolean).notNull().defaults(to: false)
            }
        }
        return migrator
    }
}
