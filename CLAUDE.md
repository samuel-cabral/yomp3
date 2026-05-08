# YoMP3 — Repository Guide

Small native macOS app (SwiftUI + SwiftPM) that downloads YouTube audio in original quality (no re-encode) for use with Moises stem separation.

## Project Layout

| Diretório | Dono | O que vive aqui |
|-----------|------|------------------|
| `Sources/yomp3/Toolchain/` | Worker 2 | Detecção de yt-dlp e ffmpeg + banner de aviso |
| `Sources/yomp3/Queue/` | Worker 3 | DownloadItem + DownloadQueue (persistência JSON) |
| `Sources/yomp3/Downloader/` | Worker 4 | YtDlpRunner (Process) + DownloadOrchestrator |
| `Sources/yomp3/Playlist/` | Worker 5 | PlaylistResolver (yt-dlp --flat-playlist) |
| `Sources/yomp3/Features/URLInput/` | Worker 1 | TextField + paste + classificação de URL |
| `Sources/yomp3/Features/DownloadList/` | Worker 6 | List view + Row view (presentational only) |
| `Sources/yomp3/Features/Settings/` | Worker 7 | SettingsView + Preferences (UserDefaults) |
| `Sources/yomp3/Errors/` | shared | AppError enum (workers podem adicionar cases) |
| `Scripts/` | Worker 8 | build-app.sh, package-dmg.sh |
| `README.md`, `LICENSE` | Worker 9 | docs e licença |

## Arquivos-tronco — NÃO MODIFICAR

Os seguintes arquivos compõem a estrutura do app inteiro. Workers individuais NÃO devem editá-los — se você acha que algo precisa mudar, reporte no PR description em vez de editar:

- `Package.swift`
- `Sources/yomp3/yomp3App.swift`
- `Sources/yomp3/ContentView.swift`
- `Resources/Info.plist`
- `Resources/yomp3.entitlements`

Também **não modifique** assinaturas de API pública em diretório de outro worker — só implemente o miolo dos seus próprios stubs preservando a API.

## APIs estáveis

Os tipos abaixo estão definidos como stubs no scaffold. Workers preservam a assinatura pública e implementam o corpo:

- `Toolchain.ytDlpPath() -> URL?` / `Toolchain.ffmpegPath() -> URL?`
- `DownloadItem` (modelo, não muda)
- `DownloadQueue.enqueue(_:)`, `.update(_:mutate:)`, `.remove(_:)`, `@Published items`
- `YtDlpRunner.download(_:into:) -> AsyncThrowingStream<DownloadEvent, Error>`
- `DownloadEvent` enum (`.progress`, `.filename`, `.done`)
- `DownloadOrchestrator.init(queue:runner:maxParallel:)`, `.start()`, `.stop()`
- `PlaylistResolver.resolve(_:) async throws -> [URL]`
- `classifyYouTubeURL(_:) -> (URL, URLKind)?`
- `AppError` (workers podem adicionar novos cases conforme necessário)

## Como rodar

```bash
swift build           # compila
bash Scripts/build-app.sh && open build/YoMP3.app   # roda como .app (necessário para SwiftUI window)
```

`swift run yomp3` direto **não** abre janela confiavelmente em macOS — sempre use o bundle `.app`.

## Sobre testes

Esta máquina tem apenas **Command Line Tools** (sem Xcode completo), então `XCTest` e `swift-testing` não estão disponíveis. O scaffold **não inclui test target** no `Package.swift`. Workers que quiserem testar lógica pura podem:

1. Adicionar funções `assert*` em código `#if DEBUG` chamadas de um sub-comando do binário, OU
2. Adicionar test target ao `Package.swift` apenas se Xcode estiver instalado (worker reporta no PR), OU
3. Pular testes unitários e validar via smoke test do `.app` (preferido para esta versão).

A prova de funcionamento é: `bash Scripts/build-app.sh && open build/YoMP3.app` abre janela e a feature aparece visualmente.

## Dependências externas

- `yt-dlp` (instalar via `brew install yt-dlp`)
- `ffmpeg` (instalar via `brew install ffmpeg`)

O app detecta esses binários em `/opt/homebrew/bin`, `/usr/local/bin`, ou `$PATH`.
