import Foundation

enum DownloadEvent {
    case progress(Double)
    case filename(URL)
    case done(URL)
}

struct YtDlpRunner {
    let toolchain: Toolchain.Type

    func download(_ url: URL, into outputDir: URL) -> AsyncThrowingStream<DownloadEvent, Error> {
        AsyncThrowingStream { continuation in
            guard let ytDlpURL = toolchain.ytDlpPath() else {
                continuation.finish(throwing: AppError.toolchainMissing("yt-dlp not found"))
                return
            }
            do {
                try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
            } catch {
                continuation.finish(throwing: AppError.downloadFailed("Cannot create output dir: \(error.localizedDescription)"))
                return
            }

            let process = Process()
            process.executableURL = ytDlpURL
            process.arguments = [
                "-f", "bestaudio[ext=m4a]/bestaudio",
                "--no-playlist",
                "--embed-metadata",
                "--newline",
                "--progress-template", "PROGRESS:%(progress._percent_str)s",
                "--print", "after_move:DONE:%(filepath)s",
                "-o", "\(outputDir.path)/%(title)s.%(ext)s",
                url.absoluteString
            ]

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            continuation.onTermination = { _ in process.terminate() }

            var stderrCollected = Data()

            process.terminationHandler = { proc in
                stderrPipe.fileHandleForReading.readabilityHandler = nil
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                if proc.terminationStatus != 0 {
                    let msg = String(data: stderrCollected, encoding: .utf8) ?? "yt-dlp failed"
                    continuation.finish(throwing: AppError.downloadFailed(msg))
                } else {
                    continuation.finish()
                }
            }

            stderrPipe.fileHandleForReading.readabilityHandler = { h in
                stderrCollected.append(h.availableData)
            }

            var stdoutBuffer = ""
            stdoutPipe.fileHandleForReading.readabilityHandler = { h in
                let data = h.availableData
                guard !data.isEmpty, let chunk = String(data: data, encoding: .utf8) else { return }
                stdoutBuffer += chunk
                var lines = stdoutBuffer.components(separatedBy: "\n")
                stdoutBuffer = lines.removeLast()
                for line in lines {
                    let t = line.trimmingCharacters(in: .whitespaces)
                    if t.hasPrefix("PROGRESS:") {
                        let pctStr = t.dropFirst("PROGRESS:".count).trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "%", with: "")
                        if let pct = Double(pctStr) { continuation.yield(.progress(pct / 100.0)) } else { Log.runner.debug("progress parse failed: \(t, privacy: .public)") }
                    } else if t.hasPrefix("DONE:") {
                        let path = String(t.dropFirst("DONE:".count))
                        continuation.yield(.done(URL(fileURLWithPath: path)))
                    }
                }
            }

            do {
                try process.run()
            } catch {
                continuation.finish(throwing: AppError.downloadFailed(error.localizedDescription))
            }
        }
    }
}
