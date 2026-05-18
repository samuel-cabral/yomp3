import AppKit
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var outputDirectoryPath: String = (Preferences.outputDirectory.path as NSString).abbreviatingWithTildeInPath
    @State private var maxParallel: Int = Preferences.maxParallelDownloads
    @State private var autoCleanup: Bool = Preferences.autoCleanupCompleted
    @State private var audioFormat: AudioFormat = Preferences.audioFormat
    @State private var fileNameTemplate: String = Preferences.fileNameTemplate

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
                Section("Formato de saída") {
                    Picker("Formato", selection: $audioFormat) {
                        ForEach(AudioFormat.allCases) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .onChange(of: audioFormat) { _, newValue in
                        Preferences.audioFormat = newValue
                    }
                    Picker("Padrão de nome", selection: $fileNameTemplate) {
                        Text("Apenas título").tag("%(title)s")
                        Text("Canal - Título").tag("%(uploader)s - %(title)s")
                        Text("Pasta por playlist").tag("%(playlist)s/%(title)s")
                    }
                    .onChange(of: fileNameTemplate) { _, newValue in
                        Preferences.fileNameTemplate = newValue
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
        .frame(minWidth: 400, minHeight: 320)
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
