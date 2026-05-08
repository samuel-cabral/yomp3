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
                List(queue.items) { item in
                    DownloadRowView(item: item)
                }
            }
        }
    }
}
