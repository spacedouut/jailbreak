#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

repo_origin="spaced's repo"
repo_label="spaced's repo"
repo_description="Rootless jailbreak packages by spaced"

for tool in ar tar gzip bzip2 md5sum sha1sum sha256sum stat awk sort mktemp; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "error: required command not found: $tool" >&2
    exit 1
  }
done

mkdir -p debs depictions
tmp_dir="$(mktemp -d)"
trap 'rm -rf -- "$tmp_dir"' EXIT
: > Packages
: > "$tmp_dir/architectures"

extract_control() {
  local deb="$1"
  local work
  work="$(mktemp -d "$tmp_dir/deb.XXXXXX")"

  (
    cd "$work"
    ar x "$OLDPWD/$deb"
    control_archive="$(find . -maxdepth 1 -type f -name 'control.tar*' -print -quit)"
    if [[ -z "$control_archive" ]]; then
      echo "error: $deb has no control archive" >&2
      exit 1
    fi
    tar -xf "$control_archive" ./control 2>/dev/null || tar -xf "$control_archive" control
    cat control
  )
}

while IFS= read -r -d '' deb; do
  control_file="$tmp_dir/control"
  extract_control "$deb" > "$control_file"

  # Preserve the package's control fields, then add repository-specific fields.
  sed -e '/^Filename:/Id' \
      -e '/^Size:/Id' \
      -e '/^MD5sum:/Id' \
      -e '/^SHA1:/Id' \
      -e '/^SHA256:/Id' \
      "$control_file" >> Packages

  printf 'Filename: %s\n' "$deb" >> Packages
  printf 'Size: %s\n' "$(stat -c '%s' "$deb")" >> Packages
  printf 'MD5sum: %s\n' "$(md5sum "$deb" | awk '{print $1}')" >> Packages
  printf 'SHA1: %s\n' "$(sha1sum "$deb" | awk '{print $1}')" >> Packages
  printf 'SHA256: %s\n\n' "$(sha256sum "$deb" | awk '{print $1}')" >> Packages

  awk -F ': *' 'tolower($1) == "architecture" { print $2 }' "$control_file" \
    >> "$tmp_dir/architectures"
done < <(find debs -maxdepth 1 -type f -name '*.deb' -print0 | sort -z)

gzip -9 -n -c Packages > Packages.gz
bzip2 -9 -c Packages > Packages.bz2

architectures="$(sort -u "$tmp_dir/architectures" | awk 'NF { printf "%s%s", sep, $0; sep=" " }')"
if [[ -z "$architectures" ]]; then
  architectures="iphoneos-arm64"
fi

cat > Release <<EOF
Origin: $repo_origin
Label: $repo_label
Suite: stable
Version: 1.0
Codename: jailbreak
Architectures: $architectures
Components: main
Description: $repo_description
MD5Sum:
EOF

for index in Packages Packages.gz Packages.bz2; do
  printf ' %s %s %s\n' \
    "$(md5sum "$index" | awk '{print $1}')" \
    "$(stat -c '%s' "$index")" "$index" >> Release
done

printf 'SHA256:\n' >> Release
for index in Packages Packages.gz Packages.bz2; do
  printf ' %s %s %s\n' \
    "$(sha256sum "$index" | awk '{print $1}')" \
    "$(stat -c '%s' "$index")" "$index" >> Release
done

package_count="$(find debs -maxdepth 1 -type f -name '*.deb' | wc -l | awk '{print $1}')"
echo "Updated repository metadata for $package_count package(s)."
