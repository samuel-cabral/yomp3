import Foundation
import os

enum Toolchain {
    static func ytDlpPath() -> URL? { resolve(binary: "yt-dlp") }
    static func ffmpegPath() -> URL? { resolve(binary: "ffmpeg") }

    /// Clears the memoized lookup so callers re-search after the user installs a missing tool.
    static func refresh() {
        cacheLock.withLock { $0.removeAll() }
    }

    // MARK: - Internals

    private static let cacheLock = OSAllocatedUnfairLock<[String: URL?]>(initialState: [:])

    private static func resolve(binary: String) -> URL? {
        if let cached = cacheLock.withLock({ $0[binary] }) {
            return cached
        }
        let resolved = search(binary: binary)
        cacheLock.withLock { $0[binary] = resolved }
        return resolved
    }

    private static func search(binary: String) -> URL? {
        var seen = Set<String>()
        var candidates: [String] = [
            "/opt/homebrew/bin/\(binary)",
            "/usr/local/bin/\(binary)",
            "/usr/bin/\(binary)",
        ]
        let pathEnv = ProcessInfo.processInfo.environment["PATH"] ?? ""
        for dir in pathEnv.split(separator: ":") where !dir.isEmpty {
            candidates.append("\(dir)/\(binary)")
        }
        for path in candidates {
            guard seen.insert(path).inserted else { continue }
            if FileManager.default.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        return nil
    }
}
