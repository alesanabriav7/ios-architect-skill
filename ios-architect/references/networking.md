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

    init(service: String = Bundle.main.bundleIdentifier ?? "app", account: String = "auth_token") {
        self.service = service
        self.account = account
    }

    func currentToken() async throws(NetworkError) -> String {
        guard let token = readFromKeychain() else {
            throw .unauthorized
        }
        return token
    }

    func refreshToken() async throws(NetworkError) -> String {
        // Call your auth endpoint to get a fresh token.
        // Store the new token in Keychain and return it.
        fatalError("Implement refresh logic against your auth API")
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
    operation: @Sendable () async throws -> T
) async throws -> T {
    var delay = initialDelay
    for attempt in 1...maxAttempts {
        do {
            return try await operation()
        } catch {
            if attempt == maxAttempts { throw error }
            try await Task.sleep(for: delay)
            delay *= 2
        }
    }
    fatalError("Unreachable")
}
```

## Concurrency Notes

- `APIClientProtocol` is `Sendable` -- safe to share across actors.
- All methods use `async throws`.
- No mutable shared state in `URLSessionAPIClient`.
- Prefer `actor` for any caching or token management that holds mutable state.
