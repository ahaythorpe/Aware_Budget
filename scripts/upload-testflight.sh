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
ARCHIVE_PATH="$BUILD_DIR/GoldMind.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
IPA_PATH="$EXPORT_PATH/GoldMind.ipa"

mkdir -p "$BUILD_DIR"

echo "▸ Build number: $(xcrun agvtool what-version -terse)"
echo "▸ Marketing version: $(xcrun agvtool what-marketing-version -terse | head -1)"
echo

echo "▸ Cleaning previous archive…"
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
xcrun altool --upload-app \
    -f "$IPA_PATH" \
    -t ios \
    --apiKey "$ASC_KEY_ID" \
    --apiIssuer "$ASC_ISSUER_ID"

echo
echo "✓ Uploaded build $(xcrun agvtool what-version -terse) to TestFlight."
echo "  Processing usually takes 5–15 min. Check App Store Connect."
