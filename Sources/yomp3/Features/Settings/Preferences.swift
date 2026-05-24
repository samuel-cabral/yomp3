import Foundation

enum PreferencesKey {
    static let outputDirectory = "yomp3.outputDirectory"
    static let maxParallelDownloads = "yomp3.maxParallelDownloads"
    static let autoCleanupCompleted = "yomp3.autoCleanupCompleted"
    static let audioFormat = "yomp3.audioFormat"
    static let fileNameTemplate = "yomp3.fileNameTemplate"
    static let backendURL = "yomp3.backendURL"
}

enum AudioFormat: String, CaseIterable, Identifiable {
    case original, m4a, mp3, wav

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .original: return "Original (sem reencode — recomendado p/ Moises)"
        case .m4a: return "M4A (AAC)"
        case .mp3: return "MP3 (320 kbps)"
        case .wav: return "WAV"
        }
    }

    var requiresFFmpeg: Bool { self != .original }
}

enum Preferences {
    static var outputDirectory: URL {
        get {
            if let path = UserDefaults.standard.string(forKey: PreferencesKey.outputDirectory) {
                return URL(fileURLWithPath: path)
            }
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                .appendingPathComponent("Downloads")
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

    static var audioFormat: AudioFormat {
        get {
            guard let raw = UserDefaults.standard.string(forKey: PreferencesKey.audioFormat),
                  let f = AudioFormat(rawValue: raw) else { return .original }
            return f
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: PreferencesKey.audioFormat) }
    }

    static var fileNameTemplate: String {
        get { UserDefaults.standard.string(forKey: PreferencesKey.fileNameTemplate) ?? "%(title)s" }
        set { UserDefaults.standard.set(newValue, forKey: PreferencesKey.fileNameTemplate) }
    }

    static var backendURL: String? {
        get { UserDefaults.standard.string(forKey: PreferencesKey.backendURL) }
        set { UserDefaults.standard.set(newValue, forKey: PreferencesKey.backendURL) }
    }
}
