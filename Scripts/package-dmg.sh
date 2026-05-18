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

trap 'rm -rf "$STAGING"' EXIT

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

if [ -n "${DEVELOPER_ID_APPLICATION:-}" ] && [ -n "${NOTARY_PROFILE:-}" ]; then
    echo "==> Signing DMG with Developer ID"
    codesign --sign "$DEVELOPER_ID_APPLICATION" --timestamp "$DMG_PATH"
    echo "==> Submitting to notarytool (this can take several minutes)"
    xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
    echo "==> Stapling notarization ticket"
    xcrun stapler staple "$DMG_PATH"
else
    echo "==> Skipping notarization (DEVELOPER_ID_APPLICATION or NOTARY_PROFILE not set)"
fi

echo "==> Done: ${DMG_PATH}"
