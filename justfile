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

# Update input definitions from remote resources
update:
    nix flake update

# Refresh Cursor Extensions
update-cursor-extensions:
    update-cursor-extensions

update-nvim-plugins:
    update-nvim-plugins

# Rebuild the system with updated input definitions from remote resources
update-switch: update && switch

# Update the secrets flake
update-secrets:
    nix flake update secrets

# Run colmena remote switch on given host
colmena HOST:
    colmena apply --on {{ HOST }} --impure
