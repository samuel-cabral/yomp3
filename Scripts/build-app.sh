#!/usr/bin/env bash
# Build YoMP3 for iOS Simulator using Xcode.
# Requires Xcode (not just Command Line Tools).
# Usage: bash Scripts/build-app.sh [simulator-name]
# Example: bash Scripts/build-app.sh "iPhone 16"

set -euo pipefail

cd "$(dirname "$0")/.."

SCHEME="yomp3"
SIMULATOR="${1:-iPhone 16}"
DERIVED_DATA="build/DerivedData"

echo "==> Building for iOS Simulator: $SIMULATOR"
xcodebuild \
    -scheme "$SCHEME" \
    -sdk iphonesimulator \
    -destination "platform=iOS Simulator,name=${SIMULATOR}" \
    -derivedDataPath "$DERIVED_DATA" \
    build 2>&1

APP_PATH=$(find "$DERIVED_DATA" -name "*.app" -maxdepth 6 | head -1)
if [ -z "$APP_PATH" ]; then
    echo "Could not locate built .app in $DERIVED_DATA" >&2
    exit 1
fi

echo "==> Built: $APP_PATH"
echo "==> To install on simulator:"
echo "    xcrun simctl install booted \"$APP_PATH\""
echo "    xcrun simctl launch booted com.samuelcabral.yomp3"
