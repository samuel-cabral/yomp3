#!/usr/bin/env bash
# Build YoMP3.app bundle from SwiftPM output.
# Required because `swift run yomp3` does not present a SwiftUI window
# reliably in macOS without a proper .app bundle (no activation policy, no dock icon).
# Worker 8 enhanced: universal binary with fallback, codesign verification.

set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="YoMP3"
APP_DIR="build/${APP_NAME}.app"
EXEC_NAME="yomp3"

echo "==> Attempting universal binary build (arm64 + x86_64)"
if swift build -c release --arch arm64 --arch x86_64 2>&1; then
    BIN_PATH="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/${EXEC_NAME}"
    echo "==> Universal binary build succeeded"
else
    echo "==> Universal binary build failed (likely CommandLineTools-only environment); falling back to native arch"
    swift build -c release
    BIN_PATH="$(swift build -c release --show-bin-path)/${EXEC_NAME}"
    echo "==> Native arch build succeeded"
fi

if [ ! -x "$BIN_PATH" ]; then
    echo "Binary not found at $BIN_PATH" >&2
    exit 1
fi

echo "==> Assembling ${APP_DIR}"
rm -rf "$APP_DIR"
mkdir -p "${APP_DIR}/Contents/MacOS" "${APP_DIR}/Contents/Resources"

cp "$BIN_PATH" "${APP_DIR}/Contents/MacOS/${EXEC_NAME}"
cp Resources/Info.plist "${APP_DIR}/Contents/Info.plist"

echo "==> Ad-hoc codesign"
codesign --sign - --force --deep --options runtime "$APP_DIR" 2>&1 | tail -3

echo "==> Verifying codesign"
codesign --verify --verbose "$APP_DIR" 2>&1 | tail -3

echo "==> Done: ${APP_DIR}"
