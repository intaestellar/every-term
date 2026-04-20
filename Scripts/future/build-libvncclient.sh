#!/bin/bash
# build-libvncclient.sh
# LibVNCClient XCFramework build skeleton for EveryTerm.
#
# This script is a placeholder. The actual LibVNCClient build pipeline will
# be implemented during the release preparation phase (SP-4 follow-up).
#
# High-level steps (to be implemented):
#   1. Install build dependencies via Homebrew:
#        brew install cmake ninja pkg-config openssl@3 libjpeg-turbo
#   2. Clone and checkout the target libvncserver release tag (contains
#        both libvncserver and libvncclient).
#   3. Configure CMake for macOS arm64 and x86_64 slices with client-only
#        build (`-DWITH_LIBVNCSERVER=OFF`, `-DWITH_LIBVNCCLIENT=ON`).
#   4. Run `cmake --build` for each architecture.
#   5. Package each slice with `xcodebuild -create-xcframework` into
#        ./Frameworks/LibVNCClient.xcframework
#   6. Emit SHA-256 checksum for Package.swift binaryTarget consumption.
#
# Until the real pipeline lands, this script exits successfully so that CI
# and developers can invoke it without failure while treating the absence
# of the XCFramework as an expected state.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OUTPUT_DIR="${REPO_ROOT}/Frameworks"

echo "[build-libvncclient] placeholder invoked"
echo "[build-libvncclient] repo root : ${REPO_ROOT}"
echo "[build-libvncclient] target dir: ${OUTPUT_DIR}/LibVNCClient.xcframework"

# TODO: brew install cmake ninja pkg-config openssl@3 libjpeg-turbo
# TODO: git clone --depth=1 --branch <tag> https://github.com/LibVNC/libvncserver.git
# TODO: cmake -S libvncserver -B build-arm64 -DCMAKE_OSX_ARCHITECTURES=arm64 \
#              -DWITH_LIBVNCSERVER=OFF -DWITH_LIBVNCCLIENT=ON ...
# TODO: cmake -S libvncserver -B build-x86_64 -DCMAKE_OSX_ARCHITECTURES=x86_64 ...
# TODO: xcodebuild -create-xcframework \
#         -library build-arm64/libvncclient.a  -headers libvncserver/include \
#         -library build-x86_64/libvncclient.a -headers libvncserver/include \
#         -output "${OUTPUT_DIR}/LibVNCClient.xcframework"
# TODO: swift package compute-checksum "${OUTPUT_DIR}/LibVNCClient.xcframework.zip"

echo "[build-libvncclient] placeholder complete (no artifacts produced)"
