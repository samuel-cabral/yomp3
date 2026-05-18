# YoMP3

YoMP3 é um app nativo para macOS (SwiftUI) que baixa o áudio do YouTube **sem re-encodar** — preservando o stream original M4A/AAC ou WebM/Opus exatamente como o YouTube o serve. Isso é essencial para músicos que usam o [Moises](https://moises.ai/) para separação de stems por IA: qualquer re-encodação adiciona ruído de compressão antes da análise, prejudicando a qualidade da separação. Com YoMP3, o Moises recebe o melhor sinal disponível.

## Download

Baixe a versão mais recente em [Releases](https://github.com/samuel-cabral/yomp3/releases/latest) — arraste `YoMP3.app` para `/Applications`.

> _Primeiro release distribuível ainda não publicado — para já, siga as instruções de [Instalação](#instalação) para compilar do source._

## Requisitos

- macOS 14 (Sonoma) ou mais recente
- `yt-dlp` e `ffmpeg` instalados via Homebrew

## Instalação

1. Instale as dependências:
   ```bash
   brew install yt-dlp ffmpeg
   ```
2. Clone o repositório e compile:
   ```bash
   git clone https://github.com/samuel-cabral/yomp3.git
   cd yomp3
   bash Scripts/build-app.sh
   open build/YoMP3.app
   ```

> **Nota Gatekeeper:** se você distribuir o `.app` para outro Mac e ele for bloqueado, veja [Troubleshooting](#troubleshooting).

## Como usar

1. Cole a URL do YouTube (vídeo ou playlist) no campo de texto
2. Clique **Adicionar**
3. O áudio é baixado em `~/Music/yomp3/` (configurável em Preferências)

## Qualidade do áudio

O YouTube não serve áudio lossless — os streams disponíveis são AAC em torno de 128–256 kbps (M4A) ou Opus em torno de 160 kbps (WebM). O que YoMP3 garante é que **nenhuma geração extra de compressão é adicionada**: o arquivo salvo é byte-a-byte idêntico ao stream que o YouTube entrega. Toda a informação de sinal presente no original chega intacta ao Moises, maximizando a qualidade da separação de stems.

## Formatos de saída

| Formato | Codec | Quando |
|---------|-------|--------|
| `.m4a`  | AAC   | Preferido — disponível na maioria dos vídeos |
| `.webm` | Opus  | Fallback quando M4A não está disponível |

## Integração com Moises

Após o download, abra o [Moises](https://moises.ai/) e importe o arquivo baixado de `~/Music/yomp3/`. Selecione o modelo de separação desejado (vocais, bateria, baixo, etc.) e inicie a análise. Por não ter re-encodação, o Moises recebe o melhor áudio possível, produzindo stems mais limpos.

## Troubleshooting

**O macOS bloqueia o app ao abrir (Gatekeeper / "App is damaged")**
O `.app` distribuído é assinado ad-hoc por enquanto, então o Gatekeeper marca como não-confiável. Remova a quarentena:
```bash
xattr -dr com.apple.quarantine /Applications/YoMP3.app
```

**`yt-dlp not found` ou `ffmpeg not found`**
Instale ambos via Homebrew: `brew install yt-dlp ffmpeg`. O app procura nos paths padrão (`/opt/homebrew/bin` em Apple Silicon, `/usr/local/bin` em Intel) e no seu `$PATH`.

**App não abre ou trava silenciosamente**
Abra o Console.app e filtre por `subsystem:com.samuelcabral.yomp3` para ver logs internos.

**Build "Universal binary failed; falling back to native arch"**
Esperado se você só tem Command Line Tools (sem Xcode completo). O script gera um binário nativo da sua arquitetura — funciona localmente, só não é compatível cross-arch.

## Desenvolvimento

```bash
swift build                              # compilar
bash Scripts/build-app.sh && open build/YoMP3.app   # rodar como .app (necessário para janela SwiftUI)
bash Scripts/package-dmg.sh             # empacotar DMG
```

> **Nota:** `swift run yomp3` direto não abre janela de forma confiável no macOS — sempre use o bundle `.app`.

## Status de desenvolvimento

Pré-1.0. APIs internas, formato do `queue.json` em `~/Library/Application Support/yomp3/` e nome de arquivos podem mudar entre versões. Feedback via [Issues](https://github.com/samuel-cabral/yomp3/issues).

## Licença

MIT — veja [LICENSE](LICENSE)
