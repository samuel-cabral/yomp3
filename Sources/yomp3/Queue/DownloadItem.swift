import Foundation

struct DownloadItem: Identifiable, Codable, Equatable {
    enum Status: Codable, Equatable {
        case queued
        case downloading(progress: Double)
        case done(URL)
        case failed(String)
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
