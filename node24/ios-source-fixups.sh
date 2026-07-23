#!/bin/sh
set -eux

SRC="${1:?usage: ios-source-fixups.sh <node-src-dir>}"
cd "$SRC"

# Apple's ld64 does not support GNU archive group flags and does not need them.
python3 - "tools/gyp/pylib/gyp/generator/make.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
updated = s.replace(" -Wl,--start-group", "").replace(" -Wl,--end-group", "")
if updated == s:
    raise SystemExit("gyp archive-group fixup matched nothing")
open(p, "w").write(updated)
PY

# The system trust-store reader is macOS-only, despite historically being
# guarded by the broader __APPLE__ macro.
python3 - "src/crypto/crypto_context.cc" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
if "TargetConditionals.h" not in s:
    s = "#if defined(__APPLE__)\n#include <TargetConditionals.h>\n#endif\n" + s
updated = s.replace("#ifdef __APPLE__", "#if defined(__APPLE__) && TARGET_OS_OSX")
if updated == s:
    raise SystemExit("crypto_context.cc fixup matched nothing")
open(p, "w").write(updated)
PY

# The make generator ignores xcode_settings framework flags for its iOS flavor.
python3 - "common.gypi" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
anchor = "['OS==\"mac\"', {\n        'defines': ['_DARWIN_USE_64_BIT_INODE=1'],"
inject = ("['OS==\"ios\"', {\n"
          "        'link_settings': { 'libraries': [\n"
          "          '-framework CoreFoundation',\n"
          "          '-framework CoreServices',\n"
          "          '-framework Security',\n"
          "        ] },\n"
          "      }],\n"
          "      " + anchor)
if anchor not in s:
    raise SystemExit("common.gypi framework anchor not found")
if "OS==\"ios\"" not in s:
    s = s.replace(anchor, inject, 1)
open(p, "w").write(s)
PY

# MAP_JIT is unsuitable for the A10 jailbreak runtime. The baseline package
# defaults to --jitless; a later patch will add explicit mprotect W^X support.
python3 - "deps/v8/src/base/platform/platform-posix.cc" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
updated = s.replace(
    "#if V8_OS_DARWIN\n  // MAP_JIT is required to obtain writable and executable pages when the",
    "#if V8_OS_DARWIN && !defined(V8_OS_IOS)\n  // MAP_JIT is required to obtain writable and executable pages when the",
)
if updated == s:
    raise SystemExit("V8 MAP_JIT fixup matched nothing")
open(p, "w").write(updated)
PY

# iOS has arc4random_buf but not the SDK header selected by c-ares' Darwin config.
if grep -q '#define HAVE_SYS_RANDOM_H 1' deps/cares/config/darwin/ares_config.h; then
  sed -i.bak 's|#define HAVE_SYS_RANDOM_H 1|/* undef HAVE_SYS_RANDOM_H (iOS SDK lacks it) */|' \
    deps/cares/config/darwin/ares_config.h
fi

echo "Node 24 iOS baseline fixups applied"
