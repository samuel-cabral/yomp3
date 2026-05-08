import Foundation

enum URLKind {
    case video
    case playlist
    case unknown
}

func classifyYouTubeURL(_ s: String) -> (URL, URLKind)? {
    let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let url = URL(string: trimmed) else { return nil }
    return (url, .unknown)
}
