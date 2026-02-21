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

## Reactive Queries with ValueObservation

`ValueObservation` provides live-updating queries that emit new values whenever the observed database region changes. This replaces manual `loadItems()` refresh patterns for list views.

### ViewModel with ValueObservation

```swift
import Foundation
import GRDB
import Observation

@Observable
@MainActor
final class {Feature}ViewModel {
    var items: [{Entity}] = []
    var errorState: AppError?
    private var observationTask: Task<Void, Never>?

    private let dbManager: DatabaseManager

    init(dbManager: DatabaseManager = .shared) {
        self.dbManager = dbManager
    }

    func startObserving() {
        observationTask?.cancel()
        observationTask = Task { [weak self] in
            guard let self else { return }
            let observation = ValueObservation.tracking { db in
                try {Entity}Record
                    .order(Column("updatedAt").desc)
                    .fetchAll(db)
                    .map { $0.toDomain() }
            }

            do {
                for try await items in observation.values(in: dbManager.reader) {
                    self.items = items
                }
            } catch {
                if !Task.isCancelled {
                    self.errorState = .persistence(error.localizedDescription)
                }
            }
        }
    }

    func stopObserving() {
        observationTask?.cancel()
        observationTask = nil
    }

    deinit {
        observationTask?.cancel()
    }
}
```

### View Integration

```swift
struct {Feature}View: View {
    @State private var viewModel = {Feature}ViewModel()

    var body: some View {
        List(viewModel.items) { item in
            {Entity}Row(item: item)
        }
        .task {
            viewModel.startObserving()
        }
    }
}
```

### When to Use ValueObservation

- Use `ValueObservation` for list views and any screen that should reflect database changes in real time.
- Use one-shot `fetch`/`fetchAll` for detail views or screens that load data once.
- `ValueObservation` automatically coalesces rapid changes and delivers results on the main actor when used with `@MainActor` ViewModels.

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
