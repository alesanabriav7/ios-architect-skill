import Foundation

/// Fixed IDs and dates so previews and screenshots are identical on every run.
nonisolated extension Note {
    static let fixtures: [Note] = [
        Note(
            id: "fixture-1",
            title: "Groceries",
            body: "Milk, eggs, coffee",
            isPinned: true,
            createdAt: Date(timeIntervalSince1970: 1_767_225_600),
            updatedAt: Date(timeIntervalSince1970: 1_767_225_600)
        ),
        Note(
            id: "fixture-2",
            title: "Trip ideas",
            body: "Lisbon in spring, a longer weekend in Kyoto",
            isPinned: false,
            createdAt: Date(timeIntervalSince1970: 1_767_139_200),
            updatedAt: Date(timeIntervalSince1970: 1_767_139_200)
        ),
    ]
}
