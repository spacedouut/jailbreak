# Node.js 24 for rootless jailbroken iOS

This directory contains the reproducible baseline build for Node.js 24.16.0
and its bundled npm. It targets `iphoneos-arm64`, installs below `/var/jb`, and
defaults V8 to `--jitless` so npm and Node scripts run safely on A10 devices.

On an Apple Silicon Mac with the iPhoneOS SDK, Python 3.12, ccache, and ldid:

```sh
./build.sh
```

After retrieving the signed binary and `deps/npm` directory to a Linux host:

```sh
./package.sh ./node ./npm ./nodejs_24.16.0-1_iphoneos-arm64.deb
```

The JIT/WebAssembly W^X patch from `j0shua-SYSON/node-ios` is intentionally not
part of this baseline. Node 24's bundled V8 has a newer BrowserEngineCore path,
so the A9/A10 `mprotect` implementation must be ported and validated separately.

Because V8's `--jitless` mode also disables WebAssembly, Node 24's global
`fetch()` API is unavailable: its bundled Undici HTTP/1 parser is WebAssembly.
The native `http` and `https` modules work, and npm's own network stack has been
verified against the public npm registry.

Install the package as root on a rootless jailbreak:

```sh
dpkg -i nodejs_24.16.0-1_iphoneos-arm64.deb
```

The package installs `node`, `npm`, and `npx` below `/var/jb/usr`.
