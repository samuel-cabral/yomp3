import Foundation

enum URLKind {
    case video
    case playlist
    case unknown
}

func classifyYouTubeURL(_ s: String) -> (URL, URLKind)? {
    let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, let url = URL(string: trimmed) else { return nil }
    guard let host = url.host?.lowercased() else { return nil }

    let path = url.path
    let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
    let hasList = queryItems.contains { $0.name == "list" && !($0.value ?? "").isEmpty }
    let hasV = queryItems.contains { $0.name == "v" && !($0.value ?? "").isEmpty }

    if host.contains("youtube.com") {
        if path == "/playlist" && hasList { return (url, .playlist) }
        if path == "/watch" && hasList { return (url, .playlist) }
        if path == "/watch" && hasV { return (url, .video) }
        return nil
    }

    if host == "youtu.be", path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).isEmpty == false {
        return (url, .video)
    }

    return nil
}
