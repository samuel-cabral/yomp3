import SwiftUI

struct DownloadRowView: View {
    let item: DownloadItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(statusLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var statusLabel: String {
        switch item.status {
        case .queued: "Na fila"
        case .downloading(let p): "Baixando \(Int(p * 100))%"
        case .done: "Pronto"
        case .failed(let msg): "Erro: \(msg)"
        }
    }
}
