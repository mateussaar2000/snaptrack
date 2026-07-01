#!/bin/bash
set -e

# SnapTrack TestFlight / App Store archive script
#
# Before running:
# 1. Open scripts/ExportOptions.plist and replace YOUR_TEAM_ID with your Apple Developer Team ID.
# 2. Make sure Config.plist exists at app/dime/Data/Config.plist (copy from Config.template.plist).
# 3. Sign in to Xcode with your Apple ID: Xcode → Settings → Accounts.

# Ensure Xcode uses the system rsync before any third-party one (MacPorts/Homebrew
# rsync breaks IPA packaging), while keeping the preferred python3/etc available.
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

SCHEME="SnapTrack"
PROJECT="../app/dime.xcodeproj"
ARCHIVE_PATH="../build/SnapTrack.xcarchive"
EXPORT_PATH="../build/SnapTrack.ipa"
EXPORT_OPTIONS="ExportOptions.plist"

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

echo "✅ IPA exported to $EXPORT_PATH"
echo ""
echo "To upload to TestFlight manually, open Transporter and drag the .ipa there,"
echo "or run: xcrun altool --upload-app --type ios --file \"$EXPORT_PATH/SnapTrack.ipa\" --apiKey \"YOUR_API_KEY\" --apiIssuer \"YOUR_ISSUER_ID\""
