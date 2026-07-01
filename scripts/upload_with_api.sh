#!/bin/bash
set -e

# Upload SnapTrack to App Store Connect using an API key.
# This script first validates the IPA, then uploads it, then polls for processing status.

SCHEME="SnapTrack"
PROJECT="../app/dime.xcodeproj"
ARCHIVE_PATH="../build/SnapTrack.xcarchive"
EXPORT_PATH="../build/SnapTrack.ipa"
EXPORT_OPTIONS="ExportOptions.plist"

# App Store Connect API credentials (SnapTrack CI key)
API_ISSUER="f613e8e5-2c0a-45c5-9a56-3299c11d3213"
API_KEY_ID="5LQRVUPX2C"
API_KEY_PATH="AuthKey_${API_KEY_ID}.p8"

# Ensure Xcode uses the system rsync first; keep preferred Python/tools available.
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

IPA_FILE="${EXPORT_PATH}/SnapTrack.ipa"

echo "🔨 Cleaning build folder..."
xcodebuild -project "$PROJECT" -scheme "$SCHEME" clean

echo "📦 Archiving..."
xcodebuild -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination 'generic/platform=iOS' \
    -archivePath "$ARCHIVE_PATH" \
    CODE_SIGNING_REQUIRED=YES \
    -allowProvisioningUpdates \
    archive

echo "🚀 Exporting IPA..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -exportPath "$EXPORT_PATH" \
    -allowProvisioningUpdates

echo "🔍 Validating IPA with App Store Connect..."
xcrun altool --validate-app \
    --type ios \
    --file "$IPA_FILE" \
    --apiKey "$API_KEY_ID" \
    --apiIssuer "$API_ISSUER" \
    --p8-file-path "$API_KEY_PATH"

echo "📤 Uploading IPA..."
xcrun altool --upload-app \
    --type ios \
    --file "$IPA_FILE" \
    --apiKey "$API_KEY_ID" \
    --apiIssuer "$API_ISSUER" \
    --p8-file-path "$API_KEY_PATH"

echo "⏳ Polling App Store Connect for processing status..."
python3 "$(dirname "$0")/asc_check.py"

echo "✅ Done. If the build is VALID, you can add it to TestFlight / review in App Store Connect."
