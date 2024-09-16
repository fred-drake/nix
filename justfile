# List all commands
default:
    @just --list

_rebuild-pre:
    git add *.nix

# Rebuild the system in its current form
flake-rebuild: _rebuild-pre
    scripts/system-flake-rebuild.sh

# Rebuild the system with trace mode
flake-rebuild-trace: _rebuild-pre
    scripts/system-flake-rebuild-trace.sh

# Update input definitions from remote resources
flake-update:
    nix flake update

# Rebuild the system with updated input definitions from remote resources
flake-rebuild-update: flake-update && flake-rebuild

# See a diff of the repository
flake-diff:
    git diff ':!flake.lock'
