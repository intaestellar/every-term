#!/bin/bash
# EveryTerm DMG packaging skeleton.
#
# Prefers the `create-dmg` Homebrew tool when available, otherwise falls
# back to hdiutil for a minimal UDZO image. Expects the signed app bundle
# at ${APP_PATH} (default: build/EveryTerm.app).
set -euo pipefail

APP_PATH="${APP_PATH:-build/EveryTerm.app}"
DMG_PATH="${DMG_PATH:-build/EveryTerm.dmg}"
VOLUME_NAME="${VOLUME_NAME:-EveryTerm}"
BACKGROUND="${BACKGROUND:-Resources/DMGBackground.png}"
DRY_RUN="${DRY_RUN:-0}"

if [[ "${1:-}" == "--dry-run" || "${DRY_RUN}" == "1" ]]; then
  echo "[create-dmg.sh] dry-run: would build ${DMG_PATH} from ${APP_PATH}"
  exit 0
fi

rm -f "${DMG_PATH}"

if command -v create-dmg >/dev/null 2>&1; then
  create-dmg \
    --volname "${VOLUME_NAME}" \
    --background "${BACKGROUND}" \
    --window-size 540 380 \
    --icon-size 96 \
    --icon "EveryTerm.app" 140 190 \
    --app-drop-link 400 190 \
    --hdiutil-quiet \
    "${DMG_PATH}" \
    "${APP_PATH}"
else
  hdiutil create \
    -volname "${VOLUME_NAME}" \
    -srcfolder "${APP_PATH}" \
    -ov -format UDZO \
    "${DMG_PATH}"
fi
