import Foundation
import Testing
@testable import SampleApp

struct APIClientTests {
    struct Item: Decodable, Equatable {
        let itemName: String
    }

    let baseURL = URL(string: "https://api.example.com")!

    @Test func decodesSnakeCaseResponses() async throws {
        let client = APIClient(baseURL: baseURL) { request in
            #expect(request.url?.path() == "/items/1")
            return (Data(#"{"item_name":"Pen"}"#.utf8), response(200, for: request))
        }

        #expect(try await client.send("GET", "items/1", as: Item.self) == Item(itemName: "Pen"))
    }

    @Test func mapsStatusCodesAndTransportErrors() async {
        let serverError = APIClient(baseURL: baseURL) { (Data(), response(503, for: $0)) }
        let offline = APIClient(baseURL: baseURL) { _ in throw URLError(.notConnectedToInternet) }

        await #expect(throws: APIError.http(status: 503)) { try await serverError.data("GET", "x") }
        await #expect(throws: APIError.transport(.notConnectedToInternet)) { try await offline.data("GET", "x") }
    }

    @Test func concurrentUnauthorizedRequestsShareOneRefresh() async throws {
        let refreshes = Counter()
        let auth = TokenRefresher(accessToken: "expired") {
            await refreshes.increment()
            try await Task.sleep(for: .milliseconds(50))
            return "fresh"
        }
        let client = APIClient(baseURL: baseURL, auth: auth) { request in
            let authorized = request.value(forHTTPHeaderField: "Authorization") == "Bearer fresh"
            return (Data(), response(authorized ? 204 : 401, for: request))
        }

        try await withThrowingTaskGroup(of: Data.self) { group in
            for _ in 0..<5 {
                group.addTask { try await client.data("GET", "me") }
            }
            try await group.waitForAll()
        }

        #expect(await refreshes.value == 1)
    }

    @Test func failedRefreshMeansUnauthorized() async {
        let auth = TokenRefresher(accessToken: "expired") { throw URLError(.userAuthenticationRequired) }
        let client = APIClient(baseURL: baseURL, auth: auth) { (Data(), response(401, for: $0)) }

        await #expect(throws: APIError.unauthorized) { try await client.data("GET", "me") }
    }
}

actor Counter {
    private(set) var value = 0
    func increment() { value += 1 }
}

nonisolated func response(_ status: Int, for request: URLRequest) -> HTTPURLResponse {
    HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
}
