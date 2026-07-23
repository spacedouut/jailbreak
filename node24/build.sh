#!/bin/bash
set -euo pipefail

NODE_REF="${NODE_REF:-v24.16.0}"
IOS_MIN="${IOS_MIN:-15.0}"
WORK_DIR="${WORK_DIR:-$HOME/node24-ios-build}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

export PATH="/opt/homebrew/opt/python@3.12/libexec/bin:/opt/homebrew/bin:$PATH"
export CCACHE_DIR="$WORK_DIR/ccache"
export CCACHE_MAXSIZE=3G

mkdir -p "$WORK_DIR"
if [ ! -d "$WORK_DIR/node-src/.git" ]; then
  git clone --depth 1 --branch "$NODE_REF" https://github.com/nodejs/node.git "$WORK_DIR/node-src"
fi

if ! grep -q 'V8_OS_DARWIN && !defined(V8_OS_IOS)' \
  "$WORK_DIR/node-src/deps/v8/src/base/platform/platform-posix.cc"; then
  "$SCRIPT_DIR/ios-source-fixups.sh" "$WORK_DIR/node-src"
fi

cd "$WORK_DIR/node-src"
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
export IPHONEOS_DEPLOYMENT_TARGET="$IOS_MIN"
export CC="ccache clang -arch arm64 -isysroot $SDK -miphoneos-version-min=$IOS_MIN"
export CXX="ccache clang++ -std=gnu++20 -arch arm64 -isysroot $SDK -miphoneos-version-min=$IOS_MIN"
# IPHONEOS_DEPLOYMENT_TARGET makes clang select an iOS triple even without a
# target sysroot. Strip it from host-tool commands so generators remain macOS
# executables while target objects continue to use the iPhoneOS SDK.
export CC_host="env -u IPHONEOS_DEPLOYMENT_TARGET clang"
export CXX_host="env -u IPHONEOS_DEPLOYMENT_TARGET clang++ -std=gnu++20"
export LDFLAGS="-arch arm64 -isysroot $SDK -miphoneos-version-min=$IOS_MIN"
export GYP_DEFINES="target_arch=arm64 host_arch=arm64 host_os=mac target_os=ios"

python3 configure \
  --dest-os=ios \
  --dest-cpu=arm64 \
  --cross-compiling \
  --with-intl=small-icu \
  --without-node-snapshot \
  --without-node-code-cache \
  --without-inspector \
  --openssl-no-asm \
  --v8-options=--jitless

make -j2

file out/Release/node
ldid -S"$SCRIPT_DIR/entitlements.plist" out/Release/node
du -h out/Release/node
