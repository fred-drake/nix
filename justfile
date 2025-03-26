# List all commands
default:
    @just --list

_rebuild-pre:
    git add *.nix

# Rebuild the system in its current form
rebuild: _rebuild-pre
    system-flake-rebuild

# Update input definitions from remote resources
update:
    nix flake update

# Refresh Cursor Extensions
update-cursor-extensions:
    update-cursor-extensions

# Rebuild the system with updated input definitions from remote resources
update-rebuild: update && rebuild

# Update the secrets flake
update-secrets:
    nix flake update secrets

# Run colmena remote switch on given host
colmena HOST:
    colmena apply --on {{ HOST }} --impure
