---
name: HM capability-flag fallback idiom
description: The osConfig-with-fallback pattern used in HM features to read my.* flags from either the parent OS config or standalone HM
type: project
---

HM feature modules in `modules/home-manager/features/*.nix` read capability flags using this idiom:

```nix
{ config, osConfig ? {}, ... }: let
  hasHyprland = (osConfig.my or {}).hasHyprland or config.my.hasHyprland;
in lib.mkIf hasHyprland { ... }
```

**Why:** HM module evaluation has its own `config` scope. `lib/my-options-module.nix` is imported into both the NixOS/Darwin module systems AND the HM module system via `lib/mk-home-manager.nix`, so `config.my` exists in both places. When HM runs inside NixOS/Darwin (as it does here), `osConfig` is the parent system config and takes precedence — but `config.my.hasX` is the fallback for standalone HM use. Flags are set at the host level (e.g. `modules/hosts/nixos.nix` lines 31-37) on the OS side; HM picks them up through `osConfig`.

**How to apply:** When writing new HM features that need to guard on capability, use the `(osConfig.my or {}).hasX or config.my.hasX` idiom — do not reach for `pkgs.stdenv.hostPlatform` or `config.my.hostName == "foo"`. Platform guards (`pkgs.stdenv.hostPlatform.isDarwin` / `isLinux`) are still acceptable when the logic is genuinely platform-scoped (e.g. `darwin-hm.nix`, `linux-apps.nix`), since capability flags do not express OS kernel.
