import Foundation

// On iOS, there are no local binaries. Toolchain wraps the configured backend URL.
enum Toolchain {
    static func backendURL() -> URL? {
        guard let raw = Preferences.backendURL, !raw.isEmpty,
              let url = URL(string: raw) else { return nil }
        return url
    }

    // Kept for API compatibility — always nil on iOS.
    static func ytDlpPath() -> URL? { nil }
    static func ffmpegPath() -> URL? { nil }

    static func refresh() {}

    static func checkReachable() async -> Bool {
        guard let base = backendURL() else { return false }
        let healthURL = base.appendingPathComponent("health")
        var request = URLRequest(url: healthURL)
        request.timeoutInterval = 5
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
}
