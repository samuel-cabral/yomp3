import Foundation

enum DownloadEvent {
    case progress(Double)
    case filename(URL)
    case done(URL)
}

struct YtDlpRunner {
    let toolchain: Toolchain.Type

    func download(_ url: URL, into outputDir: URL) -> AsyncThrowingStream<DownloadEvent, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: AppError.notImplemented("YtDlpRunner.download"))
        }
    }
}
