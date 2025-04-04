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
update-all: update update-cursor-extensions update-repos update-secrets

# Update input definitions from remote resources
update:
    nix flake update

# Refresh Cursor Extensions
update-cursor-extensions:
    update-cursor-extensions

# Pull the latest hashes and shas from the repos in apps/fetcher/repos.toml
update-repos:
    update-fetcher-repos

# Update the secrets flake
update-secrets:
    nix flake update secrets

# Run colmena remote switch on given host
colmena HOST:
    colmena apply --on {{ HOST }} --impure
