# Persistence (GRDB)

Use this file for DatabaseManager setup, schema design, migrations, queries, and ValueObservation.

## DatabaseManager Template

```swift
import Foundation
import GRDB

public final class DatabaseManager: Sendable {
    private static var sharedInstance: DatabaseManager?

    public static var shared: DatabaseManager {
        guard let sharedInstance else {
            fatalError("DatabaseManager not initialized. Call makeShared() first.")
        }
        return sharedInstance
    }

    public static func resolveShared() throws -> DatabaseManager {
        guard let sharedInstance else {
            throw DatabaseError(message: "DatabaseManager not initialized. Call makeShared() first.")
        }
        return sharedInstance
    }

    public let writer: any DatabaseWriter
    public let reader: any DatabaseReader

    private init(writer: any DatabaseWriter) {
        self.writer = writer
        self.reader = writer as any DatabaseReader
    }

    @MainActor
    public static func makeShared() throws {
        if sharedInstance != nil { return }
        let path = URL.documentsDirectory.appending(path: "{app_name}.sqlite").path()
        let dbPool = try DatabasePool(path: path)
        try runMigrations(on: dbPool)
        sharedInstance = DatabaseManager(writer: dbPool)
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
migrator.registerMigration("v{next}") { db in
    try db.alter(table: "{table}") { t in
        t.add(column: "newField", .text).defaults(to: "")
    }
}
```

### Create table

```swift
migrator.registerMigration("v{next}") { db in
    try db.create(table: "new_table") { t in
        t.primaryKey("id", .text).notNull()
    }
}
```

### Add index (recommended for aggregate/filter paths)

```swift
migrator.registerMigration("v{next}") { db in
    try db.create(index: "idx_entry_bucketID_date", on: "entry", columns: ["bucketID", "date"])
}
```

## Query Performance Rules (Prevent N+1)

- Never run `fetchOne`, `fetchAll`, or ad-hoc SQL inside Swift loops (`for`, `map`, `forEach`) over previously fetched records.
- For grouped totals and metrics, compute in SQL with `GROUP BY`, `SUM`, `COUNT`, `AVG`, `MIN`, `MAX` and fetch projection rows.
- Prefer one query for aggregate screens. Association prefetch flows may use two queries (`including(required:)` / `including(all:)`), but not one query per parent row.
- If child/related data is needed, use joins or GRDB associations in the main request, never per-row relation fetches.
- Keep mappers pure (`row -> domain`) with no extra database calls.
- Add indexes on join/filter/order columns used by hot aggregate paths (for example `bucketID`, date columns, and sort keys).
- For aggregate endpoints, select only required projected columns instead of `SELECT *`.

### Anti-Pattern (N+1)

```swift
let buckets = try BucketRecord.fetchAll(db)

return try buckets.map { bucket in
    let total = try Int.fetchOne(
        db,
        sql: "SELECT COALESCE(SUM(amount), 0) FROM entry WHERE bucketID = ?",
        arguments: [bucket.id]
    ) ?? 0

    return BucketTotal(bucketID: bucket.id, name: bucket.name, totalAmount: total)
}
```

### Preferred Pattern: Aggregate in One Query

```swift
import Foundation
import GRDB

struct BucketTotalRow: FetchableRecord, Decodable, Sendable {
    let bucketID: String
    let bucketName: String
    let totalAmount: Int64
}

func fetchAll(for range: DateInterval) async throws -> [BucketTotal] {
    try await dbManager.reader.read { db in
        let rows = try BucketTotalRow.fetchAll(
            db,
            sql: """
            SELECT b.id AS bucketID,
                   b.name AS bucketName,
                   COALESCE(SUM(e.amount), 0) AS totalAmount
            FROM bucket b
            LEFT JOIN entry e
                ON e.bucketID = b.id
               AND e.date >= ?
               AND e.date < ?
            GROUP BY b.id, b.name
            ORDER BY totalAmount DESC, b.name ASC
            """,
            arguments: [range.start, range.end]
        )

        return rows.map {
            BucketTotal(
                bucketID: $0.bucketID,
                name: $0.bucketName,
                totalAmount: Int($0.totalAmount)
            )
        }
    }
}
```

### ValueObservation for Aggregates

Use the same single-query approach inside `ValueObservation.tracking`:

```swift
let observation = ValueObservation.tracking { db in
    try BucketTotalRow.fetchAll(
        db,
        sql: """
        SELECT b.id AS bucketID,
               b.name AS bucketName,
               COALESCE(SUM(e.amount), 0) AS totalAmount
        FROM bucket b
        LEFT JOIN entry e
            ON e.bucketID = b.id
           AND e.date >= ?
           AND e.date < ?
        GROUP BY b.id, b.name
        ORDER BY totalAmount DESC, b.name ASC
        """,
        arguments: [range.start, range.end]
    )
}
```

### Generated Code Review Checklist

- `fetchAll(for:)` methods should have exactly one read query for summaries (or one request with GRDB associations).
- No database access in per-item mapping or loops.
- Aggregates are computed by SQL, not Swift iteration.
- Query has deterministic ordering when returned to UI.

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

    init(dbManager: DatabaseManager) {
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
    @State private var viewModel: {Feature}ViewModel

    init(dbManager: DatabaseManager) {
        self._viewModel = State(initialValue: {Feature}ViewModel(dbManager: dbManager))
    }

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
migrator.registerMigration("v{next}") { db in
    try db.execute(
        sql: """
        INSERT INTO category (id, name, icon, scope, sortOrder, isDefault, createdAt)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """,
        arguments: [UUID().uuidString, "Food", "fork.knife", "both", 0, true, Date()]
    )
}
```

## Associations

Use GRDB associations for relationships between tables. Define associations as static properties on the record type.

### Defining Associations

```swift
struct CategoryRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "category"
    static let expenses = hasMany(ExpenseRecord.self)

    var id: String
    var name: String
}

struct ExpenseRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "expense"
    static let category = belongsTo(CategoryRecord.self)

    var id: String
    var categoryID: String
    var amount: Int64
}
```

### When to Use Which Association

| Association | Use when |
|---|---|
| `hasMany` | Parent owns multiple child records (Category → Expenses) |
| `hasOne` | Parent owns exactly one child record (User → Profile) |
| `belongsTo` | Child references a parent by foreign key (Expense → Category) |

### Prefetch Variants

| Variant | SQL behavior | When to use |
|---|---|---|
| `including(required:)` | INNER JOIN — excludes rows with no match | Always-present relationship (expense always has a category) |
| `including(optional:)` | LEFT JOIN — includes rows even if no match | Nullable relationship (expense may have no tag) |
| `including(all:)` | Two queries — parent + all children | `hasMany` collections; avoids cartesian product from JOIN |

### Master-Detail Prefetch (Avoids N+1)

```swift
struct CategoryWithExpenses: FetchableRecord, Decodable {
    var category: CategoryRecord
    var expenses: [ExpenseRecord]
}

func fetchCategoriesWithExpenses() async throws -> [CategoryWithExpenses] {
    try await dbManager.reader.read { db in
        let request = CategoryRecord
            .including(all: CategoryRecord.expenses)
            .order(Column("name").asc)
        return try CategoryWithExpenses.fetchAll(db, request)
    }
}
```

GRDB executes two queries for `including(all:)`: one for categories, one for all related expenses, then assembles the result in memory. This is O(N) — not N+1.

### When to Prefer Raw SQL Over Associations

Use raw SQL joins instead of GRDB associations when:
- **Aggregates are needed** — `SUM`, `COUNT`, `AVG` across related rows (see Query Performance Rules)
- **High-cardinality lists** — associations return full records; SQL can project only needed columns
- **Complex filter conditions** — multi-table `WHERE` clauses that don't map cleanly to association predicates
- **Performance-critical paths** — measure first; prefer associations for readability unless a query is provably slow
