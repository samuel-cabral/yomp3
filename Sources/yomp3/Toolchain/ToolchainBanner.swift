import SwiftUI

struct ToolchainBanner: View {
    @State private var ytDlpFound: Bool = true
    @State private var ffmpegFound: Bool = true
    @State private var didLoad = false

    var body: some View {
        Group {
            if didLoad && !(ytDlpFound && ffmpegFound) {
                warningCard
            } else {
                EmptyView()
            }
        }
        .task { reload() }
    }

    private var warningCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Faltam dependências")
                .font(.headline)

            Text(missingDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            (Text("Instale com ")
                + Text("brew install yt-dlp ffmpeg").font(.system(.subheadline, design: .monospaced)))
                .font(.subheadline)

            Button("Verificar novamente") {
                Toolchain.refresh()
                reload()
            }
            .buttonStyle(.borderless)
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.yellow.opacity(0.2))
        .cornerRadius(8)
        .padding(.horizontal)
    }

    private var missingDescription: String {
        switch (ytDlpFound, ffmpegFound) {
        case (false, false): return "Não foram encontrados: yt-dlp e ffmpeg."
        case (false, true):  return "Não foi encontrado: yt-dlp."
        case (true, false):  return "Não foi encontrado: ffmpeg."
        case (true, true):   return ""
        }
    }

    private func reload() {
        ytDlpFound = Toolchain.ytDlpPath() != nil
        ffmpegFound = Toolchain.ffmpegPath() != nil
        didLoad = true
    }
}
