import Testing
@testable import SampleApp

struct TitleSuggesterTests {
    @Test(arguments: [
        ("Buy milk\nand eggs", "Buy milk"),
        ("   ", "Untitled"),
        (String(repeating: "a", count: 60), String(repeating: "a", count: 40)),
    ])
    func fallbackUsesTheFirstLine(body: String, expected: String) {
        #expect(FoundationModelsTitleSuggester.fallbackTitle(for: body) == expected)
    }
}
