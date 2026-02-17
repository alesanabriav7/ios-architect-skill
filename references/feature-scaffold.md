# Feature Scaffold (Domain/Data/Presentation)

Use this file when creating or extending a feature module.

## Layer Boundaries

- Domain:
Pure business models + interfaces. `Foundation` only.
- Data:
Repository implementations + persistence mappings.
- Presentation:
SwiftUI views, feature components, and view models in the owning feature module.

## Ownership Rules

- Default all new entities/services/repositories/view-models to `Features/{Feature}/...`.
- Promote code to `Shared` only when at least two features/domains consume the same capability.
- Keep promoted code domain-scoped (for example `Shared/Settings/...`), not in generic shared buckets.
- Preserve Domain/Data/Presentation split even inside shared modules.

If the feature includes on-device AI generation, also apply `references/foundation_models.md`:

- Domain: add AI generator protocol and AI input/output models.
- Data: keep `FoundationModels` session + prompt building here.
- Presentation: consume protocol only; always support deterministic fallback UX.

If the feature includes Liquid Glass styling, also apply `references/liquid-glass.md`:

- Keep glass APIs in Presentation/shared UI components only.
- Gate with `#available(iOS 26.0, *)` and provide deterministic fallback materials.
- Reuse design-system glass components instead of one-off inline styles.
- Use native `.searchable(...)` for searchable views unless product explicitly requires a custom in-content field.
- For tab-based features, keep search/filter state scoped per tab and use search-tab APIs (`role: .search`, `tabViewSearchActivation(_:)`) when needed.

## Domain Templates

### Model

```swift
import Foundation

struct {Entity}: Identifiable, Codable, Sendable, Equatable, Hashable {
    let id: String
    var title: String
    var details: String
    var isCompleted: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        title: String,
        details: String = "",
        isCompleted: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
```

### Repository Interface

```swift
import Foundation

struct {Entity}Filter: Sendable, Equatable {
    var isCompleted: Bool?
    var searchText: String?

    init(isCompleted: Bool? = nil, searchText: String? = nil) {
        self.isCompleted = isCompleted
        self.searchText = searchText
    }
}

protocol {Entity}RepositoryProtocol: Sendable {
    func save(_ item: {Entity}) async throws
    func delete(_ item: {Entity}) async throws
    func fetchAll() async throws -> [{Entity}]
    func fetch(matching filter: {Entity}Filter) async throws -> [{Entity}]
}
```

## Data Templates

Mapping rules:

- Keep Domain expressive and persistence primitive.
- Add explicit mapper paths (`init(from:)` and `toDomain()`).
- Use stable ordering (`updatedAt` descending) for list-first features.
- If a domain needs special conversions (for example currency or measurements), document conversion rules beside the mapper.

### Record

```swift
import Foundation
import GRDB

struct {Entity}Record: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "{entity_snake_case}"

    var id: String
    var title: String
    var details: String
    var isCompleted: Bool
    var createdAt: Date
    var updatedAt: Date

    init(from entity: {Entity}) {
        self.id = entity.id
        self.title = entity.title
        self.details = entity.details
        self.isCompleted = entity.isCompleted
        self.createdAt = entity.createdAt
        self.updatedAt = entity.updatedAt
    }

    func toDomain() -> {Entity} {
        {Entity}(
            id: id,
            title: title,
            details: details,
            isCompleted: isCompleted,
            createdAt: createdAt,
            updatedAt: updatedAt
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
                .order(Column("updatedAt").desc)
                .fetchAll(db)
                .map { $0.toDomain() }
        }
    }

    func fetch(matching filter: {Entity}Filter) async throws -> [{Entity}] {
        try await dbManager.reader.read { db in
            var request = {Entity}Record
                .order(Column("updatedAt").desc)

            if let isCompleted = filter.isCompleted {
                request = request.filter(Column("isCompleted") == isCompleted)
            }

            if let searchText = filter.searchText?.trimmingCharacters(in: .whitespacesAndNewlines),
               !searchText.isEmpty {
                let pattern = "%\(searchText)%"
                request = request.filter(
                    Column("title").like(pattern) ||
                    Column("details").like(pattern)
                )
            }

            return try request
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
    var searchText = ""
    var showCompletedOnly = false
    var activeSheet: {Feature}SheetRoute?

    private let repository: {Entity}RepositoryProtocol

    init(repository: {Entity}RepositoryProtocol = {Entity}Repository()) {
        self.repository = repository
    }

    func loadItems() async {
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await repository.fetch(
                matching: {Entity}Filter(
                    isCompleted: showCompletedOnly ? true : nil,
                    searchText: searchText
                )
            )
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
    var details = ""
    var isCompleted = false
    var isSaving = false

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
            details = item.details
            isCompleted = item.isCompleted
        }
    }

    func save() async -> Bool {
        guard isValid else { return false }
        isSaving = true
        defer { isSaving = false }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let item = {Entity}(
            id: editingItem?.id ?? UUID().uuidString,
            title: trimmedTitle,
            details: details.trimmingCharacters(in: .whitespacesAndNewlines),
            isCompleted: isCompleted,
            createdAt: editingItem?.createdAt ?? .now,
            updatedAt: .now
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
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: Space.m) {
                    Toggle("Show completed only", isOn: $viewModel.showCompletedOnly)
                        .font(.dsCaption)
                        .padding(.horizontal, Space.l)
                        .onChange(of: viewModel.showCompletedOnly) {
                            Task { await viewModel.loadItems() }
                        }

                    ScrollView {
                        LazyVStack(spacing: Space.m) {
                            ForEach(viewModel.items) { item in
                                Button {
                                    viewModel.presentEditSheet(for: item)
                                } label: {
                                    {Entity}Row(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Space.l)
                    }
                }

                {Prefix}GlassFAB {
                    viewModel.presentNewSheet()
                }
                .padding(.trailing, Space.l)
                .padding(.bottom, Space.l)
            }
            .navigationTitle("{Feature}")
        }
        .searchable(text: $viewModel.searchText, prompt: "Filter by title or details")
        .onChange(of: viewModel.searchText) {
            Task { await viewModel.loadItems() }
        }
        .onSubmit(of: .search) {
            Task { await viewModel.loadItems() }
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
        @Bindable var viewModel = viewModel
        NavigationStack {
            Form {
                {Prefix}TextField("Title", prompt: "Required", text: $viewModel.title)
                {Prefix}TextField("Details", prompt: "Optional", text: $viewModel.details)
                Toggle("Completed", isOn: $viewModel.isCompleted)
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
        HStack(spacing: Space.m) {
            VStack(alignment: .leading, spacing: Space.xs) {
                Text(item.title)
                    .font(.dsBody)
                    .foregroundStyle(Color.textPrimary)

                Text(item.details.isEmpty ? "No details" : item.details)
                    .font(.dsCaption)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            Text(item.isCompleted ? "Completed" : "Open")
                .font(.dsCaption)
                .foregroundStyle(item.isCompleted ? Color.accentSuccess : Color.textSecondary)
        }
        .padding(Space.l)
        .background(Color.appSurface)
        .clipShape(.rect(cornerRadius: Radius.m))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.m)
                .stroke(Color.strokeSubtle, lineWidth: 1)
        )
    }
}
```
