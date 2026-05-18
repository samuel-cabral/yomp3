import Combine
import Foundation

@MainActor
final class DownloadQueue: ObservableObject {
    @Published private(set) var items: [DownloadItem] = []

    private let persistenceURL: URL = {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("yomp3/queue.json")
    }()

    private var pendingSaveTask: Task<Void, Never>?

    init() {
        load()
    }

    @discardableResult
    func enqueue(_ url: URL) -> DownloadItem {
        let item = DownloadItem(sourceURL: url)
        items.append(item)
        scheduleSave()
        return item
    }

    func update(_ id: UUID, mutate: (inout DownloadItem) -> Void) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        mutate(&items[idx])
        scheduleSave()
    }

    func remove(_ id: UUID) {
        items.removeAll { $0.id == id }
        scheduleSave()
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: persistenceURL.path) else { return }
        do {
            let data = try Data(contentsOf: persistenceURL)
            var loaded = try JSONDecoder().decode([DownloadItem].self, from: data)
            for idx in loaded.indices {
                if case .downloading = loaded[idx].status {
                    Log.queue.warning("recovered downloading item \(loaded[idx].id, privacy: .public) as queued (crash recovery)")
                    loaded[idx].status = .queued
                }
            }
            items = loaded
        } catch {
            Log.queue.error("load error: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func scheduleSave() {
        pendingSaveTask?.cancel()
        pendingSaveTask = Task {
            do {
                try await Task.sleep(nanoseconds: 500_000_000)
            } catch {
                return
            }
            persist()
        }
    }

    private func persist() {
        do {
            let dir = persistenceURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(items)
            try data.write(to: persistenceURL, options: .atomic)
        } catch {
            Log.queue.error("persist error: \(error.localizedDescription, privacy: .public)")
        }
    }
}
