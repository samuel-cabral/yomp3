import Foundation

enum PreferencesKey {
    static let outputDirectory = "yomp3.outputDirectory"
    static let maxParallelDownloads = "yomp3.maxParallelDownloads"
    static let autoCleanupCompleted = "yomp3.autoCleanupCompleted"
}

enum Preferences {
    static var outputDirectory: URL {
        if let path = UserDefaults.standard.string(forKey: PreferencesKey.outputDirectory) {
            return URL(fileURLWithPath: path)
        }
        let music = FileManager.default.urls(for: .musicDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Music")
        return music.appendingPathComponent("yomp3")
    }

    static var maxParallelDownloads: Int {
        let v = UserDefaults.standard.integer(forKey: PreferencesKey.maxParallelDownloads)
        return v > 0 ? v : 2
    }
}
