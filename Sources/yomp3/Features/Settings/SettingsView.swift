import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Configurações")
                .font(.title2)
            Text("Em construção")
                .foregroundStyle(.secondary)
            Spacer()
            Button("Fechar") { dismiss() }
        }
        .padding()
    }
}
