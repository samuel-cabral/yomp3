import SwiftUI

struct DownloadListView: View {
    @EnvironmentObject private var queue: DownloadQueue

    var body: some View {
        Group {
            if queue.items.isEmpty {
                ContentUnavailableView(
                    "Nenhum download",
                    systemImage: "tray",
                    description: Text("Cole uma URL do YouTube na barra lateral.")
                )
            } else {
                List {
                    ForEach(queue.items) { item in
                        DownloadRowView(item: item)
                            .environmentObject(queue)
                    }
                }
                .toolbar {
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
        }
    }
}
