import Foundation

nonisolated protocol AccessTokenProvider: Sendable {
    func currentToken() async throws(APIError) -> String?
    /// `rejected` is the token that got the 401. If another caller already replaced it, the new one is returned without a second refresh.
    func refreshToken(rejected: String?) async throws(APIError) -> String
}

/// Single-flight refresh: N concurrent 401s trigger exactly one refresh request.
actor TokenRefresher: AccessTokenProvider {
    typealias Refresh = @Sendable () async throws -> String

    private var accessToken: String?
    private var inFlight: Task<String, any Error>?
    private let refresh: Refresh

    /// `refresh` exchanges the stored *refresh* token for a new access token (e.g. via `KeychainStore` + `APIClient`).
    /// Keep access and refresh tokens as separate Keychain items; never send the access token as the refresh token.
    init(accessToken: String?, refresh: @escaping Refresh) {
        self.accessToken = accessToken
        self.refresh = refresh
    }

    func currentToken() -> String? {
        accessToken
    }

    func refreshToken(rejected: String?) async throws(APIError) -> String {
        if let accessToken, accessToken != rejected {
            return accessToken
        }
        let task = inFlight ?? Task { try await refresh() }
        inFlight = task
        defer { inFlight = nil }
        do {
            let token = try await task.value
            accessToken = token
            return token
        } catch {
            accessToken = nil
            throw .unauthorized
        }
    }
}
