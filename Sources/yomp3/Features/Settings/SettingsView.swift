import AppKit
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var outputDirectoryPath: String = (Preferences.outputDirectory.path as NSString).abbreviatingWithTildeInPath
    @State private var maxParallel: Int = Preferences.maxParallelDownloads
    @State private var autoCleanup: Bool = Preferences.autoCleanupCompleted

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Pasta de destino") {
                    HStack {
                        Text(outputDirectoryPath)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button("Escolher…") { openFolderPicker() }
                    }
                }
                Section("Downloads") {
                    Stepper("Paralelos: \(maxParallel)", value: $maxParallel, in: 1...5)
                        .onChange(of: maxParallel) { _, newValue in
                            Preferences.maxParallelDownloads = newValue
                        }
                }
                Section("Geral") {
                    Toggle("Limpar completados automaticamente", isOn: $autoCleanup)
                        .onChange(of: autoCleanup) { _, newValue in
                            Preferences.autoCleanupCompleted = newValue
                        }
                }
            }
            .formStyle(.grouped)
            Divider()
            HStack {
                Spacer()
                Button("Fechar") { dismiss() }
                    .keyboardShortcut(.defaultAction)
                    .padding()
            }
        }
        .frame(minWidth: 400, minHeight: 280)
    }

    private func openFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Escolher"
        panel.begin { response in
            if response == .OK, let url = panel.url {
                Preferences.outputDirectory = url
                outputDirectoryPath = (url.path as NSString).abbreviatingWithTildeInPath
            }
        }
    }
}
