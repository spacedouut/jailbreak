# spaced's rootless jailbreak repo

This is a flat APT repository for rootless jailbreak packages.

## Add a package

1. Build a rootless `.deb` whose payload installs beneath `/var/jb`.
2. Copy the finished package into `debs/`.
3. Run `./update-repo.sh`.
4. Commit the `.deb` and the regenerated `Packages*` and `Release` files.

The updater reads each package's `DEBIAN/control` metadata, so package names,
versions, dependencies, descriptions, and architectures do not need to be
entered again. It also generates the required file sizes and checksums.

Typical rootless control metadata includes:

```text
Package: com.spaced.example
Name: Example
Version: 1.0.0
Architecture: iphoneos-arm64
Description: An example rootless package.
Maintainer: spaced
Author: spaced
Section: Tweaks
Depends: firmware (>= 15.0)
```

Typical tweak payload paths are:

```text
/var/jb/Library/MobileSubstrate/DynamicLibraries/Example.dylib
/var/jb/Library/MobileSubstrate/DynamicLibraries/Example.plist
```

Add a `Depiction:` or `SileoDepiction:` URL to the package control file if a
package should link to content under `depictions/`.
