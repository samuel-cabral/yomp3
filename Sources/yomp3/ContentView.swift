import SwiftUI

struct ContentView: View {
    @State private var showSettings = false

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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSettings = true
                } label: {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .frame(minWidth: 420, minHeight: 300)
        }
    }
}
