import AppKit
import SwiftUI

struct URLInputView: View {
    @EnvironmentObject private var queue: DownloadQueue
    @State private var input: String = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("URL do YouTube")
                .font(.headline)

            TextField("https://youtube.com/watch?v=…", text: $input)
                .textFieldStyle(.roundedBorder)
                .onSubmit(addToQueue)

            HStack {
                Button("Colar", action: paste)
                Button("Adicionar à fila", action: addToQueue)
                    .keyboardShortcut(.defaultAction)
                    .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Spacer()
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
    }

    private func paste() {
        if let pasted = NSPasteboard.general.string(forType: .string) {
            input = pasted
            errorMessage = nil
        }
    }

    private func addToQueue() {
        guard let (url, kind) = classifyYouTubeURL(input) else {
            errorMessage = "URL inválida"
            return
        }

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
            errorMessage = "URL inválida"
            return
        }

        input = ""
        errorMessage = nil
    }
}
