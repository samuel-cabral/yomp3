import AppKit
import SwiftUI

struct DownloadRowView: View {
    let item: DownloadItem
    @EnvironmentObject private var queue: DownloadQueue
    @EnvironmentObject private var orchestrator: DownloadOrchestrator

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: statusIcon)
                .foregroundStyle(statusColor)
                .font(.title2)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)
                statusView
            }

            Spacer()

            actionButton
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var statusView: some View {
        switch item.status {
        case .queued:
            Text("Na fila")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .downloading(let p, let speed, let eta, let totalBytes):
            VStack(alignment: .leading, spacing: 2) {
                ProgressView(value: p, total: 1.0)
                Text("\(Int(p * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                let details = [speed, eta, totalBytes].compactMap { $0 }
                if !details.isEmpty {
                    Text(details.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        case .done(let fileURL):
            Text(fileURL.lastPathComponent)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        case .failed(let msg):
            Text(msg)
                .font(.caption)
                .foregroundStyle(.red)
                .lineLimit(2)
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch item.status {
        case .queued:
            Button("Cancelar") { queue.remove(item.id) }
                .buttonStyle(.borderless)
                .foregroundStyle(.red)
        case .downloading:
            Button("Cancelar") { orchestrator.cancel(item.id) }
                .buttonStyle(.borderless)
                .foregroundStyle(.red)
        case .done(let fileURL):
            Button("Revelar") {
                NSWorkspace.shared.activateFileViewerSelecting([fileURL])
            }
            .buttonStyle(.borderless)
        case .failed:
            Button("Repetir") { _ = queue.enqueue(item.sourceURL) }
                .buttonStyle(.borderless)
        }
    }

    private var statusIcon: String {
        switch item.status {
        case .queued: return "arrow.down.circle"
        case .downloading: return "arrow.down.circle.fill"
        case .done: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch item.status {
        case .queued: return .secondary
        case .downloading: return .blue
        case .done: return .green
        case .failed: return .red
        }
    }
}
