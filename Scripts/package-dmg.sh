#!/usr/bin/env bash
# Package YoMP3.app into a distributable DMG.
# Usage: bash Scripts/package-dmg.sh
# Prereq: run Scripts/build-app.sh first.

set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="YoMP3"
APP_DIR="build/${APP_NAME}.app"
DMG_PATH="build/${APP_NAME}.dmg"
STAGING="build/dmg-staging"

if [ ! -d "$APP_DIR" ]; then
    echo "Error: ${APP_DIR} not found. Run Scripts/build-app.sh first." >&2
    exit 1
fi

echo "==> Staging DMG contents"
rm -rf "$STAGING"
mkdir -p "$STAGING"
cp -R "$APP_DIR" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

echo "==> Creating DMG"
rm -f "$DMG_PATH"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGING" -ov -format UDZO "$DMG_PATH"
rm -rf "$STAGING"
echo "==> Done: ${DMG_PATH}"
