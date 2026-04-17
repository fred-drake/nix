---
name: hasDesktop is consumed only from Home Manager via osConfig
description: my.hasDesktop is set on NixOS hosts but no NixOS feature guards on it; only HM linux-apps reads it via osConfig fallback.
type: project
---

`config.my.hasDesktop` is set to true on macbookx86 and fredpc in modules/hosts/nixos.nix, but grep finds no NixOS-level `lib.mkIf config.my.hasDesktop`. The only consumer is modules/home-manager/features/linux-apps.nix, which reads it via `(osConfig.my or {}).hasDesktop or config.my.hasDesktop`.

Why: hasDesktop acts as a coarse umbrella for the HM side when both Hyprland and GNOME desktops qualify. It is not currently used to gate NixOS-side config — hasHyprland / hasGnome handle that.

How to apply: If asked to add a NixOS feature that should run on any desktop host, hasDesktop is the right guard. If asked whether hasDesktop is redundant, it isn't — HM linux-apps depends on it.
