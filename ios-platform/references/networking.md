# Networking Layer

Use this file when adding API-backed features with Clean Architecture networking.

## APIClient Protocol (Domain)

Define the client contract in the Domain layer. No URLSession imports here.

```swift
import Foundation

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

struct APIRequest: Sendable {
    let path: String
    let method: HTTPMethod
    let headers: [String: String]
    let queryItems: [URLQueryItem]
    let body: Data?

    init(
        path: String,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        queryItems: [URLQueryItem] = [],
        body: Data? = nil
    ) {
        self.path = path
        self.method = method
        self.headers = headers
        self.queryItems = queryItems
        self.body = body
    }
}

protocol APIClientProtocol: Sendable {
    func send<T: Decodable & Sendable>(_ request: APIRequest) async throws -> T
    func send(_ request: APIRequest) async throws
}
```

## URLSession Implementation (Data)

Concrete client lives in the Data layer. Inject `TokenProviderProtocol` for authenticated endpoints.

```swift
import Foundation

final class URLSessionAPIClient: APIClientProtocol, Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let tokenProvider: TokenProviderProtocol?

    init(
        baseURL: URL,
        session: URLSession = .shared,
        decoder: JSONDecoder = .apiDecoder,
        tokenProvider: TokenProviderProtocol? = nil
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
        self.tokenProvider = tokenProvider
    }

    func send<T: Decodable & Sendable>(_ request: APIRequest) async throws -> T {
        let (data, response) = try await perform(request)
        try validate(response)
        return try decoder.decode(T.self, from: data)
    }

    func send(_ request: APIRequest) async throws {
        let (_, response) = try await perform(request)
        try validate(response)
    }

    private func perform(_ request: APIRequest) async throws(NetworkError) -> (Data, HTTPURLResponse) {
        let (data, httpResponse) = try await executeRequest(request)

        // 401-retry: refresh token and retry once
        if httpResponse.statusCode == 401, let tokenProvider {
            let newToken = try await tokenProvider.refreshToken()
            var retryRequest = try buildURLRequest(from: request)
            retryRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")

            let retryData: Data
            let retryResponse: URLResponse
            do {
                (retryData, retryResponse) = try await session.data(for: retryRequest)
            } catch {
                throw .noConnection
            }
            guard let retryHTTP = retryResponse as? HTTPURLResponse else {
                throw .unexpected(nil)
            }
            return (retryData, retryHTTP)
        }

        return (data, httpResponse)
    }

    private func executeRequest(_ request: APIRequest) async throws(NetworkError) -> (Data, HTTPURLResponse) {
        var urlRequest = try buildURLRequest(from: request)

        if let tokenProvider {
            let token = try await tokenProvider.currentToken()
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw .noConnection
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw .unexpected(nil)
        }

        return (data, httpResponse)
    }

    private func buildURLRequest(from request: APIRequest) throws(NetworkError) -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(request.path), resolvingAgainstBaseURL: true)
        if !request.queryItems.isEmpty {
            components?.queryItems = request.queryItems
        }
        guard let url = components?.url else {
            throw .unexpected(nil)
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        return urlRequest
    }

    private func validate(_ response: HTTPURLResponse) throws(NetworkError) {
        switch response.statusCode {
        case 200...299: return
        case 401: throw .unauthorized
        case 404: throw .notFound
        case 500...599: throw .serverError(response.statusCode)
        default: throw .unexpected(nil)
        }
    }
}
```

## Error Handling

Single typed error enum for all networking failures.

```swift
enum NetworkError: Error, Sendable, Equatable {
    case unauthorized
    case notFound
    case serverError(Int)
    case noConnection
    case decodingFailed(String)
    case unexpected(String?)

    var isRetryable: Bool {
        switch self {
        case .serverError, .noConnection:
            return true
        default:
            return false
        }
    }
}
```

## Token Management

Injectable token provider protocol. Keep token storage in the Data layer using Keychain.

```swift
protocol TokenProviderProtocol: Sendable {
    func currentToken() async throws(NetworkError) -> String
    func refreshToken() async throws(NetworkError) -> String
}
```

Skeleton Keychain-backed implementation:

```swift
import Foundation
import Security

actor KeychainTokenProvider: TokenProviderProtocol {
    private let service: String
    private let account: String
    private let session: URLSession
    private let refreshURL: URL
    private var currentRefreshTask: Task<String, Error>?

    init(
        service: String = Bundle.main.bundleIdentifier ?? "app",
        account: String = "auth_token",
        session: URLSession = .shared,
        refreshURL: URL
    ) {
        self.service = service
        self.account = account
        self.session = session
        self.refreshURL = refreshURL
    }

    func currentToken() async throws(NetworkError) -> String {
        guard let token = readFromKeychain() else {
            throw .unauthorized
        }
        return token
    }

    func refreshToken() async throws(NetworkError) -> String {
        // Dedup concurrent refresh calls by reusing an in-flight task
        if let existing = currentRefreshTask {
            do {
                return try await existing.value
            } catch let error as NetworkError {
                throw error
            } catch {
                throw .unexpected(error.localizedDescription)
            }
        }

        let task = Task<String, Error> { [session, refreshURL] in
            guard let currentRefresh = readFromKeychain() else {
                throw NetworkError.unauthorized
            }

            var request = URLRequest(url: refreshURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(["refresh_token": currentRefresh])

            let (data, response) = try await session.data(for: request)

            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw NetworkError.unauthorized
            }

            struct TokenResponse: Decodable { let accessToken: String }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let tokenResponse = try decoder.decode(TokenResponse.self, from: data)
            return tokenResponse.accessToken
        }

        currentRefreshTask = task

        do {
            let newToken = try await task.value
            currentRefreshTask = nil
            saveToKeychain(newToken)
            return newToken
        } catch let error as NetworkError {
            currentRefreshTask = nil
            throw error
        } catch {
            currentRefreshTask = nil
            throw .unexpected(error.localizedDescription)
        }
    }

    private func readFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func saveToKeychain(_ token: String) {
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let attributes: [String: Any] = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var newItem = query
            newItem[kSecValueData as String] = data
            SecItemAdd(newItem as CFDictionary, nil)
        }
    }
}
```

## JSONDecoder Configuration

Shared decoder for consistent API response parsing.

```swift
extension JSONDecoder {
    static let apiDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
```

## Response Cache (Stale-While-Revalidate)

Recommended add-on for any API-backed feature. Provides instant first-load from a lightweight key-value cache, then silently refreshes from the network. **Do not use the database as a cache** -- GRDB is for structured, queryable, user-owned data. This cache is for ephemeral API responses only.

Use when:
- Read-heavy screens (feeds, profiles, settings, catalogs).
- You want sub-second first paint without a full database layer.
- The data is server-authoritative and the app never edits it locally.

Do not use when:
- The user creates or edits data offline -- use Offline-First with GRDB instead.
- You need to query/filter/sort cached data -- use a database.

### Cache Protocol (Domain)

```swift
import Foundation

protocol ResponseCacheProtocol: Sendable {
    func get<T: Codable & Sendable>(for key: String) async -> T?
    func set<T: Codable & Sendable>(_ value: T, for key: String) async
    func remove(for key: String) async
    func removeAll() async
}
```

### Cache Implementation (Data)

Two-tier: in-memory dictionary for nanosecond reads, file-backed for persistence across app launches. Stored in `Caches/` so the OS can reclaim disk under storage pressure.

```swift
import Foundation
import CryptoKit

actor ResponseCache: ResponseCacheProtocol {
    private struct Entry {
        let data: Data
        let storedAt: Date
    }

    private var memory: [String: Entry] = [:]
    private let directory: URL
    private let maxAge: Duration
    private let maxMemoryEntries: Int
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        namespace: String = "api",
        maxAge: Duration = .seconds(300),
        maxMemoryEntries: Int = 50
    ) {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.directory = caches.appendingPathComponent("ResponseCache/\(namespace)", isDirectory: true)
        self.maxAge = maxAge
        self.maxMemoryEntries = maxMemoryEntries
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func get<T: Codable & Sendable>(for key: String) async -> T? {
        let hash = hashedKey(key)

        // Tier 1: in-memory (nanoseconds)
        if let entry = memory[hash], !isExpired(entry) {
            return try? decoder.decode(T.self, from: entry.data)
        }

        // Tier 2: disk (microseconds)
        let file = directory.appendingPathComponent(hash)
        guard let raw = try? Data(contentsOf: file) else {
            memory[hash] = nil
            return nil
        }

        // Disk entry layout: 8 bytes timestamp + payload
        guard raw.count > 8 else { return nil }
        let interval = raw.prefix(8).withUnsafeBytes { $0.load(as: Double.self) }
        let storedAt = Date(timeIntervalSince1970: interval)
        let payload = raw.dropFirst(8)

        let entry = Entry(data: Data(payload), storedAt: storedAt)
        guard !isExpired(entry) else {
            try? FileManager.default.removeItem(at: file)
            memory[hash] = nil
            return nil
        }

        // Promote to memory for next read
        memory[hash] = entry
        return try? decoder.decode(T.self, from: entry.data)
    }

    func set<T: Codable & Sendable>(_ value: T, for key: String) async {
        guard let payload = try? encoder.encode(value) else { return }
        let now = Date.now
        let hash = hashedKey(key)
        let entry = Entry(data: payload, storedAt: now)

        // Tier 1: write to memory
        if memory.count >= maxMemoryEntries {
            evictOldestMemoryEntry()
        }
        memory[hash] = entry

        // Tier 2: write to disk (8-byte timestamp prefix + payload)
        var diskData = Data(capacity: 8 + payload.count)
        var interval = now.timeIntervalSince1970
        diskData.append(Data(bytes: &interval, count: 8))
        diskData.append(payload)
        try? diskData.write(to: directory.appendingPathComponent(hash), options: .atomic)
    }

    func remove(for key: String) async {
        let hash = hashedKey(key)
        memory[hash] = nil
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(hash))
    }

    func removeAll() async {
        memory.removeAll()
        try? FileManager.default.removeItem(at: directory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private func hashedKey(_ key: String) -> String {
        SHA256.hash(data: Data(key.utf8))
            .compactMap { String(format: "%02x", $0) }
            .joined()
    }

    private func isExpired(_ entry: Entry) -> Bool {
        Duration.seconds(Date.now.timeIntervalSince(entry.storedAt)) >= maxAge
    }

    private func evictOldestMemoryEntry() {
        guard let oldest = memory.min(by: { $0.value.storedAt < $1.value.storedAt }) else { return }
        memory[oldest.key] = nil
    }
}
```

### Cache Key Convention

Build the key from the full request identity so different queries never collide:

```swift
extension APIRequest {
    var cacheKey: String {
        var parts = [method.rawValue, path]
        if !queryItems.isEmpty {
            let sorted = queryItems
                .map { "\($0.name)=\($0.value ?? "")" }
                .sorted()
            parts.append(sorted.joined(separator: "&"))
        }
        return parts.joined(separator: ":")
    }
}
```

### Repository Integration

The repository owns the cache-then-refresh flow. The ViewModel never knows about the cache.

```swift
final class {Entity}Repository: {Entity}RepositoryProtocol, Sendable {
    private let api: APIClientProtocol
    private let cache: ResponseCacheProtocol

    init(api: APIClientProtocol, cache: ResponseCacheProtocol = ResponseCache()) {
        self.api = api
        self.cache = cache
    }

    func fetch(filter: {Entity}Filter?) async throws -> [{Entity}] {
        let request = APIRequest(path: "/{entities}", queryItems: filter?.queryItems ?? [])

        // 1. Return cached data if available
        if let cached: [{Entity}] = await cache.get(for: request.cacheKey) {
            return cached
        }

        // 2. No cache -- fetch from network
        let items: [{Entity}] = try await api.send(request)
        await cache.set(items, for: request.cacheKey)
        return items
    }

    func refresh(filter: {Entity}Filter?) async throws -> [{Entity}] {
        let request = APIRequest(path: "/{entities}", queryItems: filter?.queryItems ?? [])
        let items: [{Entity}] = try await api.send(request)
        await cache.set(items, for: request.cacheKey)
        return items
    }
}
```

### ViewModel: Diff Before Emit

Never replace the published array blindly -- diff against the current state so SwiftUI sees no change when the data is identical. This prevents flicker on refresh.

```swift
@Observable
@MainActor
final class {Entity}ListViewModel {
    private(set) var items: [{Entity}] = []
    private(set) var isLoading = false
    private(set) var error: AppError?

    private let repository: {Entity}RepositoryProtocol

    init(repository: {Entity}RepositoryProtocol) {
        self.repository = repository
    }

    func load() async {
        isLoading = items.isEmpty  // only show spinner on cold start
        do {
            items = try await repository.fetch(filter: nil)
            // Silent background refresh
            if let fresh = try? await repository.refresh(filter: nil) {
                applyIfChanged(fresh)
            }
        } catch {
            self.error = .from(error)
        }
        isLoading = false
    }

    /// Replace items only when the content actually changed.
    /// Equatable diff prevents SwiftUI from re-rendering identical lists.
    private func applyIfChanged(_ new: [{Entity}]) {
        guard items != new else { return }
        items = new
    }
}
```

### Rules

- **Database is not a cache.** GRDB stores user-owned, queryable, offline-editable data. `ResponseCache` stores throwaway API snapshots.
- **Diff before emit.** Always compare old vs new before assigning to an `@Observable` property. SwiftUI will skip re-rendering when the value is unchanged, but only if you skip the assignment entirely.
- **Show loading only on cold start.** When cache returns data, suppress the loading spinner. Show a subtle refresh indicator if needed, not a full skeleton.
- **Invalidate on mutations.** After a POST/PUT/DELETE that changes server state, call `cache.remove(for:)` on the affected keys so the next read fetches fresh data.
- **Let the OS evict.** Store in `Caches/` directory, not `Documents/`. The system reclaims this storage under pressure. Never treat cached data as durable.

## Offline-First Pattern

Try local DB first, sync from network, reconcile. Use this when the feature must work without connectivity.

```swift
protocol OfflineSyncServiceProtocol: Sendable {
    func fetchLocal() async throws -> [{Entity}]
    func fetchRemote() async throws -> [{Entity}]
    func reconcile(local: [{Entity}], remote: [{Entity}]) async throws -> [{Entity}]
}
```

Typical flow:

1. Load from local repository and display immediately.
2. Fetch from remote in the background.
3. Reconcile using `updatedAt` timestamps -- remote wins on conflict unless local has unsynchronized edits.
4. Persist reconciled set back to local DB.

## Retry with Exponential Backoff

Wrap unreliable network calls with bounded retry logic.

```swift
func withRetry<T: Sendable>(
    maxAttempts: Int = 3,
    initialDelay: Duration = .seconds(1),
    shouldRetry: @Sendable (Error) -> Bool = { ($0 as? NetworkError)?.isRetryable == true },
    operation: @Sendable () async throws -> T
) async throws -> T {
    var delay = initialDelay
    for attempt in 1...maxAttempts {
        do {
            return try await operation()
        } catch {
            guard attempt < maxAttempts, shouldRetry(error) else { throw error }
            try await Task.sleep(for: delay)
            delay *= 2
        }
    }
    // All attempts exhausted; the final error is thrown inside the loop.
    throw NetworkError.unexpected("Retry loop exited unexpectedly")
}
```

## Concurrency Notes

- `APIClientProtocol` is `Sendable` -- safe to share across actors.
- All methods use `async throws`.
- No mutable shared state in `URLSessionAPIClient`.
- Prefer `actor` for any caching or token management that holds mutable state.
