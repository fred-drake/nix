# List all commands
default:
    @just --list

_rebuild-pre:
    git add *.nix

# Switch the system in its current form (auto-updates secrets)
switch: _rebuild-pre update-secrets
    sudo system-flake-rebuild switch

# Build the system in its current form (auto-updates secrets)
build: _rebuild-pre update-secrets
    sudo system-flake-rebuild build

# Update everything
update-all: update update-npm-packages update-repos update-container-digests update-secrets update-claude update-gws

# Pull the latest hashes and shas from the repos in apps/fetcher/repos.toml
update-repos:
    update-fetcher-repos

# Update the SHA digests of container images
update-container-digests:
    update-container-digests

# Update NPM packages
update-npm-packages:
    update-npm-packages

# Update Claude Code binary and plugin repos
update-claude:
    update-claude-plugins
    ./apps/fetcher/update-claude-code.sh

# Update GWS CLI binary metadata
update-gws:
    ./apps/fetcher/update-gws.sh

# Format all .nix files with alejandra
format:
    alejandra .

# Linting for the project
lint:
    statix check

# Update input definitions from remote resources
update:
    nix flake update

# Update the secrets flake
update-secrets:
    nix flake update secrets

# Import iOS code signing identity (.p12) into the login keychain. One-time per Darwin host.
bootstrap-signing:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ "$(uname)" != "Darwin" ]]; then
        echo "bootstrap-signing only runs on macOS" >&2
        exit 1
    fi
    p12="$HOME/.config/sops-nix/secrets/apple-distribution-p12"
    pass="$HOME/.config/sops-nix/secrets/apple-distribution-p12-passphrase"
    if [[ ! -f "$p12" || ! -f "$pass" ]]; then
        echo "Decrypted secrets not found. Run 'just switch' first so sops-nix deploys them." >&2
        echo "Expected: $p12" >&2
        echo "Expected: $pass" >&2
        exit 1
    fi
    if security find-identity -v -p codesigning | grep -q "Apple Distribution"; then
        echo "Apple Distribution identity already present in login keychain — nothing to do."
        exit 0
    fi
    security import "$p12" \
        -k "$HOME/Library/Keychains/login.keychain-db" \
        -P "$(cat "$pass")" \
        -T /usr/bin/codesign \
        -T /usr/bin/security
    echo "Imported. Verify with: security find-identity -v -p codesigning"

# Run colmena remote switch on given host
colmena HOST:
    colmena apply --on {{ HOST }} --impure

# Check nixpkgs age on a colmena host
colmena-age HOST:
    @colmena exec --on {{ HOST }} --impure -- 'jq -r ".nixpkgs | \"nixpkgs: \(.shortRev) (\(((now - .lastModified) / 86400) | floor) days old)\"" /etc/nixos/version.json 2>/dev/null || echo "unknown"' 2>&1 | grep -E "^\s*{{ HOST }} \|" | grep -v "Succeeded" | sed "s/^[[:space:]]*{{ HOST }} | //"
