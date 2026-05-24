import Foundation

// Shared URLSession configured for background downloads.
// The delegate handles completion events that arrive after the app wakes.
final class BackgroundSessionDelegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    static let shared = BackgroundSessionDelegate()

    private var completions: [Int: (URL?, URLResponse?, Error?) -> Void] = [:]
    private let lock = NSLock()

    func register(taskIdentifier: Int, handler: @escaping (URL?, URLResponse?, Error?) -> Void) {
        lock.withLock { completions[taskIdentifier] = handler }
    }

    func unregister(taskIdentifier: Int) {
        lock.withLock { completions.removeValue(forKey: taskIdentifier) }
    }

    // MARK: - URLSessionDownloadDelegate

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let tempCopy: URL
        do {
            let tmp = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(location.pathExtension)
            try FileManager.default.copyItem(at: location, to: tmp)
            tempCopy = tmp
        } catch {
            let handler = lock.withLock { completions[downloadTask.taskIdentifier] }
            handler?(nil, downloadTask.response, error)
            return
        }
        let handler = lock.withLock { completions[downloadTask.taskIdentifier] }
        handler?(tempCopy, downloadTask.response, nil)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            let handler = lock.withLock { completions[task.taskIdentifier] }
            handler?(nil, task.response, error)
        }
        lock.withLock { completions.removeValue(forKey: task.taskIdentifier) }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        // Progress is handled via KVO on task.progress in YtDlpRunner
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            BackgroundSession.backgroundSessionCompletionHandler?()
            BackgroundSession.backgroundSessionCompletionHandler = nil
        }
    }
}

enum BackgroundSession {
    static let identifier = "com.samuelcabral.yomp3.downloads"

    static var backgroundSessionCompletionHandler: (() -> Void)?

    static let session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: identifier)
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        return URLSession(configuration: config, delegate: BackgroundSessionDelegate.shared, delegateQueue: nil)
    }()
}
