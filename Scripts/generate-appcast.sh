#!/bin/bash
# EveryTerm Sparkle appcast generator skeleton.
#
# Uses Sparkle's `generate_appcast` binary to walk the release directory,
# sign each build with the stored EdDSA private key, and emit the
# appcast.xml consumed by Sparkle on the client side.
set -euo pipefail

RELEASES_DIR="${RELEASES_DIR:-build/Releases}"
APPCAST_OUT="${APPCAST_OUT:-docs/appcast.xml}"
EDDSA_KEY="${EDDSA_KEY:-$HOME/.everyterm/eddsa_priv.key}"
DRY_RUN="${DRY_RUN:-0}"

if [[ "${1:-}" == "--dry-run" || "${DRY_RUN}" == "1" ]]; then
  echo "[generate-appcast.sh] dry-run: would run generate_appcast over ${RELEASES_DIR}"
  exit 0
fi

if ! command -v generate_appcast >/dev/null 2>&1; then
  echo "generate_appcast not found — install Sparkle first." >&2
  exit 1
fi

mkdir -p "$(dirname "${APPCAST_OUT}")"

generate_appcast \
  --ed-key-file "${EDDSA_KEY}" \
  --output-path "${APPCAST_OUT}" \
  "${RELEASES_DIR}"
