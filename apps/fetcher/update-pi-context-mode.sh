#!/usr/bin/env bash
# Update pi-context-mode.nix to the latest context-mode npm release.
#
# Usage: ./apps/fetcher/update-pi-context-mode.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIN_FILE="$SCRIPT_DIR/pi-context-mode.nix"

PKG="context-mode"

echo "Resolving latest $PKG ..."
version=$(npm view "$PKG" version)
echo "  version: $version"

url="https://registry.npmjs.org/$PKG/-/$PKG-$version.tgz"
echo "Fetching source hash for $url ..."
raw=$(nix-prefetch-url --type sha256 "$url" 2>/dev/null | tail -1)
hash=$(nix hash convert --hash-algo sha256 --from nix32 --to sri "$raw" 2>/dev/null)
echo "  hash: $hash"

cat > "$PIN_FILE" <<EOF
# Auto-generated — bump with ./apps/fetcher/update-pi-context-mode.sh
# Pins the context-mode npm tarball for stdenvNoCC installation.
# The pre-built JS extension files are loaded directly by pi's ESM loader.
# Do not edit by hand; run ./apps/fetcher/update-pi-context-mode.sh.
{
  version = "$version";
  # sha256 of https://registry.npmjs.org/$PKG/-/$PKG-$version.tgz
  hash = "$hash";
}
EOF

alejandra --quiet "$PIN_FILE" 2>/dev/null || true
echo "Updated $PIN_FILE ($PKG $version)"
