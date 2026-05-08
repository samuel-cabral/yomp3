import Combine
import Foundation

@MainActor
final class DownloadOrchestrator: ObservableObject {
    private let queue: DownloadQueue
    private let runner: YtDlpRunner
    private let maxParallel: Int

    init(queue: DownloadQueue, runner: YtDlpRunner, maxParallel: Int = 2) {
        self.queue = queue
        self.runner = runner
        self.maxParallel = maxParallel
    }

    func start() {
        // Worker 4 implementa: observa queue.items, dispara YtDlpRunner para cada
        // .queued enquanto inflight.count < maxParallel, atualiza item via queue.update.
    }

    func stop() {
        // Worker 4 implementa: cancela tasks inflight.
    }
}
