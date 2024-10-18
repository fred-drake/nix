# List all commands
default:
    @just --list

_rebuild-pre:
    git add *.nix

# Rebuild the system in its current form
rebuild: _rebuild-pre
    development/scripts/system-flake-rebuild.sh

# Update input definitions from remote resources
update:
    nix flake update

# Rebuild the system with updated input definitions from remote resources
update-rebuild: update && rebuild

# Update input definitions of our development flake from remote resources
devflake-update:
    cd development && nix flake update
