#!/bin/bash
# GoldMind → TestFlight automated upload.
#
# Reads App Store Connect API credentials from .secrets/asc-api.env:
#   ASC_KEY_ID=ABCDE12345
#   ASC_ISSUER_ID=12345678-1234-1234-1234-123456789012
#   ASC_KEY_PATH=.secrets/AuthKey_ABCDE12345.p8
#   TEAM_ID=ABCDE12345
#
# Steps: clean → archive → export IPA → upload via altool.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

SECRETS_FILE=".secrets/asc-api.env"
if [[ ! -f "$SECRETS_FILE" ]]; then
    echo "✗ Missing $SECRETS_FILE — see header of this script for required keys."
    exit 1
fi
# shellcheck disable=SC1090
source "$SECRETS_FILE"

: "${ASC_KEY_ID:?ASC_KEY_ID not set in $SECRETS_FILE}"
: "${ASC_ISSUER_ID:?ASC_ISSUER_ID not set in $SECRETS_FILE}"
: "${ASC_KEY_PATH:?ASC_KEY_PATH not set in $SECRETS_FILE}"
: "${TEAM_ID:?TEAM_ID not set in $SECRETS_FILE}"

if [[ ! -f "$ASC_KEY_PATH" ]]; then
    echo "✗ API key file not found at $ASC_KEY_PATH"
    exit 1
fi

SCHEME="GoldMind"
PROJECT="GoldMind.xcodeproj"
BUILD_DIR="$PROJECT_DIR/build/testflight"

# Lock file prevents concurrent runs from trampling each other's
# archives. The 17/18 build loss came from two uploads running in
# parallel, both writing to the same fixed archive path. Fail-fast
# if another run is already in progress.
LOCK_FILE="$BUILD_DIR/.upload.lock"
mkdir -p "$BUILD_DIR"
if [[ -f "$LOCK_FILE" ]]; then
    other_pid=$(cat "$LOCK_FILE" 2>/dev/null || echo "?")
    if kill -0 "$other_pid" 2>/dev/null; then
        echo "✗ Another TestFlight upload is already running (pid $other_pid). Aborting."
        echo "  If you're sure no other run is active, delete: $LOCK_FILE"
        exit 1
    fi
    echo "▸ Stale lock from pid $other_pid (process gone). Reclaiming."
fi
echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT INT TERM

# Capture the build number ONCE at script start. Previously this was
# re-read at the final "Uploaded build N" line — if the file changed
# mid-run, the log lied about which version was uploaded.
BUILD_NUMBER="$(grep -m1 'CURRENT_PROJECT_VERSION =' "$PROJECT/project.pbxproj" | sed -E 's/.*= ([0-9]+);.*/\1/' || echo "?")"

# Per-build paths so concurrent runs (or interrupted prior runs) can't
# wipe an in-flight archive.
ARCHIVE_PATH="$BUILD_DIR/GoldMind-${BUILD_NUMBER}.xcarchive"
EXPORT_PATH="$BUILD_DIR/export-${BUILD_NUMBER}"
IPA_PATH="$EXPORT_PATH/GoldMind.ipa"

echo "▸ Build number: $BUILD_NUMBER"
echo "▸ Marketing version: $(xcrun agvtool what-marketing-version -terse | head -1)"
echo

echo "▸ Cleaning previous archive at $ARCHIVE_PATH…"
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"

echo "▸ Archiving (Release, generic iOS device)…"
xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    -authenticationKeyID "$ASC_KEY_ID" \
    -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
    -authenticationKeyPath "$PROJECT_DIR/$ASC_KEY_PATH" \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    CODE_SIGN_STYLE=Automatic \
    2>&1 | tail -50
test -d "$ARCHIVE_PATH" || { echo "✗ Archive failed"; exit 1; }

echo "▸ Exporting IPA…"
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist ExportOptions.plist \
    -allowProvisioningUpdates \
    -authenticationKeyID "$ASC_KEY_ID" \
    -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
    -authenticationKeyPath "$PROJECT_DIR/$ASC_KEY_PATH" \
    2>&1 | tail -50
test -f "$IPA_PATH" || { echo "✗ Export failed — no IPA at $IPA_PATH"; exit 1; }

# altool searches standard dirs for the .p8; point it at .secrets/
export API_PRIVATE_KEYS_DIR="$PROJECT_DIR/.secrets"

echo "▸ Validating with altool…"
xcrun altool --validate-app \
    -f "$IPA_PATH" \
    -t ios \
    --apiKey "$ASC_KEY_ID" \
    --apiIssuer "$ASC_ISSUER_ID"

echo "▸ Uploading to TestFlight…"
upload_log="$(mktemp)"
if xcrun altool --upload-app \
    -f "$IPA_PATH" \
    -t ios \
    --apiKey "$ASC_KEY_ID" \
    --apiIssuer "$ASC_ISSUER_ID" 2>&1 | tee "$upload_log"; then
    if grep -q "No errors uploading" "$upload_log"; then
        echo
        echo "✓ Uploaded build $BUILD_NUMBER to TestFlight."
        echo "  Processing usually takes 5–15 min. Check App Store Connect."
    else
        echo "✗ altool returned 0 but no success line. Check the log above."
        rm -f "$upload_log"
        exit 1
    fi
else
    echo "✗ altool failed for build $BUILD_NUMBER. See log above."
    rm -f "$upload_log"
    exit 1
fi
rm -f "$upload_log"
