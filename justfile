default:
    @just --list

rebuild-pre:
    git add *.nix

rebuild: rebuild-pre
    scripts/system-flake-rebuild.sh

rebuild-trace: rebuild-pre
    scripts/system-flake-rebuild-trace.sh

update:
    nix flake update

rebuild-update: update && rebuild

diff:
    git diff ':!flake.lock'
