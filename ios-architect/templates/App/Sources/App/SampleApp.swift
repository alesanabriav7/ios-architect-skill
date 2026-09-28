import SwiftUI

@main
struct SampleApp: App {
    private let launch = LaunchOptions(ProcessInfo.processInfo.environment)
    private let environment: Result<AppEnvironment, any Error>
    @State private var router = Router()

    init() {
        let usePreviewData = launch.usePreviewData
        environment = Result { usePreviewData ? try .preview() : try .live() }
    }

    var body: some Scene {
        WindowGroup {
            switch environment {
            case .success(let environment):
                NotesView(repository: environment.notes, titleSuggester: environment.titleSuggester)
                    .environment(router)
                    .onOpenURL { url in
                        if let route = AppRoute(url: url) { router.open(route) }
                    }
                    .task {
                        if let route = launch.initialRoute { router.open(route) }
                    }
            case .failure:
                ContentUnavailableView(
                    "Can't Open Your Data",
                    systemImage: "externaldrive.badge.exclamationmark",
                    description: Text("Restart the app. If this keeps happening, contact support.")
                )
            }
        }
    }
}

/// Launch contract for screenshots and UI tests:
/// `APP_USE_PREVIEW_DATA=1` seeds fixtures; `APP_INITIAL_ROUTE=<deep link URL>` opens a screen through the deep-link parser.
nonisolated struct LaunchOptions: Sendable {
    let usePreviewData: Bool
    let initialRoute: AppRoute?

    init(_ environment: [String: String]) {
        usePreviewData = environment["APP_USE_PREVIEW_DATA"] == "1"
        initialRoute = environment["APP_INITIAL_ROUTE"].flatMap(URL.init(string:)).flatMap(AppRoute.init(url:))
    }
}
