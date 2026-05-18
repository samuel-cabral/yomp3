import Foundation
import UserNotifications

/// Thin wrapper around UNUserNotificationCenter for download lifecycle notifications.
/// Authorization is requested lazily on first use; if denied, subsequent calls are no-ops.
enum DownloadNotifier {
    private static var authorizationChecked = false

    private static func requestAuthorizationIfNeeded() async -> Bool {
        if authorizationChecked { return true }
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            authorizationChecked = true
            if !granted {
                Log.notifications.info("user denied notification authorization")
            }
            return granted
        } catch {
            Log.notifications.error("authorization request failed: \(error.localizedDescription, privacy: .public)")
            authorizationChecked = true
            return false
        }
    }

    /// Posts a notification announcing a successful download.
    static func notifySuccess(title: String, fileURL: URL) async {
        guard await requestAuthorizationIfNeeded() else { return }
        let content = UNMutableNotificationContent()
        content.title = "Download concluído"
        content.body = title
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            Log.notifications.error("post success failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Posts a notification announcing a failed download.
    static func notifyFailure(title: String, errorMessage: String) async {
        guard await requestAuthorizationIfNeeded() else { return }
        let content = UNMutableNotificationContent()
        content.title = "Download falhou"
        content.body = "\(title): \(errorMessage)"
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            Log.notifications.error("post failure failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
