import Foundation

enum Toolchain {
    static func ytDlpPath() -> URL? {
        candidatePaths(for: "yt-dlp").first
    }

    static func ffmpegPath() -> URL? {
        candidatePaths(for: "ffmpeg").first
    }

    private static func candidatePaths(for binary: String) -> [URL] {
        let candidates = [
            "/opt/homebrew/bin/\(binary)",
            "/usr/local/bin/\(binary)",
            "/usr/bin/\(binary)",
        ]
        return candidates.compactMap { path in
            FileManager.default.isExecutableFile(atPath: path)
                ? URL(fileURLWithPath: path)
                : nil
        }
    }
}
