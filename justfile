# List all commands
default:
    @just --list

_rebuild-pre:
    git add *.nix

# Switch the system in its current form
switch: _rebuild-pre
    system-flake-rebuild switch

# Build the system in its current form
build: _rebuild-pre
    system-flake-rebuild build

# Update everything
update-all: update update-npm-packages update-repos update-container-digests update-secrets

# Pull the latest hashes and shas from the repos in apps/fetcher/repos.toml
update-repos:
    update-fetcher-repos

# Update the SHA digests of container images
update-container-digests:
    update-container-digests

# Update NPM packages
update-npm-packages:
    update-npm-packages

# Run colmena on only the DNS hosts
colmena-dns: update-secrets
    just colmena dns1,dns2

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

# Run colmena remote switch on given host
colmena HOST:
    colmena apply --on {{ HOST }} --impure

# Check nixpkgs age on a colmena host
colmena-age HOST:
    @colmena exec --on {{ HOST }} --impure -- 'jq -r ".nixpkgs | \"nixpkgs: \(.shortRev) (\(((now - .lastModified) / 86400) | floor) days old)\"" /etc/nixos/version.json 2>/dev/null || echo "unknown"' 2>&1 | grep -E "^{{ HOST }} \|" | grep -v "Succeeded" | sed "s/^{{ HOST }} | //"
