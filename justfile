# List all commands
default:
    @just --list

_rebuild-pre:
    git add *.nix

# Rebuild the system in its current form
rebuild: _rebuild-pre
    scripts/system-flake-rebuild.sh

# Rebuild the system with trace mode
rebuild-trace: _rebuild-pre
    scripts/system-flake-rebuild-trace.sh

# Update input definitions from remote resources
update:
    nix flake update

# Rebuild the system with updated input definitions from remote resources
rebuild-update: update && rebuild

# See a diff of the repository
diff:
    git diff ':!flake.lock'
