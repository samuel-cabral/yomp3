import Foundation

struct PlaylistResolver {
    func resolve(_ url: URL) async throws -> [URL] {
        throw AppError.notImplemented("PlaylistResolver.resolve")
    }
}
