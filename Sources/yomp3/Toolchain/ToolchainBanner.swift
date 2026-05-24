import SwiftUI

// Renamed to BackendBanner — checks if the configured backend is reachable.
struct BackendBanner: View {
    @State private var state: BannerState = .checking

    enum BannerState { case checking, ok, notConfigured, unreachable }

    var body: some View {
        Group {
            switch state {
            case .checking, .ok:
                EmptyView()
            case .notConfigured:
                warningCard(
                    message: "Backend não configurado. Defina a URL nas Configurações.",
                    actionLabel: nil
                )
            case .unreachable:
                warningCard(
                    message: "Backend inacessível. Verifique a URL e a rede.",
                    actionLabel: "Tentar novamente"
                )
            }
        }
        .task { await reload() }
    }

    private func warningCard(message: String, actionLabel: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let actionLabel {
                Button(actionLabel) {
                    Task { await reload() }
                }
                .buttonStyle(.borderless)
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.yellow.opacity(0.2))
        .cornerRadius(8)
        .padding(.horizontal)
    }

    private func reload() async {
        guard Preferences.backendURL?.isEmpty == false else {
            state = .notConfigured
            return
        }
        state = .checking
        state = await Toolchain.checkReachable() ? .ok : .unreachable
    }
}
