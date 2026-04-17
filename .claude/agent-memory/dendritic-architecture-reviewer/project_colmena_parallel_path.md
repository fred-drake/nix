---
name: Colmena has a parallel infra path outside lib/nixos-infra.nix
description: Colmena hosts assemble commonModules inline instead of reusing lib/nixos-infra.nix, and filter deferredNixosModules by feature name.
type: project
---

Colmena hosts (colmena/hosts/*.nix) do NOT go through lib/nixos-infra.nix. Each host imports nixosOptionsModule, soft-secrets, sops, minimal.nix, services, and `++ deferredNixosModules` directly. The deferredNixosModules passed in are pre-filtered in modules/infra/colmena-config.nix by a hardcoded string list (`desktopOnlyModules = ["gaming" "nvidia-cuda" "pipewire-audio" "hyprland" "gnome-desktop" "gpu-passthrough"]`).

Why: The minimal.nix profile doesn't register desktop NixOS options; `lib.mkIf false` still forces option-type validation, so desktop deferred modules must be excluded outright from Colmena builds.

How to apply: When suggesting new desktop-only feature modules, add them to the `desktopOnlyModules` list in modules/infra/colmena-config.nix or they will break colmena builds. When proposing a refactor that unifies nixos-infra.nix with colmena, know this filter is the reason the two paths diverged.
