#!/bin/bash
# build-freerdp.sh
# FreeRDP XCFramework build skeleton for EveryTerm.
#
# This script is a placeholder. The actual FreeRDP build pipeline will be
# implemented during the release preparation phase (SP-4 follow-up).
#
# High-level steps (to be implemented):
#   1. Install build dependencies via Homebrew:
#        brew install cmake ninja pkg-config openssl@3
#   2. Clone and checkout the target FreeRDP release tag.
#   3. Configure CMake for macOS arm64 and x86_64 slices (static libs).
#   4. Run `cmake --build` for each architecture into separate output dirs.
#   5. Package each slice with `xcodebuild -create-xcframework` into
#        ./Frameworks/FreeRDP.xcframework
#   6. Emit SHA-256 checksum for Package.swift binaryTarget consumption.
#
# Until the real pipeline lands, this script exits successfully so that CI
# and developers can invoke it without failure while treating the absence
# of the XCFramework as an expected state.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OUTPUT_DIR="${REPO_ROOT}/Frameworks"

echo "[build-freerdp] placeholder invoked"
echo "[build-freerdp] repo root : ${REPO_ROOT}"
echo "[build-freerdp] target dir: ${OUTPUT_DIR}/FreeRDP.xcframework"

# TODO: brew install cmake ninja pkg-config openssl@3
# TODO: git clone --depth=1 --branch <tag> https://github.com/FreeRDP/FreeRDP.git
# TODO: cmake -S FreeRDP -B build-arm64 -DCMAKE_OSX_ARCHITECTURES=arm64 ...
# TODO: cmake -S FreeRDP -B build-x86_64 -DCMAKE_OSX_ARCHITECTURES=x86_64 ...
# TODO: xcodebuild -create-xcframework \
#         -library build-arm64/libfreerdp.a  -headers FreeRDP/include \
#         -library build-x86_64/libfreerdp.a -headers FreeRDP/include \
#         -output "${OUTPUT_DIR}/FreeRDP.xcframework"
# TODO: swift package compute-checksum "${OUTPUT_DIR}/FreeRDP.xcframework.zip"

echo "[build-freerdp] placeholder complete (no artifacts produced)"
