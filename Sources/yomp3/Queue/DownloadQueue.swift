import Combine
import Foundation

@MainActor
final class DownloadQueue: ObservableObject {
    @Published private(set) var items: [DownloadItem] = []

    @discardableResult
    func enqueue(_ url: URL) -> DownloadItem {
        let item = DownloadItem(sourceURL: url)
        items.append(item)
        return item
    }

    func update(_ id: UUID, mutate: (inout DownloadItem) -> Void) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        mutate(&items[idx])
    }

    func remove(_ id: UUID) {
        items.removeAll { $0.id == id }
    }
}
