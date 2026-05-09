import Foundation

struct PlaylistResolver {
    func resolve(_ url: URL) async throws -> [URL] {
        guard let ytDlpURL = Toolchain.ytDlpPath() else {
            throw AppError.toolchainMissing("yt-dlp not found")
        }

        let process = Process()
        process.executableURL = ytDlpURL
        process.arguments = ["--flat-playlist", "--dump-single-json", "--no-warnings", url.absoluteString]

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { proc in
                let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

                if proc.terminationStatus != 0 {
                    let msg = String(data: stderrData, encoding: .utf8) ?? "yt-dlp failed"
                    continuation.resume(throwing: AppError.playlistResolutionFailed(msg))
                    return
                }

                do {
                    let result = try JSONDecoder().decode(FlatPlaylistJSON.self, from: stdoutData)
                    if let entries = result.entries, !entries.isEmpty {
                        let urls = entries.compactMap { entry -> URL? in
                            guard let id = entry.id, !id.isEmpty else { return nil }
                            return URL(string: "https://www.youtube.com/watch?v=\(id)")
                        }
                        continuation.resume(returning: urls.isEmpty ? [url] : urls)
                    } else {
                        continuation.resume(returning: [url])
                    }
                } catch {
                    continuation.resume(returning: [url])
                }
            }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: AppError.playlistResolutionFailed(error.localizedDescription))
            }
        }
    }
}

private struct FlatPlaylistJSON: Decodable {
    let entries: [PlaylistEntry]?
}

private struct PlaylistEntry: Decodable {
    let id: String?
}
