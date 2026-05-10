import Foundation

enum PreferencesKey {
    static let outputDirectory = "yomp3.outputDirectory"
    static let maxParallelDownloads = "yomp3.maxParallelDownloads"
    static let autoCleanupCompleted = "yomp3.autoCleanupCompleted"
}

enum Preferences {
    static var outputDirectory: URL {
        get {
            if let path = UserDefaults.standard.string(forKey: PreferencesKey.outputDirectory) {
                return URL(fileURLWithPath: path)
            }
            let music = FileManager.default.urls(for: .musicDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Music")
            return music.appendingPathComponent("yomp3")
        }
        set {
            UserDefaults.standard.set(newValue.path, forKey: PreferencesKey.outputDirectory)
        }
    }

    static var maxParallelDownloads: Int {
        get {
            let v = UserDefaults.standard.integer(forKey: PreferencesKey.maxParallelDownloads)
            return v > 0 ? v : 2
        }
        set {
            UserDefaults.standard.set(min(max(newValue, 1), 5), forKey: PreferencesKey.maxParallelDownloads)
        }
    }

    static var autoCleanupCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: PreferencesKey.autoCleanupCompleted) }
        set { UserDefaults.standard.set(newValue, forKey: PreferencesKey.autoCleanupCompleted) }
    }
}
