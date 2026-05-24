import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     handleEventsForBackgroundURLSession identifier: String,
                     completionHandler: @escaping () -> Void) {
        guard identifier == BackgroundSession.identifier else { return }
        BackgroundSession.backgroundSessionCompletionHandler = completionHandler
    }
}

@main
struct YoMP3App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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
    }
}
