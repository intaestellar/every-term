#!/bin/bash
# EveryTerm notarization skeleton.
#
# Requires the following environment variables (GitHub Secrets in CI):
#
#   APPLE_ID             -- developer Apple ID email
#   APPLE_TEAM_ID        -- developer team identifier
#   APPLE_APP_PASSWORD   -- app-specific password from appleid.apple.com
#
# Submits the packaged DMG to Apple's notary service, waits for the
# verdict, and staples the ticket into the DMG on success.
set -euo pipefail

DMG_PATH="${DMG_PATH:-build/EveryTerm.dmg}"
DRY_RUN="${DRY_RUN:-0}"

if [[ "${1:-}" == "--dry-run" || "${DRY_RUN}" == "1" ]]; then
  echo "[notarize.sh] dry-run: would run xcrun notarytool submit ${DMG_PATH}"
  echo "[notarize.sh] dry-run: would run xcrun stapler staple ${DMG_PATH}"
  exit 0
fi

xcrun notarytool submit "${DMG_PATH}" \
  --apple-id "${APPLE_ID}" \
  --team-id "${APPLE_TEAM_ID}" \
  --password "${APPLE_APP_PASSWORD}" \
  --wait

xcrun stapler staple "${DMG_PATH}"
