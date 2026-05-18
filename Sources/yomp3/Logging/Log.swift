import OSLog

enum Log {
    static let queue        = Logger(subsystem: "com.samuelcabral.yomp3", category: "queue")
    static let orchestrator = Logger(subsystem: "com.samuelcabral.yomp3", category: "orchestrator")
    static let runner       = Logger(subsystem: "com.samuelcabral.yomp3", category: "runner")
    static let playlist     = Logger(subsystem: "com.samuelcabral.yomp3", category: "playlist")
    static let notifications = Logger(subsystem: "com.samuelcabral.yomp3", category: "notifications")
}
