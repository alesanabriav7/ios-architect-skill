import Foundation
import Observation

nonisolated enum AppRoute: Hashable, Sendable {
    case notes
    case note(id: String)
    case newNote

    /// Accepts `sampleapp://notes[/new|/<id>]` and `https://example.com/notes[/new|/<id>]`.
    init?(url: URL) {
        var segments = url.pathComponents.filter { $0 != "/" }
        if url.scheme == "sampleapp", let host = url.host() {
            segments.insert(host, at: 0)
        } else if url.scheme != "https" || url.host() != "example.com" {
            return nil
        }
        switch segments {
        case ["notes"]: self = .notes
        case ["notes", "new"]: self = .newNote
        case let path where path.count == 2 && path[0] == "notes": self = .note(id: path[1])
        default: return nil
        }
    }
}

@MainActor
@Observable
final class Router {
    var path: [Note.ID] = []
    var isAddingNote = false

    func open(_ route: AppRoute) {
        isAddingNote = false
        switch route {
        case .notes:
            path = []
        case .note(let id):
            path = [id]
        case .newNote:
            path = []
            isAddingNote = true
        }
    }
}
