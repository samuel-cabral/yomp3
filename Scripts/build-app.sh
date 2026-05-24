#!/usr/bin/env bash
# Build YoMP3 for iOS Simulator using XcodeGen + xcodebuild.
# Requires Xcode (not just Command Line Tools) and xcodegen.
#
# Usage: bash Scripts/build-app.sh [simulator-name]
# Example: bash Scripts/build-app.sh "iPhone 16"
#
# Install prerequisites:
#   brew install xcodegen
#   (Xcode must be installed from the Mac App Store)

set -euo pipefail

cd "$(dirname "$0")/.."

SCHEME="YoMP3"
SIMULATOR="${1:-iPhone 16}"
DERIVED_DATA="build/DerivedData"

# ── 1. Check for xcodegen ────────────────────────────────────────────────────
if ! command -v xcodegen &>/dev/null; then
    echo "Error: xcodegen not found." >&2
    echo "Install it with:" >&2
    echo "    brew install xcodegen" >&2
    exit 1
fi

# ── 2. Generate Xcode project ────────────────────────────────────────────────
echo "==> Generating YoMP3.xcodeproj with XcodeGen"
xcodegen generate --spec project.yml

# ── 3. Build for iOS Simulator ──────────────────────────────────────────────
echo "==> Building for iOS Simulator: $SIMULATOR"
xcodebuild \
    -project YoMP3.xcodeproj \
    -scheme "$SCHEME" \
    -sdk iphonesimulator \
    -destination "platform=iOS Simulator,name=${SIMULATOR}" \
    -derivedDataPath "$DERIVED_DATA" \
    build 2>&1

# ── 4. Report output path ────────────────────────────────────────────────────
APP_PATH=$(find "$DERIVED_DATA" -name "*.app" -maxdepth 6 | head -1)
if [ -z "$APP_PATH" ]; then
    echo "Could not locate built .app in $DERIVED_DATA" >&2
    exit 1
fi

echo "==> Built: $APP_PATH"
echo ""
echo "==> To install on a running simulator:"
echo "    xcrun simctl install booted \"$APP_PATH\""
echo "    xcrun simctl launch booted com.samuelcabral.yomp3"
