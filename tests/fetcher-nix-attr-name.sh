#!/usr/bin/env bash
set -euo pipefail

renderer="${1:-./apps/fetcher/render-nix-attr-name.sh}"

actual="$($renderer 'hermes-agent-v2026.8.3-src')"
expected='"hermes-agent-v2026.8.3-src"'
if [[ "$actual" != "$expected" ]]; then
  printf 'expected %s, got %s\n' "$expected" "$actual" >&2
  exit 1
fi

for unsafe in '${builtins.currentSystem}' 'quote"name' 'backslash\name' $'line\nbreak'; do
  if "$renderer" "$unsafe" >/dev/null 2>&1; then
    printf 'unsafe attribute name was accepted: %q\n' "$unsafe" >&2
    exit 1
  fi
done
