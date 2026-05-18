import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct URLInputView: View {
    @EnvironmentObject private var queue: DownloadQueue
    @State private var input: String = ""
    @State private var errorMessage: String?
    @State private var isDropTarget = false

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
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isDropTarget ? Color.accentColor : .clear, lineWidth: 2)
        )
        .onDrop(of: [UTType.url, UTType.plainText], isTargeted: $isDropTarget) { providers in
            handleDrop(providers: providers)
        }
    }

    private func paste() {
        if let pasted = NSPasteboard.general.string(forType: .string) {
            input = pasted
            errorMessage = nil
        }
    }

    private func addToQueue() {
        let tokens = tokenize(input)
        guard !tokens.isEmpty else { return }
        processTokens(tokens)
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard !providers.isEmpty else { return false }

        let collector = DropCollector(expected: providers.count) { strings in
            Task { @MainActor in
                let joined = strings.joined(separator: "\n")
                let tokens = tokenize(joined)
                if tokens.isEmpty {
                    errorMessage = "URL inválida"
                    return
                }
                processTokens(tokens)
            }
        }

        for provider in providers {
            if provider.canLoadObject(ofClass: NSURL.self) {
                provider.loadObject(ofClass: NSURL.self) { item, _ in
                    let s = (item as? URL)?.absoluteString
                    collector.submit(s)
                }
            } else if provider.canLoadObject(ofClass: NSString.self) {
                provider.loadObject(ofClass: NSString.self) { item, _ in
                    let s = (item as? String)
                    collector.submit(s)
                }
            } else {
                collector.submit(nil)
            }
        }
        return true
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
            if !seen.insert(key).inserted {
                continue
            }
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
                for u in urls {
                    queue.enqueue(u)
                }
            }
        case .unknown:
            break
        }
    }
}

private func tokenize(_ s: String) -> [String] {
    s.split(whereSeparator: { $0.isWhitespace })
        .map { String($0) }
}

/// Accumulates async string results from a set of drop providers,
/// then invokes `done` once with whatever non-nil strings arrived.
private final class DropCollector: @unchecked Sendable {
    private let expected: Int
    private var received = 0
    private var strings: [String] = []
    private let lock = NSLock()
    private let done: ([String]) -> Void

    init(expected: Int, done: @escaping ([String]) -> Void) {
        self.expected = expected
        self.done = done
    }

    func submit(_ s: String?) {
        lock.lock()
        if let s, !s.isEmpty { strings.append(s) }
        received += 1
        let finished = received >= expected
        let snapshot = strings
        lock.unlock()
        if finished { done(snapshot) }
    }
}
