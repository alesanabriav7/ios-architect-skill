# Feature Scaffold (Domain/Data/Presentation)

Use this file when creating or extending a feature module.

## Layer Boundaries

- Domain:
Pure business models + interfaces. `Foundation` only.
- Data:
Repository implementations + persistence mappings.
- Presentation:
SwiftUI views, feature components, and view models.

## Domain Templates

### Model

```swift
import Foundation

struct {Entity}: Identifiable, Codable, Sendable, Equatable, Hashable {
    let id: String
    var title: String
    var amount: Decimal
    var date: Date
    var category: String
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        title: String,
        amount: Decimal,
        date: Date = .now,
        category: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.date = date
        self.category = category
        self.createdAt = createdAt
    }
}
```

### Repository Interface

```swift
import Foundation

protocol {Entity}RepositoryProtocol: Sendable {
    func save(_ item: {Entity}) async throws
    func delete(_ item: {Entity}) async throws
    func fetchAll() async throws -> [{Entity}]
    func fetch(for month: Date) async throws -> [{Entity}]
}
```

## Data Templates

Money rule:

- Domain uses `Decimal`.
- Persistence uses `Int` cents.
- Multiply by 100 on save, divide by 100 on load.

### Record

```swift
import Foundation
import GRDB

struct {Entity}Record: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "{entity_snake_case}"

    var id: String
    var title: String
    var amount: Int
    var date: Date
    var category: String
    var createdAt: Date

    init(from entity: {Entity}) {
        self.id = entity.id
        self.title = entity.title
        self.amount = Int((entity.amount * 100).rounded())
        self.date = entity.date
        self.category = entity.category
        self.createdAt = entity.createdAt
    }

    func toDomain() -> {Entity} {
        {Entity}(
            id: id,
            title: title,
            amount: Decimal(amount) / 100,
            date: date,
            category: category,
            createdAt: createdAt
        )
    }
}
```

### Repository Implementation

```swift
import Foundation
import GRDB

final class {Entity}Repository: {Entity}RepositoryProtocol, Sendable {
    private let dbManager: DatabaseManager

    init(dbManager: DatabaseManager = .shared) {
        self.dbManager = dbManager
    }

    func save(_ item: {Entity}) async throws {
        let record = {Entity}Record(from: item)
        try await dbManager.writer.write { db in
            try record.save(db)
        }
    }

    func delete(_ item: {Entity}) async throws {
        try await dbManager.writer.write { db in
            _ = try {Entity}Record.deleteOne(db, key: item.id)
        }
    }

    func fetchAll() async throws -> [{Entity}] {
        try await dbManager.reader.read { db in
            try {Entity}Record
                .order(Column("createdAt").desc)
                .fetchAll(db)
                .map { $0.toDomain() }
        }
    }

    func fetch(for month: Date) async throws -> [{Entity}] {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let end = calendar.date(byAdding: .month, value: 1, to: start)!

        return try await dbManager.reader.read { db in
            try {Entity}Record
                .filter(Column("date") >= start && Column("date") < end)
                .order(Column("date").desc)
                .fetchAll(db)
                .map { $0.toDomain() }
        }
    }
}
```

## Presentation Templates

### Sheet Route

```swift
enum {Feature}SheetRoute: Identifiable, Equatable {
    case new
    case edit({Entity})

    var id: String {
        switch self {
        case .new: return "new"
        case .edit(let item): return "edit-\(item.id)"
        }
    }
}
```

### Feature ViewModel

```swift
import Foundation

@Observable
@MainActor
final class {Feature}ViewModel {
    var items: [{Entity}] = []
    var isLoading = false
    var errorMessage: String?
    var activeSheet: {Feature}SheetRoute?

    private let repository: {Entity}RepositoryProtocol

    init(repository: {Entity}RepositoryProtocol = {Entity}Repository()) {
        self.repository = repository
    }

    func loadItems() async {
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await repository.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ item: {Entity}) async {
        do {
            try await repository.delete(item)
            items.removeAll { $0.id == item.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func presentNewSheet() { activeSheet = .new }
    func presentEditSheet(for item: {Entity}) { activeSheet = .edit(item) }
}
```

### Form ViewModel

```swift
import Foundation

@Observable
@MainActor
final class {Entity}FormViewModel {
    var title = ""
    var amount = ""
    var date = Date.now
    var category = ""
    var isSaving = false

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        Decimal(string: amount) != nil &&
        Decimal(string: amount)! > 0
    }

    private let repository: {Entity}RepositoryProtocol
    private let editingItem: {Entity}?
    var isEditing: Bool { editingItem != nil }

    init(
        repository: {Entity}RepositoryProtocol = {Entity}Repository(),
        editing item: {Entity}? = nil
    ) {
        self.repository = repository
        self.editingItem = item
        if let item {
            title = item.title
            amount = "\(item.amount)"
            date = item.date
            category = item.category
        }
    }

    func save() async -> Bool {
        guard isValid else { return false }
        isSaving = true
        defer { isSaving = false }

        let item = {Entity}(
            id: editingItem?.id ?? UUID().uuidString,
            title: title.trimmingCharacters(in: .whitespaces),
            amount: Decimal(string: amount)!,
            date: date,
            category: category,
            createdAt: editingItem?.createdAt ?? .now
        )

        do {
            try await repository.save(item)
            return true
        } catch {
            return false
        }
    }
}
```

### View + Sheet + Row

```swift
import SwiftUI

struct {Feature}View: View {
    @State private var viewModel = {Feature}ViewModel()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.items) { item in
                        {Entity}Row(item: item)
                            .onTapGesture { viewModel.presentEditSheet(for: item) }
                    }
                }
                .padding(.horizontal, 16)
            }

            {Prefix}GlassFAB {
                viewModel.presentNewSheet()
            }
            .padding(.trailing, 16)
            .padding(.bottom, 16)
        }
        .task { await viewModel.loadItems() }
        .sheet(item: $viewModel.activeSheet) { route in
            switch route {
            case .new: {Entity}Sheet()
            case .edit(let item): {Entity}Sheet(editing: item)
            }
        }
    }
}

struct {Entity}Sheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: {Entity}FormViewModel

    init(editing item: {Entity}? = nil) {
        _viewModel = State(initialValue: {Entity}FormViewModel(editing: item))
    }

    var body: some View {
        NavigationStack {
            Form {
                // fields
            }
            .navigationTitle(viewModel.isEditing ? "Edit" : "New")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if await viewModel.save() { dismiss() }
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isSaving)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

struct {Entity}Row: View {
    let item: {Entity}

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title).font(.uiLabel)
                Text(item.category).font(.uiCaption)
            }
            Spacer()
            Text(formatAmount(item.amount)).font(.dataBody(size: 16))
        }
        .padding(16)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formatAmount(_ amount: Decimal) -> String {
        amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }
}
```
