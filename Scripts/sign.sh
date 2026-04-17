#!/bin/bash
# EveryTerm codesigning skeleton.
#
# Real execution requires a paid Apple Developer account plus a
# "Developer ID Application" certificate in the local keychain.
# In CI, the certificate is installed from the following GitHub Secrets:
#
#   APPLE_CERT_BASE64      -- .p12 encoded with base64
#   APPLE_CERT_PASSWORD    -- certificate export password
#   KEYCHAIN_PASSWORD      -- temporary keychain password
#
# This script exits 0 in --dry-run mode so it can be smoke-tested inside
# environments without Apple credentials.
set -euo pipefail

APP_PATH="${APP_PATH:-build/EveryTerm.app}"
ENTITLEMENTS="${ENTITLEMENTS:-EveryTerm.entitlements}"
CERT_NAME="${CERT_NAME:-Developer ID Application: EveryTerm (TEAMID)}"
DRY_RUN="${DRY_RUN:-0}"

if [[ "${1:-}" == "--dry-run" || "${DRY_RUN}" == "1" ]]; then
  echo "[sign.sh] dry-run: would codesign ${APP_PATH} with '${CERT_NAME}' using ${ENTITLEMENTS}"
  exit 0
fi

codesign \
  --deep \
  --force \
  --verify \
  --verbose \
  --options runtime \
  --timestamp \
  --sign "${CERT_NAME}" \
  --entitlements "${ENTITLEMENTS}" \
  "${APP_PATH}"

codesign --verify --deep --strict --verbose=2 "${APP_PATH}"
