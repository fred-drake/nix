# Import common Nix commands
import "common-config/justfile-nix"

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
