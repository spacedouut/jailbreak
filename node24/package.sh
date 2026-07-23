#!/bin/bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "usage: package.sh <signed-node-binary> <npm-source-dir> <output.deb>" >&2
  exit 2
fi

NODE_BINARY="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
NPM_SOURCE="$(cd "$2" && pwd)"
OUTPUT="$(cd "$(dirname "$3")" && pwd)/$(basename "$3")"
STAGE="$(mktemp -d /tmp/nodejs24-ios-package.XXXXXX)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

cleanup() {
  rm -rf "$STAGE"
}
trap cleanup EXIT

mkdir -p \
  "$STAGE/data/var/jb/usr/bin" \
  "$STAGE/data/var/jb/usr/lib/node_modules" \
  "$STAGE/control"

install -m 0755 "$NODE_BINARY" "$STAGE/data/var/jb/usr/bin/node"
cp -R "$NPM_SOURCE" "$STAGE/data/var/jb/usr/lib/node_modules/npm"
ln -s ../lib/node_modules/npm/bin/npm-cli.js "$STAGE/data/var/jb/usr/bin/npm"
ln -s ../lib/node_modules/npm/bin/npx-cli.js "$STAGE/data/var/jb/usr/bin/npx"

install -m 0644 "$SCRIPT_DIR/control" "$STAGE/control/control"
install -m 0644 "$SCRIPT_DIR/debian-binary" "$STAGE/debian-binary"
tar --sort=name --owner=0 --group=0 --numeric-owner \
  -C "$STAGE/control" -czf "$STAGE/control.tar.gz" .
tar --sort=name --owner=0 --group=0 --numeric-owner \
  -C "$STAGE/data" -czf "$STAGE/data.tar.gz" .

if [ -e "$OUTPUT" ]; then
  echo "refusing to overwrite existing output: $OUTPUT" >&2
  exit 1
fi
(cd "$STAGE" && ar -r "$OUTPUT" debian-binary control.tar.gz data.tar.gz)
echo "$OUTPUT"
