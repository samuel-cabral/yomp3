import Foundation

enum DownloadEvent {
    case progress(percent: Double, speed: String?, eta: String?, totalBytes: String?)
    case filename(URL)
    case done(URL)
}

struct YtDlpRunner {
    let toolchain: Toolchain.Type

    func download(
        _ url: URL,
        into outputDir: URL,
        format: AudioFormat,
        template: String
    ) -> AsyncThrowingStream<DownloadEvent, Error> {
        AsyncThrowingStream { continuation in
            guard let backendBase = toolchain.backendURL() else {
                continuation.finish(throwing: AppError.toolchainMissing("Backend URL não configurada — defina nas Configurações"))
                return
            }

            do {
                try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
            } catch {
                continuation.finish(throwing: AppError.downloadFailed("Não foi possível criar diretório de saída: \(error.localizedDescription)"))
                return
            }

            var components = URLComponents(url: backendBase.appendingPathComponent("api/download"), resolvingAgainstBaseURL: false)!
            components.queryItems = [
                URLQueryItem(name: "url", value: url.absoluteString),
                URLQueryItem(name: "format", value: format.rawValue),
                URLQueryItem(name: "template", value: template),
            ]
            guard let requestURL = components.url else {
                continuation.finish(throwing: AppError.downloadFailed("URL de requisição inválida"))
                return
            }

            let session = URLSession.shared
            let task = session.downloadTask(with: requestURL) { tempURL, response, error in
                if let error = error {
                    if (error as NSError).code == NSURLErrorCancelled { return }
                    continuation.finish(throwing: AppError.downloadFailed(error.localizedDescription))
                    return
                }
                guard let tempURL,
                      let http = response as? HTTPURLResponse else {
                    continuation.finish(throwing: AppError.downloadFailed("Sem resposta do servidor"))
                    return
                }
                guard http.statusCode == 200 else {
                    continuation.finish(throwing: AppError.downloadFailed("Erro do servidor: HTTP \(http.statusCode)"))
                    return
                }

                let filename = Self.filename(from: http) ?? "\(UUID().uuidString).m4a"
                let destURL = outputDir.appendingPathComponent(filename)
                do {
                    if FileManager.default.fileExists(atPath: destURL.path) {
                        try FileManager.default.removeItem(at: destURL)
                    }
                    try FileManager.default.moveItem(at: tempURL, to: destURL)
                    continuation.yield(.done(destURL))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: AppError.downloadFailed("Falha ao salvar arquivo: \(error.localizedDescription)"))
                }
            }

            let observation = task.progress.observe(\.fractionCompleted) { progress, _ in
                let total = progress.totalUnitCount > 0
                    ? ByteCountFormatter.string(fromByteCount: progress.totalUnitCount, countStyle: .file)
                    : nil
                continuation.yield(.progress(
                    percent: progress.fractionCompleted,
                    speed: nil,
                    eta: nil,
                    totalBytes: total
                ))
            }

            continuation.onTermination = { _ in
                task.cancel()
                observation.invalidate()
            }

            task.resume()
        }
    }

    private static func filename(from response: HTTPURLResponse) -> String? {
        guard let disposition = response.value(forHTTPHeaderField: "Content-Disposition") else { return nil }
        for part in disposition.components(separatedBy: ";") {
            let t = part.trimmingCharacters(in: .whitespaces)
            if t.hasPrefix("filename=") {
                return String(t.dropFirst("filename=".count))
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            }
        }
        return nil
    }
}
