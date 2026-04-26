#!/usr/bin/env bash
# Stub: code-sign and notarize the macOS .app/.dmg.
# Requires an Apple Developer ID (certificate in Keychain) and an app-specific
# password / API key for notarytool. Fill in the variables below when ready.
set -euo pipefail

: "${APPLE_TEAM_ID:?Set APPLE_TEAM_ID env var}"
: "${APPLE_SIGNING_IDENTITY:?Set APPLE_SIGNING_IDENTITY (e.g. 'Developer ID Application: Your Name (TEAMID)')}"
: "${APPLE_ID:?Set APPLE_ID email}"
: "${APPLE_PASSWORD:?Set APPLE_PASSWORD app-specific password}"

APP="dist/installers/macos/Chess.app"
DMG="dist/installers/macos/Chess_0.1.0_universal.dmg"

codesign --force --deep --options runtime --timestamp \
  --sign "$APPLE_SIGNING_IDENTITY" "$APP"

xcrun notarytool submit "$DMG" \
  --apple-id "$APPLE_ID" \
  --password "$APPLE_PASSWORD" \
  --team-id "$APPLE_TEAM_ID" \
  --wait

xcrun stapler staple "$DMG"
