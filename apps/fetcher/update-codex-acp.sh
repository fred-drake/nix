#!/usr/bin/env bash
# Refresh the lockfiles and npm dependency hashes coupled to the codex-acp pin.
# Run after npm-packages.nix has been regenerated; the Justfile does this.
#
# Usage: ./apps/fetcher/update-codex-acp.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

NPM_PACKAGES_FILE="$SCRIPT_DIR/npm-packages.nix"
ACP_LOCK_FILE="$SCRIPT_DIR/codex-acp-lock.json"
CODEX_PACKAGE_FILE="$SCRIPT_DIR/codex-package.json"
CODEX_LOCK_FILE="$SCRIPT_DIR/codex-lock.json"
ACP_NIX_FILE="$ROOT_DIR/apps/codex-acp.nix"
CODEX_NIX_FILE="$ROOT_DIR/apps/codex.nix"

pin=$(nix eval --json --file "$NPM_PACKAGES_FILE" codex-acp)
version=$(jq -er '.version' <<<"$pin")
url=$(jq -er '.url' <<<"$pin")
expected_url_hash=$(jq -er '."url-hash"' <<<"$pin")

echo "Refreshing Codex ACP dependencies for $version ..."
prefetched=$(nix store prefetch-file --json "$url")
source_path=$(jq -er '.storePath' <<<"$prefetched")
actual_url_hash=$(jq -er '.hash' <<<"$prefetched")
if [[ $actual_url_hash != "$expected_url_hash" ]]; then
  echo "codex-acp source hash mismatch: expected $expected_url_hash, got $actual_url_hash" >&2
  exit 1
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
acp_dir="$tmp/codex-acp"
codex_dir="$tmp/codex-runtime"
mkdir -p "$acp_dir" "$codex_dir"
tar -xzf "$source_path" --strip-components=1 -C "$acp_dir"

published_version=$(jq -er '.version' "$acp_dir/package.json")
if [[ $published_version != "$version" ]]; then
  echo "codex-acp version mismatch: pin is $version, tarball is $published_version" >&2
  exit 1
fi

rm -f "$acp_dir/package-lock.json"
(
  cd "$acp_dir"
  npm install --ignore-scripts --no-audit --no-fund --loglevel=error
)

missing_integrity=$(jq '[.packages | to_entries[] | select(.value.resolved != null and .value.integrity == null)] | length' "$acp_dir/package-lock.json")
if [[ $missing_integrity != 0 ]]; then
  echo "codex-acp lockfile has $missing_integrity registry entries without integrity" >&2
  exit 1
fi

codex_version=$(jq -er '.packages["node_modules/@openai/codex"].version' "$acp_dir/package-lock.json")
acp_npm_deps_hash=$(nix run nixpkgs#prefetch-npm-deps -- "$acp_dir/package-lock.json" 2>/dev/null)

jq -n --arg version "$codex_version" '{
  name: "codex-runtime",
  version: $version,
  private: true,
  dependencies: {
    "@openai/codex": $version
  }
}' >"$codex_dir/package.json"
(
  cd "$codex_dir"
  npm install --ignore-scripts --no-audit --no-fund --loglevel=error
)

missing_integrity=$(jq '[.packages | to_entries[] | select(.value.resolved != null and .value.integrity == null)] | length' "$codex_dir/package-lock.json")
if [[ $missing_integrity != 0 ]]; then
  echo "Codex runtime lockfile has $missing_integrity registry entries without integrity" >&2
  exit 1
fi

codex_npm_deps_hash=$(nix run nixpkgs#prefetch-npm-deps -- "$codex_dir/package-lock.json" 2>/dev/null)

cp "$ACP_NIX_FILE" "$tmp/codex-acp.nix"
cp "$CODEX_NIX_FILE" "$tmp/codex.nix"
replace_npm_deps_hash() {
  local file=$1
  local hash=$2
  node - "$file" "$hash" <<'NODE'
const fs = require('fs');
const [file, hash] = process.argv.slice(2);
const contents = fs.readFileSync(file, 'utf8');
const matches = contents.match(/npmDepsHash = "[^"]+";/g) ?? [];
if (matches.length !== 1) {
  throw new Error(`Expected one npmDepsHash assignment in ${file}, found ${matches.length}`);
}
fs.writeFileSync(file, contents.replace(matches[0], `npmDepsHash = "${hash}";`));
NODE
}
replace_npm_deps_hash "$tmp/codex-acp.nix" "$acp_npm_deps_hash"
replace_npm_deps_hash "$tmp/codex.nix" "$codex_npm_deps_hash"
alejandra --quiet "$tmp/codex-acp.nix" "$tmp/codex.nix"

cp "$acp_dir/package-lock.json" "$ACP_LOCK_FILE"
cp "$codex_dir/package.json" "$CODEX_PACKAGE_FILE"
cp "$codex_dir/package-lock.json" "$CODEX_LOCK_FILE"
cp "$tmp/codex-acp.nix" "$ACP_NIX_FILE"
cp "$tmp/codex.nix" "$CODEX_NIX_FILE"

echo "Updated codex-acp $version (Codex $codex_version)"
echo "  codex-acp npmDepsHash: $acp_npm_deps_hash"
echo "  codex npmDepsHash:     $codex_npm_deps_hash"
