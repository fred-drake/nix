---
name: Dendritic audit surprises
description: Non-obvious compliance findings in modules/features/ that won't be apparent from re-reading code — where guards live, cross-cutting patterns, and base-module exceptions.
type: project
---

Non-obvious observations from auditing modules/features/ on 2026-04-17:

- Most hm-*.nix wrappers are deliberately thin and do NOT guard on capability flags themselves. Guards live one level down in modules/home-manager/features/*.nix using the `(osConfig.my or {}).hasX or config.my.hasX` pattern so the same file works for both NixOS+HM and standalone Darwin HM. Do not flag the wrapper as "missing mkIf" — the guard is intentional at the leaf.
- hm-darwin.nix and hm-linux-apps.nix rely on `pkgs.stdenv.hostPlatform.isDarwin/isLinux` at the leaf for platform gating rather than a `my.isDarwin` flag. This is the project's chosen idiom.
- `nixos-base.nix` is explicitly unguarded by design (comment in file) — it sets timezone + btop for all NixOS hosts.
- gpu-passthrough.nix is the canonical cross-cutting example: one file registers into both `my.modules.nixos.gpu-passthrough` AND `my.modules.home-manager.gpu-passthrough`. Use it as the reference when unifying split features.
- prometheus-node-exporter.nix reads `config.soft-secrets.host.${config.my.hostName}.admin_ip_address` — this is a LOOKUP keyed by hostname, not a branch on hostname. It is compliant; do not flag as a hostname check.

**Why:** future reviewers re-running this audit will otherwise flag the thin wrappers and the soft-secrets lookup as violations.
**How to apply:** when auditing, verify the leaf file before flagging a wrapper; treat `config.X.${hostName}` attribute lookups as data-driven (compliant) vs `hostName == "foo"` branches (violation).
