#!/usr/bin/env bash
set -euo pipefail

name="${1-}"
if [[ ! "$name" =~ ^[A-Za-z0-9._-]+$ ]]; then
  printf 'invalid Nix attribute name: %q\n' "$name" >&2
  exit 1
fi

printf '"%s"\n' "$name"
