import Foundation

struct DownloadItem: Identifiable, Codable, Equatable {
    enum Status: Codable, Equatable {
        case queued
        case downloading(progress: Double, speed: String?, eta: String?, totalBytes: String?)
        case done(URL)
        case failed(String)

        // Mirrors the auto-synthesized CodingKeys so the custom decoder reads
        // the exact same JSON shape produced by Swift's default encoder. Keeping
        // the synthesized encode(to:) untouched guarantees byte-equivalent
        // round-trip for known cases; only init(from:) is overridden so that
        // unknown future cases (e.g. .cancelled, .paused) fall back to .queued
        // instead of throwing — older builds can safely read newer queue.json.
        private enum CodingKeys: String, CodingKey {
            case queued
            case downloading
            case done
            case failed
        }

        private enum DownloadingKeys: String, CodingKey {
            case progress
            case speed
            case eta
            case totalBytes
        }

        private enum SingleValueKeys: String, CodingKey {
            case _0
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            guard let key = container.allKeys.first else {
                self = .queued
                return
            }
            switch key {
            case .queued:
                self = .queued
            case .downloading:
                let nested = try container.nestedContainer(keyedBy: DownloadingKeys.self, forKey: .downloading)
                let progress = try nested.decode(Double.self, forKey: .progress)
                let speed = try nested.decodeIfPresent(String.self, forKey: .speed)
                let eta = try nested.decodeIfPresent(String.self, forKey: .eta)
                let totalBytes = try nested.decodeIfPresent(String.self, forKey: .totalBytes)
                self = .downloading(progress: progress, speed: speed, eta: eta, totalBytes: totalBytes)
            case .done:
                let nested = try container.nestedContainer(keyedBy: SingleValueKeys.self, forKey: .done)
                let url = try nested.decode(URL.self, forKey: ._0)
                self = .done(url)
            case .failed:
                let nested = try container.nestedContainer(keyedBy: SingleValueKeys.self, forKey: .failed)
                let message = try nested.decode(String.self, forKey: ._0)
                self = .failed(message)
            }
        }
    }

    let id: UUID
    var sourceURL: URL
    var title: String
    var status: Status
    var addedAt: Date

    init(
        id: UUID = UUID(),
        sourceURL: URL,
        title: String = "",
        status: Status = .queued,
        addedAt: Date = .now
    ) {
        self.id = id
        self.sourceURL = sourceURL
        self.title = title.isEmpty ? sourceURL.absoluteString : title
        self.status = status
        self.addedAt = addedAt
    }
}
