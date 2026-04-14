# Error Taxonomy

Use this file to understand how errors are classified, contained, and surfaced across architecture layers.

## Layer Responsibilities

### Domain Errors

Business rule violations: validation failures, entity not found, constraint violations.

- Use typed enums per feature. Never import Data layer types into Domain.
- Name them `{Feature}Error` (e.g. `ExpenseError`, `CategoryError`).

```swift
enum ExpenseError: Error, Equatable, Sendable {
    case titleRequired
    case amountMustBePositive
    case categoryNotFound(id: String)
    case duplicateEntry
}
```

### Data Errors

Wrap persistence (GRDB) and network (`URLError`, `NetworkError`) failures into typed enums. Map to Domain errors at the repository implementation boundary. GRDB types must never leak into Domain.

```swift
// In the Data layer repository implementation:
func save(_ expense: Expense) async throws {
    do {
        let record = ExpenseRecord(from: expense)
        try await dbManager.writer.write { db in try record.save(db) }
    } catch let error as DatabaseError where error.extendedResultCode == .SQLITE_CONSTRAINT_UNIQUE {
        throw ExpenseError.duplicateEntry
    } catch {
        throw AppError.persistence(error.localizedDescription)
    }
}
```

### Presentation Errors

Map Domain errors to user-facing strings in ViewModel. Use a `localizedErrorMessage(from:)` helper. Never show raw `error.localizedDescription` to users.

```swift
func localizedErrorMessage(from error: Error) -> String {
    switch error {
    case ExpenseError.titleRequired:
        return String(localized: "Title is required.")
    case ExpenseError.amountMustBePositive:
        return String(localized: "Amount must be greater than zero.")
    case AppError.network(.unauthorized):
        return String(localized: "Session expired. Please sign in again.")
    case AppError.network(.noConnection):
        return String(localized: "No internet connection.")
    default:
        return String(localized: "Something went wrong.")
    }
}
```

In the ViewModel, catch domain errors and map to a user message:

```swift
func save() async {
    do {
        try await repository.save(expense)
    } catch {
        errorMessage = localizedErrorMessage(from: error)
    }
}
```

### AppError

A top-level enum for errors that cross feature boundaries (auth expired, no network). ViewModels catch domain errors and map to `AppError` only when routing or global alerts are needed.

`NetworkError` is defined in `ios-platform/references/networking.md` (Error Handling section). Reproduced here for context:

```swift
enum NetworkError: Error, Sendable, Equatable {
    case unauthorized
    case notFound
    case serverError(Int)
    case noConnection
    case decodingFailed(String)
    case unexpected(String?)
}
```

```swift
enum AppError: Error, Equatable, Sendable {
    case network(NetworkError)
    case persistence(String)
    case validation(String)
    case unexpected(String)

    var userMessage: String {
        switch self {
        case .network(.noConnection):
            return String(localized: "No internet connection. Please try again.")
        case .network(.unauthorized):
            return String(localized: "Session expired. Please sign in again.")
        case .network(.serverError):
            return String(localized: "Server error. Please try again later.")
        case .network:
            return String(localized: "A network error occurred.")
        case .persistence:
            return String(localized: "Failed to save or load data.")
        case .validation(let message):
            return message
        case .unexpected:
            return String(localized: "Something went wrong.")
        }
    }
}
```

## Error Flow

```
Domain layer throws {Feature}Error
        ↓
Data layer catches GRDB/network errors → maps to {Feature}Error or AppError
        ↓
ViewModel catches domain errors → maps to user-facing string via localizedErrorMessage(from:)
        ↓
View binds errorMessage/.errorState to .alert modifier
```

Never let GRDB types (`DatabaseError`) reach the ViewModel. Never show raw `error.localizedDescription` in UI without mapping.
