import SwiftUI

struct SettingsView: View {
    @State private var backendURL: String = Preferences.backendURL ?? ""
    @State private var maxParallel: Int = Preferences.maxParallelDownloads
    @State private var autoCleanup: Bool = Preferences.autoCleanupCompleted
    @State private var audioFormat: AudioFormat = Preferences.audioFormat
    @State private var fileNameTemplate: String = Preferences.fileNameTemplate
    @State private var backendStatus: String? = nil
    @State private var isCheckingBackend = false

    var body: some View {
        Form {
            Section("Backend") {
                TextField("http://192.168.1.100:8080", text: $backendURL)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: backendURL) { _, v in
                        Preferences.backendURL = v.isEmpty ? nil : v
                        backendStatus = nil
                    }
                Button {
                    checkBackend()
                } label: {
                    if isCheckingBackend {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                    } else {
                        Text("Verificar conexão")
                    }
                }
                .disabled(backendURL.isEmpty || isCheckingBackend)

                if let status = backendStatus {
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(status.hasPrefix("✓") ? .green : .red)
                }
            }

            Section("Downloads") {
                Stepper("Paralelos: \(maxParallel)", value: $maxParallel, in: 1...5)
                    .onChange(of: maxParallel) { _, v in Preferences.maxParallelDownloads = v }

                Picker("Formato", selection: $audioFormat) {
                    ForEach(AudioFormat.allCases) { format in
                        Text(format.displayName).tag(format)
                    }
                }
                .onChange(of: audioFormat) { _, v in Preferences.audioFormat = v }

                Picker("Padrão de nome", selection: $fileNameTemplate) {
                    Text("Apenas título").tag("%(title)s")
                    Text("Canal - Título").tag("%(uploader)s - %(title)s")
                    Text("Pasta por playlist").tag("%(playlist)s/%(title)s")
                }
                .onChange(of: fileNameTemplate) { _, v in Preferences.fileNameTemplate = v }
            }

            Section("Geral") {
                Toggle("Limpar completados automaticamente", isOn: $autoCleanup)
                    .onChange(of: autoCleanup) { _, v in Preferences.autoCleanupCompleted = v }
            }
        }
    }

    private func checkBackend() {
        isCheckingBackend = true
        Task {
            let ok = await Toolchain.checkReachable()
            backendStatus = ok ? "✓ Backend acessível" : "✗ Não foi possível conectar"
            isCheckingBackend = false
        }
    }
}
