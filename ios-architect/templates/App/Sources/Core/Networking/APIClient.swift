import Foundation

nonisolated enum APIError: Error, Equatable {
    case transport(URLError.Code)
    case unauthorized
    case http(status: Int)
    case decoding
}

nonisolated struct APIClient: Sendable {
    typealias Transport = @Sendable (URLRequest) async throws -> (Data, URLResponse)

    let baseURL: URL
    let auth: (any AccessTokenProvider)?
    let transport: Transport

    init(
        baseURL: URL,
        auth: (any AccessTokenProvider)? = nil,
        transport: @escaping Transport = { try await URLSession.shared.data(for: $0) }
    ) {
        self.baseURL = baseURL
        self.auth = auth
        self.transport = transport
    }

    func send<Response: Decodable>(
        _ method: String = "GET",
        _ path: String,
        body: (any Encodable & Sendable)? = nil,
        as type: Response.Type = Response.self
    ) async throws(APIError) -> Response {
        let data = try await data(method, path, body: body)
        do {
            return try JSONDecoder.api.decode(Response.self, from: data)
        } catch {
            throw .decoding
        }
    }

    func data(_ method: String, _ path: String, body: (any Encodable & Sendable)? = nil) async throws(APIError) -> Data {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = method
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                request.httpBody = try JSONEncoder.api.encode(body)
            } catch {
                throw .decoding
            }
        }

        let token = try await auth?.currentToken()
        var (data, status) = try await perform(request, token: token)
        // One retry after a single-flight refresh; a second 401 means the session is gone.
        if status == 401, let auth {
            let refreshed = try await auth.refreshToken(rejected: token)
            (data, status) = try await perform(request, token: refreshed)
        }

        switch status {
        case 200..<300: return data
        case 401: throw .unauthorized
        default: throw .http(status: status)
        }
    }

    private func perform(_ request: URLRequest, token: String?) async throws(APIError) -> (Data, Int) {
        var request = request
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await transport(request)
        } catch let error as URLError {
            throw .transport(error.code)
        } catch {
            throw .transport(.unknown)
        }
        guard let http = response as? HTTPURLResponse else { throw .transport(.badServerResponse) }
        return (data, http.statusCode)
    }
}

nonisolated extension JSONDecoder {
    static var api: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

nonisolated extension JSONEncoder {
    static var api: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
