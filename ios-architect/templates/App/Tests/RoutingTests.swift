import Foundation
import Testing
@testable import SampleApp

struct RoutingTests {
    @Test(arguments: [
        ("sampleapp://notes", AppRoute.notes),
        ("sampleapp://notes/new", .newNote),
        ("sampleapp://notes/abc", .note(id: "abc")),
        ("https://example.com/notes/abc", .note(id: "abc")),
    ])
    func parsesSupportedLinks(link: String, expected: AppRoute) throws {
        #expect(AppRoute(url: try #require(URL(string: link))) == expected)
    }

    @Test(arguments: ["sampleapp://settings", "https://evil.com/notes/abc", "sampleapp://notes/a/b"])
    func rejectsUnknownLinks(link: String) throws {
        #expect(AppRoute(url: try #require(URL(string: link))) == nil)
    }

    @Test @MainActor func routerOpensScreens() {
        let router = Router()
        router.open(.note(id: "abc"))
        #expect(router.path == ["abc"])

        router.open(.newNote)
        #expect(router.path.isEmpty)
        #expect(router.isAddingNote)
    }

    @Test func launchOptionsUseTheDeepLinkParser() {
        let options = LaunchOptions(["APP_USE_PREVIEW_DATA": "1", "APP_INITIAL_ROUTE": "sampleapp://notes/new"])
        #expect(options.usePreviewData)
        #expect(options.initialRoute == .newNote)
    }
}
