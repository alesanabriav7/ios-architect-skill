# Database and Migrations (GRDB)

Use this file for database package setup and schema evolution.

## DatabaseManager Template

```swift
import Foundation
import GRDB

public final class DatabaseManager: Sendable {
    public static var shared: DatabaseManager!

    public let writer: any DatabaseWriter
    public let reader: any DatabaseReader

    private init(writer: any DatabaseWriter) {
        self.writer = writer
        self.reader = writer as any DatabaseReader
    }

    @MainActor
    public static func makeShared() throws {
        if shared != nil { return }
        let path = URL.documentsDirectory.appending(path: "{app_name}.sqlite").path()
        let dbPool = try DatabasePool(path: path)
        try runMigrations(on: dbPool)
        shared = DatabaseManager(writer: dbPool)
    }

    private static func runMigrations(on db: DatabasePool) throws {
        var migrator = DatabaseMigrator()
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif
        registerMigrations(&migrator)
        try migrator.migrate(db)
    }
}
```

## Migration Rules

- Migrations are append-only.
- Never modify or rename existing migration identifiers.
- Use sequential IDs (`v1`, `v2`, `v3`...).

### Initial Migration

```swift
extension DatabaseManager {
    static func registerMigrations(_ migrator: inout DatabaseMigrator) {
        migrator.registerMigration("v1") { db in
            try db.create(table: "{entity_snake_case}") { t in
                t.primaryKey("id", .text).notNull()
                t.column("title", .text).notNull()
                t.column("amount", .integer).notNull()
                t.column("date", .datetime).notNull()
                t.column("category", .text).notNull().defaults(to: "")
                t.column("createdAt", .datetime).notNull()
            }
        }
    }
}
```

## Common Migration Operations

### Add column

```swift
migrator.registerMigration("v2") { db in
    try db.alter(table: "{table}") { t in
        t.add(column: "newField", .text).defaults(to: "")
    }
}
```

### Create table

```swift
migrator.registerMigration("v3") { db in
    try db.create(table: "new_table") { t in
        t.primaryKey("id", .text).notNull()
    }
}
```

### Seed data

```swift
migrator.registerMigration("v4") { db in
    try db.execute(
        sql: """
        INSERT INTO category (id, name, icon, scope, sortOrder, isDefault, createdAt)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """,
        arguments: [UUID().uuidString, "Food", "fork.knife", "both", 0, true, Date()]
    )
}
```
