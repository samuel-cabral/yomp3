"""
YoMP3 Backend Server
Wraps yt-dlp to provide download and playlist endpoints for the iOS app.
"""

import os
import shutil
import tempfile
import logging
from pathlib import Path

from flask import Flask, jsonify, request, send_file, abort
from flask_cors import CORS
from werkzeug.exceptions import HTTPException
import yt_dlp

# ---------------------------------------------------------------------------
# App setup
# ---------------------------------------------------------------------------

app = Flask(__name__)
CORS(app)  # Allow all origins so the iOS app can connect from any network

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

MIME_TYPES = {
    "m4a": "audio/mp4",
    "mp3": "audio/mpeg",
    "wav": "audio/wav",
    "webm": "audio/webm",
    "ogg": "audio/ogg",
}

FORMAT_SELECTORS = {
    "original": "bestaudio[ext=m4a]/bestaudio",
    "m4a": "bestaudio[ext=m4a]/bestaudio",
    "mp3": "bestaudio/best",
    "wav": "bestaudio/best",
}


def _build_ydl_opts(fmt: str, output_template: str, tmpdir: str) -> dict:
    """Return yt-dlp options dict for the requested audio format."""
    # Bug 4 fix: only append .%(ext)s if the template doesn't already contain it
    tmpl = output_template if "%(ext)s" in output_template else f"{output_template}.%(ext)s"
    outtmpl = os.path.join(tmpdir, tmpl)

    base_opts = {
        "outtmpl": outtmpl,
        "quiet": True,
        "no_warnings": True,
        "noplaylist": True,
        "format": FORMAT_SELECTORS.get(fmt, "bestaudio[ext=m4a]/bestaudio"),
    }

    if fmt == "mp3":
        base_opts["postprocessors"] = [
            {
                "key": "FFmpegExtractAudio",
                "preferredcodec": "mp3",
                "preferredquality": "320",
            }
        ]
    elif fmt == "wav":
        base_opts["postprocessors"] = [
            {
                "key": "FFmpegExtractAudio",
                "preferredcodec": "wav",
            }
        ]
    elif fmt == "m4a":
        base_opts["postprocessors"] = [
            {
                "key": "FFmpegExtractAudio",
                "preferredcodec": "m4a",
                "preferredquality": "0",
            }
        ]

    return base_opts


def _find_downloaded_file(tmpdir: str) -> Path | None:
    """Return the first audio file found in tmpdir, or None."""
    candidates = sorted(Path(tmpdir).iterdir())
    for p in candidates:
        if p.is_file() and not p.name.startswith("."):
            return p
    return None


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------


@app.before_request
def log_request():
    logger.info("%s %s args=%s", request.method, request.path, dict(request.args))


@app.route("/health")
def health():
    return jsonify({"status": "ok"}), 200


@app.route("/api/playlist")
def playlist():
    url = request.args.get("url", "").strip()
    if not url:
        abort(400, description="Missing 'url' query parameter")

    ydl_opts = {
        "quiet": True,
        "no_warnings": True,
        "extract_flat": "in_playlist",
        "skip_download": True,
    }

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)
    except yt_dlp.utils.DownloadError as exc:
        logger.error("Playlist extraction failed: %s", exc)
        abort(400, description=f"Could not extract playlist: {exc}")
    except Exception as exc:
        logger.exception("Unexpected error during playlist extraction")
        abort(500, description=str(exc))

    # Bug 1 fix: guard against None return from extract_info (geo-blocked / unrecognised URLs)
    if not info:
        return jsonify({"urls": [url]}), 200

    entries = info.get("entries") or []

    # Bug 2 fix: skip None entries (deleted/unavailable videos in a playlist)
    urls = []
    for entry in entries:
        if entry is None:
            continue
        entry_url = entry.get("url") or entry.get("webpage_url")
        if entry_url:
            # yt-dlp sometimes returns bare video IDs for flat extraction
            if entry_url.startswith("http"):
                urls.append(entry_url)
            else:
                urls.append(f"https://www.youtube.com/watch?v={entry_url}")

    return jsonify({"urls": urls}), 200


@app.route("/api/download")
def download():
    url = request.args.get("url", "").strip()
    fmt = request.args.get("format", "original").strip().lower()
    template = request.args.get("template", "%(title)s").strip()

    if not url:
        abort(400, description="Missing 'url' query parameter")

    if fmt not in FORMAT_SELECTORS:
        abort(400, description=f"Unsupported format '{fmt}'. Use: original, m4a, mp3, wav")

    # Sanitise template — strip directory separators to prevent path traversal
    template = template.replace("/", "_").replace("\\", "_")
    if not template:
        template = "%(title)s"

    tmpdir = tempfile.mkdtemp(prefix="yomp3_")
    logger.info("Downloading url=%s format=%s to %s", url, fmt, tmpdir)

    try:
        ydl_opts = _build_ydl_opts(fmt, template, tmpdir)
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download([url])

        audio_file = _find_downloaded_file(tmpdir)
        if audio_file is None:
            logger.error("No file found in %s after download", tmpdir)
            abort(500, description="Download completed but no output file was found")

        ext = audio_file.suffix.lstrip(".")
        mime = MIME_TYPES.get(ext, "application/octet-stream")
        download_name = audio_file.name

        logger.info("Streaming file %s (%s)", download_name, mime)

        response = send_file(
            str(audio_file),
            mimetype=mime,
            as_attachment=True,
            download_name=download_name,
        )

        # Schedule cleanup after the response finishes streaming
        @response.call_on_close
        def cleanup():
            try:
                shutil.rmtree(tmpdir, ignore_errors=True)
                logger.info("Cleaned up temp dir %s", tmpdir)
            except Exception:
                pass

        return response

    # Bug 3 fix: re-raise HTTPException so Flask's own error handlers process it,
    # preventing abort() calls inside the try block from being swallowed by the
    # generic except Exception handler below.
    except HTTPException:
        shutil.rmtree(tmpdir, ignore_errors=True)
        raise
    except yt_dlp.utils.DownloadError as exc:
        shutil.rmtree(tmpdir, ignore_errors=True)
        logger.error("yt-dlp DownloadError: %s", exc)
        abort(400, description=f"Download failed: {exc}")
    except Exception as exc:
        shutil.rmtree(tmpdir, ignore_errors=True)
        logger.exception("Unexpected error during download")
        abort(500, description=str(exc))


# ---------------------------------------------------------------------------
# Error handlers
# ---------------------------------------------------------------------------


@app.errorhandler(400)
def bad_request(exc):
    return jsonify({"error": str(exc.description)}), 400


@app.errorhandler(500)
def internal_error(exc):
    return jsonify({"error": str(exc.description)}), 500


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    logger.info("YoMP3 backend starting on 0.0.0.0:%d", port)
    app.run(host="0.0.0.0", port=port, debug=False)
