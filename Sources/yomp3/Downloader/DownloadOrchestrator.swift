import Combine
import Foundation

@MainActor
final class DownloadOrchestrator: ObservableObject {
    private let queue: DownloadQueue
    private let runner: YtDlpRunner
    private let maxParallel: Int

    private var cancellables = Set<AnyCancellable>()
    private var inflightTasks: [UUID: Task<Void, Never>] = [:]

    init(queue: DownloadQueue, runner: YtDlpRunner, maxParallel: Int = 2) {
        self.queue = queue
        self.runner = runner
        self.maxParallel = maxParallel
    }

    func start() {
        queue.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in self?.dispatch(items: items) }
            .store(in: &cancellables)
        dispatch(items: queue.items)
    }

    func stop() {
        for task in inflightTasks.values { task.cancel() }
        inflightTasks.removeAll()
        cancellables.removeAll()
    }

    func cancel(_ id: UUID) {
        Log.orchestrator.info("cancelling \(id, privacy: .public)")
        inflightTasks[id]?.cancel()
        inflightTasks.removeValue(forKey: id)
        queue.update(id) { $0.status = .failed("cancelled") }
    }

    private func dispatch(items: [DownloadItem]) {
        for item in items {
            guard case .queued = item.status else { continue }
            guard !inflightTasks.keys.contains(item.id) else { continue }
            guard inflightTasks.count < maxParallel else { break }

            let id = item.id
            let sourceURL = item.sourceURL
            let task = Task { @MainActor [weak self] in
                guard let self else { return }
                self.queue.update(id) { $0.status = .downloading(progress: 0, speed: nil, eta: nil, totalBytes: nil) }
                do {
                    let outputDir = Preferences.outputDirectory
                    let format = Preferences.audioFormat
                    let template = Preferences.fileNameTemplate
                    for try await event in self.runner.download(sourceURL, into: outputDir, format: format, template: template) {
                        switch event {
                        case .progress(let pct, let speed, let eta, let total):
                            self.queue.update(id) { $0.status = .downloading(progress: pct, speed: speed, eta: eta, totalBytes: total) }
                        case .done(let fileURL):
                            self.queue.update(id) { $0.status = .done(fileURL) }
                        case .filename:
                            break
                        }
                    }
                } catch {
                    self.queue.update(id) { item in
                        // Preserve "cancelled" set by cancel(_:) — yt-dlp's
                        // non-zero exit from termination would otherwise
                        // overwrite it with stderr noise.
                        if case .failed(let msg) = item.status, msg == "cancelled" { return }
                        item.status = .failed(error.localizedDescription)
                    }
                }
                self.inflightTasks.removeValue(forKey: id)
            }
            inflightTasks[id] = task
        }
    }
}
