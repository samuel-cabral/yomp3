import Foundation

struct PlaylistResolver {
    func resolve(_ url: URL) async throws -> [URL] {
        guard let backendBase = Toolchain.backendURL() else {
            throw AppError.toolchainMissing("Backend URL não configurada")
        }

        var components = URLComponents(url: backendBase.appendingPathComponent("api/playlist"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "url", value: url.absoluteString)]
        guard let requestURL = components.url else {
            throw AppError.playlistResolutionFailed("URL de requisição inválida")
        }

        let (data, response) = try await URLSession.shared.data(from: requestURL)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AppError.playlistResolutionFailed("Servidor retornou erro")
        }

        let result = try JSONDecoder().decode(PlaylistResponse.self, from: data)
        let urls = result.urls.compactMap { URL(string: $0) }
        return urls.isEmpty ? [url] : urls
    }
}

private struct PlaylistResponse: Decodable {
    let urls: [String]
}
