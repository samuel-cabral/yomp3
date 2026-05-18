import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                URLInputView()
                ToolchainBanner()
                Spacer()
            }
            .frame(minWidth: 280)
        } detail: {
            DownloadListView()
                .frame(minWidth: 480, minHeight: 360)
        }
    }
}
