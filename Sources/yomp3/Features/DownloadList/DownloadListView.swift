import AppKit
import SwiftUI

struct DownloadListView: View {
    @EnvironmentObject private var queue: DownloadQueue

    var body: some View {
        Group {
            if queue.items.isEmpty {
                ContentUnavailableView {
                    Label("Nenhum download", systemImage: "tray")
                } description: {
                    Text("Cole uma URL do YouTube na barra lateral ou clique abaixo.")
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
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    NSWorkspace.shared.open(Preferences.outputDirectory)
                } label: {
                    Label("Abrir pasta", systemImage: "folder")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                if queue.items.contains(where: {
                    if case .done = $0.status { return true }
                    if case .failed = $0.status { return true }
                    return false
                }) {
                    Button("Limpar tudo") {
                        for item in queue.items {
                            if case .done = item.status { queue.remove(item.id) }
                            else if case .failed = item.status { queue.remove(item.id) }
                        }
                    }
                }
            }
        }
    }

    private func pasteFromClipboard() {
        guard let pasted = NSPasteboard.general.string(forType: .string) else { return }
        let trimmed = pasted.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let (url, kind) = classifyYouTubeURL(trimmed) else { return }

        switch kind {
        case .video:
            queue.enqueue(url)
        case .playlist:
            Task {
                let urls = (try? await PlaylistResolver().resolve(url)) ?? [url]
                for u in urls {
                    queue.enqueue(u)
                }
            }
        case .unknown:
            break
        }
    }
}
