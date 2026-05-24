# YoMP3 — Repository Guide

App iOS (SwiftUI + XcodeGen) que faz download de áudio do YouTube via backend HTTP, para uso com separação de stems no Moises.

## Estrutura

| Diretório | O que vive aqui |
|-----------|------------------|
| `Sources/yomp3/Toolchain/` | BackendBanner — verifica se o backend está acessível |
| `Sources/yomp3/Queue/` | DownloadItem + DownloadQueue (persistência JSON) |
| `Sources/yomp3/Downloader/` | YtDlpRunner (HTTP) + DownloadOrchestrator |
| `Sources/yomp3/Playlist/` | PlaylistResolver (via backend) |
| `Sources/yomp3/Features/URLInput/` | TextField + paste + classificação de URL |
| `Sources/yomp3/Features/DownloadList/` | List view + Row view (presentacional) |
| `Sources/yomp3/Features/Settings/` | SettingsView + Preferences (UserDefaults) |
| `Sources/yomp3/Errors/` | AppError enum |
| `Backend/` | Servidor Python (yt-dlp + FastAPI/Flask) |
| `Scripts/` | build-app.sh, install-iphone.sh |
| `README.md`, `LICENSE` | docs e licença |

## Como rodar (iOS)

Requer Xcode 15+ e XcodeGen (`brew install xcodegen`).

```bash
xcodegen generate           # gera YoMP3.xcodeproj a partir de project.yml
open YoMP3.xcodeproj        # abre no Xcode
```

Para instalar no iPhone:
1. Abra `YoMP3.xcodeproj` no Xcode
2. Em *Signing & Capabilities*, selecione seu Apple ID como Team
3. Conecte o iPhone e selecione-o como destino
4. ⌘R para compilar e instalar

Para instalar no simulador:
```bash
bash Scripts/build-app.sh         # compila para simulador
bash Scripts/install-iphone.sh    # instala em iPhone conectado
```

## Backend

O app delega o download ao backend HTTP. Configure a URL do backend nas Configurações do app.

Endpoints necessários:
| Método | Path | Descrição |
|--------|------|-----------|
| GET | /health | Retorna 200 se vivo |
| GET | /api/download?url=…&format=…&template=… | Retorna arquivo de áudio |
| GET | /api/playlist?url=… | Retorna `{"urls": […]}` |

Para subir o backend local (requer Python 3 + yt-dlp):
```bash
pip install -r Backend/requirements.txt
python3 Backend/server.py
```

## Sobre testes

O projeto requer **Xcode 15+** (não apenas Command Line Tools). Com Xcode instalado, use `xcodegen generate` e abra o `.xcodeproj` para rodar testes no simulador via ⌘U.

Sem Xcode disponível, valide via smoke test: gere o projeto, selecione o simulador como destino, e confirme que a tela principal abre e a feature aparece visualmente.

## Dependências externas

- `xcodegen` (instalar via `brew install xcodegen`) — gerador de projeto Xcode
- Backend Python com `yt-dlp` (ver seção Backend acima)
