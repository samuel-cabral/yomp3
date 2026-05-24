#!/usr/bin/env bash
# Archive YoMP3 and install it on a connected iPhone.
# Requires Xcode 15+ and xcodegen.
#
# Usage: bash Scripts/install-iphone.sh
#
# Before running:
#   1. Install xcodegen:   brew install xcodegen
#   2. Open Xcode, sign in with your Apple ID (Preferences → Accounts)
#   3. Set DEVELOPMENT_TEAM in project.yml (look for the placeholder comment)
#   4. Connect your iPhone via USB and trust this computer
#   5. Run this script

set -euo pipefail

cd "$(dirname "$0")/.."

SCHEME="YoMP3"
BUNDLE_ID="com.samuelcabral.yomp3"
ARCHIVE_PATH="build/YoMP3.xcarchive"
EXPORT_PATH="build/YoMP3-export"
EXPORT_OPTIONS_PLIST="build/ExportOptions.plist"

# ── 1. Check for xcodegen ────────────────────────────────────────────────────
if ! command -v xcodegen &>/dev/null; then
    echo "Error: xcodegen not found." >&2
    echo "Install it with:" >&2
    echo "    brew install xcodegen" >&2
    exit 1
fi

# ── 2. Check DEVELOPMENT_TEAM is set in project.yml ─────────────────────────
TEAM=$(grep 'DEVELOPMENT_TEAM:' project.yml | sed 's/.*DEVELOPMENT_TEAM:[[:space:]]*//' | tr -d '"' | xargs)
if [ -z "$TEAM" ]; then
    echo "Error: DEVELOPMENT_TEAM is not set in project.yml." >&2
    echo "Open project.yml and replace the empty DEVELOPMENT_TEAM value" >&2
    echo "with your 10-character Apple Developer Team ID." >&2
    echo "You can find it at: https://developer.apple.com/account/#/membership" >&2
    exit 1
fi

echo "==> Using Development Team: $TEAM"

# ── 3. Generate Xcode project ────────────────────────────────────────────────
echo "==> Generating YoMP3.xcodeproj with XcodeGen"
xcodegen generate --spec project.yml

# ── 4. Archive for a connected device ────────────────────────────────────────
echo "==> Archiving for connected iPhone (generic/platform=iOS)"
mkdir -p build
xcodebuild archive \
    -project YoMP3.xcodeproj \
    -scheme "$SCHEME" \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE_PATH" \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM="$TEAM" \
    2>&1

echo "==> Archive created: $ARCHIVE_PATH"

# ── 5. Write ExportOptions.plist ─────────────────────────────────────────────
cat > "$EXPORT_OPTIONS_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>${TEAM}</string>
    <key>compileBitcode</key>
    <false/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
PLIST

# ── 6. Export IPA ────────────────────────────────────────────────────────────
echo "==> Exporting IPA (method: development)"
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
    2>&1

IPA_PATH=$(find "$EXPORT_PATH" -name "*.ipa" | head -1)
if [ -z "$IPA_PATH" ]; then
    echo "Error: IPA not found in $EXPORT_PATH" >&2
    exit 1
fi
echo "==> IPA ready: $IPA_PATH"

# Also locate the .app inside the archive for tools that need a .app path
APP_IN_ARCHIVE=$(find "$ARCHIVE_PATH/Products" -name "*.app" -maxdepth 4 | head -1)

# ── 7. Install on connected device ───────────────────────────────────────────
echo "==> Installing on connected iPhone"

# Try Xcode 15+ devicectl first (accepts .ipa)
if xcrun devicectl --help &>/dev/null 2>&1; then
    DEVICE_ID=$(xcrun devicectl list devices --json 2>/dev/null \
        | python3 -c "import sys,json; devs=json.load(sys.stdin).get('result',{}).get('devices',[]); print(devs[0]['identifier'])" 2>/dev/null || true)

    if [ -n "${DEVICE_ID:-}" ]; then
        echo "==> Using devicectl to install on device: $DEVICE_ID"
        xcrun devicectl device install app \
            --device "$DEVICE_ID" \
            "$IPA_PATH"
        echo "==> Installation complete!"
        echo ""
        echo "==> Launch the app from your iPhone home screen."
        exit 0
    fi
fi

# Fallback to ios-deploy (requires a .app directory, not a .ipa file)
if command -v ios-deploy &>/dev/null; then
    if [ -n "${APP_IN_ARCHIVE:-}" ]; then
        echo "==> Using ios-deploy as fallback (app: $APP_IN_ARCHIVE)"
        ios-deploy --bundle "$APP_IN_ARCHIVE" --no-wifi
        echo "==> Installation complete!"
        exit 0
    else
        echo "Warning: ios-deploy is installed but .app not found in archive; skipping." >&2
    fi
fi

# Neither tool worked — give instructions
echo ""
echo "==> Could not auto-install. Next steps:" >&2
echo "    Option A (Xcode 15+):" >&2
echo "      xcrun devicectl device install app --device <DEVICE-ID> \"$IPA_PATH\"" >&2
echo "      (find DEVICE-ID in Window → Devices and Simulators in Xcode)" >&2
echo "" >&2
echo "    Option B (ios-deploy):" >&2
echo "      npm install -g ios-deploy" >&2
echo "      # ios-deploy needs a .app directory (from the archive, not the .ipa):" >&2
echo "      ios-deploy --bundle \"${APP_IN_ARCHIVE:-$ARCHIVE_PATH/Products/Applications/YoMP3.app}\" --no-wifi" >&2
echo "" >&2
echo "    Option C (drag into Xcode):" >&2
echo "      Open Window → Devices and Simulators, drag $IPA_PATH onto your device." >&2
exit 1
