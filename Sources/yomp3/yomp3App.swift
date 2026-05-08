import SwiftUI

@main
struct YoMP3App: App {
    @StateObject private var queue: DownloadQueue
    @StateObject private var orchestrator: DownloadOrchestrator
    private let runner: YtDlpRunner

    init() {
        let q = DownloadQueue()
        let r = YtDlpRunner(toolchain: Toolchain.self)
        _queue = StateObject(wrappedValue: q)
        runner = r
        _orchestrator = StateObject(wrappedValue: DownloadOrchestrator(queue: q, runner: r))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(queue)
                .environmentObject(orchestrator)
                .onAppear { orchestrator.start() }
        }
        .windowResizability(.contentSize)
    }
}
