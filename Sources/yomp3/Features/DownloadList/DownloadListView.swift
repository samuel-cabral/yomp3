import SwiftUI

struct DownloadListView: View {
    @EnvironmentObject private var queue: DownloadQueue

    var body: some View {
        Group {
            if queue.items.isEmpty {
                ContentUnavailableView {
                    Label("Nenhum download", systemImage: "tray")
                } description: {
                    Text("Cole uma URL do YouTube no campo acima.")
                } actions: {
                    Button("Colar do clipboard", action: pasteFromClipboard)
                }
            } else {
                List {
                    ForEach(queue.items) { item in
                        DownloadRowView(item: item)
                            .environmentObject(queue)
                    }
                }
                .listStyle(.plain)
            }
        }
        .toolbar {
            if queue.items.contains(where: {
                if case .done = $0.status { return true }
                if case .failed = $0.status { return true }
                return false
            }) {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Limpar tudo") {
                        for item in queue.items {
                            if case .done = item.status { queue.remove(item.id) }
                            else if case .failed = item.status { queue.remove(item.id) }
                        }
                    }
                    .foregroundStyle(.red)
                }
            }
        }
    }

    private func pasteFromClipboard() {
        guard let pasted = UIPasteboard.general.string else { return }
        let trimmed = pasted.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let (url, kind) = classifyYouTubeURL(trimmed) else { return }
        switch kind {
        case .video:
            queue.enqueue(url)
        case .playlist:
            Task {
                let urls = (try? await PlaylistResolver().resolve(url)) ?? [url]
                for u in urls { queue.enqueue(u) }
            }
        case .unknown:
            break
        }
    }
}
