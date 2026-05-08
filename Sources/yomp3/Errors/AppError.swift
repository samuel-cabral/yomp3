import Foundation

enum AppError: LocalizedError {
    case notImplemented(String)
    case toolchainMissing(String)
    case invalidURL(String)
    case downloadFailed(String)
    case playlistResolutionFailed(String)

    var errorDescription: String? {
        switch self {
        case .notImplemented(let what): "Não implementado: \(what)"
        case .toolchainMissing(let bin): "Binário ausente: \(bin)"
        case .invalidURL(let s): "URL inválida: \(s)"
        case .downloadFailed(let msg): "Falha no download: \(msg)"
        case .playlistResolutionFailed(let msg): "Falha ao resolver playlist: \(msg)"
        }
    }
}
