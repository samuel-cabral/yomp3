import SwiftUI
import UniformTypeIdentifiers

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
                .keyboardType(.URL)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onSubmit(addToQueue)

            HStack {
                Button("Colar", action: paste)
                Button("Adicionar à fila", action: addToQueue)
                    .buttonStyle(.borderedProminent)
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
        if let pasted = UIPasteboard.general.string {
            input = pasted
            errorMessage = nil
        }
    }

    private func addToQueue() {
        let tokens = tokenize(input)
        guard !tokens.isEmpty else { return }
        processTokens(tokens)
    }

    private func processTokens(_ tokens: [String]) {
        var seen = Set<String>()
        var valid = 0
        var invalid = 0

        for token in tokens {
            guard let (url, kind) = classifyYouTubeURL(token) else {
                invalid += 1
                continue
            }
            let key = url.absoluteString
            if !seen.insert(key).inserted { continue }
            enqueueClassified(url: url, kind: kind)
            valid += 1
        }

        if valid == 0 && invalid > 0 {
            errorMessage = "URL inválida"
        } else if invalid > 0 {
            errorMessage = "\(valid) URLs adicionadas, \(invalid) inválida\(invalid == 1 ? "" : "s")"
            input = ""
        } else {
            errorMessage = nil
            input = ""
        }
    }

    private func enqueueClassified(url: URL, kind: URLKind) {
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

private func tokenize(_ s: String) -> [String] {
    s.split(whereSeparator: { $0.isWhitespace }).map { String($0) }
}
