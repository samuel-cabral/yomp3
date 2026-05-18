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
            guard let ytDlpURL = toolchain.ytDlpPath() else {
                continuation.finish(throwing: AppError.toolchainMissing("yt-dlp not found"))
                return
            }
            if format.requiresFFmpeg, toolchain.ffmpegPath() == nil {
                continuation.finish(throwing: AppError.toolchainMissing("ffmpeg required for \(format.rawValue) output — install with: brew install ffmpeg"))
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

            var args: [String] = []
            switch format {
            case .original:
                args.append(contentsOf: ["-f", "bestaudio[ext=m4a]/bestaudio"])
            case .m4a:
                args.append(contentsOf: ["-f", "bestaudio", "-x", "--audio-format", "m4a"])
            case .mp3:
                args.append(contentsOf: ["-f", "bestaudio", "-x", "--audio-format", "mp3", "--audio-quality", "0"])
            case .wav:
                args.append(contentsOf: ["-f", "bestaudio", "-x", "--audio-format", "wav"])
            }
            args.append(contentsOf: [
                "--no-playlist",
                "--embed-metadata",
                "--newline",
                "--progress-template", "PROGRESS:%(progress._percent_str)s|%(progress._speed_str)s|%(progress._eta_str)s|%(progress._total_bytes_str)s",
                "--print", "after_move:DONE:%(filepath)s",
                "-o", "\(outputDir.path)/\(template).%(ext)s",
                url.absoluteString
            ])
            process.arguments = args

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
                        let payload = String(t.dropFirst("PROGRESS:".count))
                        let fields = payload
                            .split(separator: "|", omittingEmptySubsequences: false)
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                        let pctStr = (fields.first ?? "")
                            .replacingOccurrences(of: "%", with: "")
                            .trimmingCharacters(in: .whitespaces)
                        guard let pct = Double(pctStr) else {
                            Log.runner.debug("progress parse failed: \(t, privacy: .public)")
                            continue
                        }
                        let speed = fields.count > 1 ? Self.normalizeField(fields[1]) : nil
                        let eta = fields.count > 2 ? Self.normalizeField(fields[2]) : nil
                        let totalBytes = fields.count > 3 ? Self.normalizeField(fields[3]) : nil
                        continuation.yield(.progress(percent: pct / 100.0, speed: speed, eta: eta, totalBytes: totalBytes))
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

    private static func normalizeField(_ s: String) -> String? {
        guard !s.isEmpty, s != "NA", s != "N/A" else { return nil }
        return s
    }
}
