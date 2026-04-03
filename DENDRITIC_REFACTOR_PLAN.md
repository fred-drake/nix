# Dendritic Refactoring Plan

**Last Updated:** 2026-04-03
**Status:** Planning
**Pattern Reference:** https://github.com/mightyiam/dendritic

## Overview

Refactor this nix codebase from the current **class-organized** layout
(`modules/nixos/`, `modules/home-manager/`, `modules/darwin/`) to a
**feature-organized** dendritic pattern where every non-entry-point file is a
flake-parts module, organized by what it does rather than which configuration
class it belongs to.

### Core Principle

Every Nix file (except `flake.nix`) is a module of a single top-level
flake-parts configuration. Each file implements a single feature across all
configuration classes that the feature touches. The file's path names the
feature.

### Key Benefits

1. **No more specialArgs chains** — shared values become top-level options
2. **Feature-oriented files** — cross-cutting concerns live in one file
3. **Automatic importing** — import-tree eliminates manual import lists
4. **Every file has the same type** — all are flake-parts modules

---

## Current Architecture Summary

```
flake.nix                          # Entry point, flake-utils for devShells
systems/
  nixos.nix                        # NixOS system definitions (3 hosts)
  darwin.nix                       # Darwin system definitions (3 hosts)
colmena/
  default.nix                      # Colmena host assembly
  hosts/{headscale,ironforge,orgrimmar,anton}.nix
  hetzner-common/                  # Shared Hetzner server config
  wsl-common/                      # Shared WSL config
modules/
  nixos/
    default.nix                    # Shared NixOS config (minimal)
    host/{fredpc,headscale,ironforge,orgrimmar,anton,macbookx86,nixosaarch64vm}/
    windsurf-remote-dev.nix
  home-manager/
    default.nix                    # MONOLITHIC shared HM config (~730 lines)
    darwin.nix                     # Darwin-specific HM
    linux-desktop.nix              # Linux-specific HM
    host/{fredpc,mac-studio,macbook-pro}.nix
    hyprland/                      # Hyprland HM config
    claude-code.nix
    secrets.nix
    tmux-windev-settings.nix
  darwin/
    default.nix                    # Shared Darwin config
    {mac-studio,macbook-pro,laisas-mac-mini}/
  secrets/
    {cloudflare,ironforge,orgrimmar,sabnzbd}.nix
lib/
  mk-home-manager.nix             # HM constructor helper
  mk-neovim-packages.nix
apps/                              # Custom packages (unchanged)
homefiles/                         # Raw dotfiles (unchanged)
overlays/                          # Package overlays (unchanged)
```

### Problems with Current Structure

- **specialArgs everywhere**: 6+ different specialArgs sets threaded through
  nixosSystem, darwinSystem, and mkHomeManager calls
- **Cross-cutting features split across directories**: Hyprland config spans
  `modules/nixos/host/fredpc/hyprland.nix` + `modules/home-manager/hyprland/`
- **Monolithic HM default.nix**: 730 lines covering shells, editors, packages,
  dotfiles, programs — hard to navigate and reason about
- **Duplicate pkgs instantiation**: 12+ copies of
  `import nixpkgs { system = ...; config.allowUnfree = true; overlays = [...]; }`
- **Manual import lists**: Every system definition manually lists its module imports
- **Secrets coupled to hosts, not services**: `modules/secrets/orgrimmar.nix`
  contains secrets for 5 different services

---

## Target Architecture

```
flake.nix                          # Entry point: flake-parts.lib.mkFlake + import-tree
modules/
  infra/                           # Plumbing — option types, system builders
  features/                        # Feature modules (cross-platform, HM, platform-specific)
  services/                        # Server service modules (each owns its secrets)
  hosts/                           # Host composition modules (import features)
apps/                              # Custom packages (unchanged)
homefiles/                         # Raw dotfiles (unchanged)
overlays/                          # Package overlays (unchanged)
shell.nix                          # Dev shell (unchanged, imported by infra)
```

---

## Phase 0: Foundation (flake.nix rewrite)

### Goal
Get flake-parts + import-tree working as the top-level framework. Existing
code continues to work via minimal wrapping.

### Tasks

- [ ] **0.1** Add `flake-parts` input (`github:hercules-ci/flake-parts`)
- [ ] **0.2** Add `import-tree` input (`github:vic/import-tree`)
- [ ] **0.3** Remove `flake-utils` input (only used for `eachDefaultSystem` devShells)
- [ ] **0.4** Rewrite `flake.nix` outputs to use flake-parts:
  ```nix
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; }
      (inputs.import-tree ./modules);
  ```
- [ ] **0.5** Create `modules/infra/systems.nix` defining supported systems:
  ```nix
  { systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"]; }
  ```
- [ ] **0.6** Create `modules/infra/devshell.nix` — move devShells to `perSystem`
- [ ] **0.7** Wrap existing outputs (nixosConfigurations, darwinConfigurations,
  colmena, lib) as temporary flake-parts `flake.*` passthrough modules
- [ ] **0.8** Verify `nix flake check` passes
- [ ] **0.9** Verify `just build` works for at least one NixOS and one Darwin host

### Validation
```bash
nix flake check
nix build .#nixosConfigurations.fredpc.config.system.build.toplevel --dry-run
nix build .#darwinConfigurations.mac-studio.system --dry-run
```

---

## Phase 1: Infrastructure Modules

### Goal
Build the dendritic plumbing — option types for `deferredModule`, system
builders, centralized pkgs. Replace `specialArgs` chains and helper functions.

### Tasks

- [ ] **1.1** Create `modules/infra/pkgs.nix` — centralize all pkgs variants:
  - `pkgs` (nixpkgs + overlays + allowUnfree)
  - `pkgsUnstable` (nixpkgs-unstable + overlays)
  - `pkgsStable` (nixpkgs-stable + overlays)
  - `pkgsFredTesting` (nixpkgs-fred-testing + overlays)
  - `pkgsFredUnstable` (nixpkgs-fred-unstable + overlays)
  - `pkgsCuda` (nixpkgs + cudaSupport, x86_64-linux only)
  - All defined once per system via `perSystem`, eliminating 12+ duplicate
    instantiations

- [ ] **1.2** Create `modules/infra/nixos.nix` — NixOS configuration infrastructure:
  - Define `options.configurations.nixos` as
    `lazyAttrsOf (submodule { options.module = mkOption { type = deferredModule; }; })`
  - Assemble `flake.nixosConfigurations` from `config.configurations.nixos`
  - No more `specialArgs` — `inputs` available via standard flake-parts module args

- [ ] **1.3** Create `modules/infra/darwin.nix` — Darwin configuration infrastructure:
  - Same `deferredModule` pattern as NixOS
  - Assemble `flake.darwinConfigurations`
  - Handle `darwin.lib.darwinSystem` call with centralized pkgs

- [ ] **1.4** Create `modules/infra/home-manager.nix` — HM infrastructure:
  - Set `useGlobalPkgs`, `useUserPackages`, `backupFileExtension`
  - Define `deferredModule` container for HM feature modules
  - Wire base imports: sops-nix, secrets, nixvim, nix-index-database
  - Replaces `lib/mk-home-manager.nix` entirely

- [ ] **1.5** Create `modules/infra/colmena.nix` — Colmena output assembly:
  - Migrate `colmena/default.nix` function to flake-parts module
  - Preserve init/full deployment pattern with stable node names
  - Replace `self.colmena._hostname` self-reference with explicit module imports
  - Verify `_module.args` for secrets passing works in flake-parts context

- [ ] **1.6** Create `modules/infra/homebrew-infra.nix` — nix-homebrew tap wiring:
  - Move tap infrastructure from `mkDarwinSystem` inline module
  - `nix-homebrew.darwinModules.nix-homebrew` + all tap flake input mappings
  - `enableRosetta`, `user = "fdrake"`, `mutableTaps = false`

- [ ] **1.7** Create shared top-level options module:
  - `options.my.hostName` — replaces `hostArgs.hostName` from `extraSpecialArgs`
  - `options.my.isWorkstation` — replaces `non-mac-mini-casks` discriminator
  - `options.my.username` — replaces hardcoded `"fdrake"` throughout

- [ ] **1.8** Delete `lib/mk-home-manager.nix`
- [ ] **1.9** Delete `systems/nixos.nix` and `systems/darwin.nix`
- [ ] **1.10** Delete `systems/` directory
- [ ] **1.11** Verify `nix flake check` and `just build` for all hosts

### specialArgs Elimination Reference

| Current specialArg | Replacement |
|---|---|
| `inputs` | Standard flake-parts module arg |
| `outputs` / `self` | `inputs.self` |
| `nixpkgs` (flake input) | `inputs.nixpkgs` |
| `pkgsCuda` | `perSystem` option via `infra/pkgs.nix` |
| `pkgsUnstable` / `pkgsStable` | `perSystem` options via `infra/pkgs.nix` |
| `pkgsFredTesting` / `pkgsFredUnstable` | `perSystem` options via `infra/pkgs.nix` |
| `nix4vscode` | `inputs.nix4vscode` |
| `nix-jetbrains-plugins` | `inputs.nix-jetbrains-plugins` |
| `secrets` | `inputs.secrets` |
| `non-mac-mini-casks` | `config.my.isWorkstation` flag |
| `hostArgs.hostName` | `config.my.hostName` top-level option |
| `extraSpecialArgs = { inherit inputs secrets hostArgs; }` | Eliminated entirely |

---

## Phase 2: Feature Modules (Home Manager Decomposition)

### Goal
Decompose the monolithic `modules/home-manager/default.nix` (730 lines) into
focused feature files. Fold `darwin.nix` and `linux-desktop.nix` into features
using `mkIf` platform guards.

### Tasks

- [x] **2.1** `modules/home-manager/features/shells.nix` — Done (Phase 2a)
- [x] **2.2** `modules/home-manager/features/editor.nix` — Done (Phase 2a)
- [x] **2.3** `modules/home-manager/features/dev-tools.nix` — Done (Phase 2a)
- [x] **2.4** `modules/home-manager/features/terminal.nix` — Done (Phase 2a)
- [x] **2.5** `modules/home-manager/features/dotfiles.nix` — Done (Phase 2a)
- [x] **2.6** `modules/home-manager/features/vscode-family.nix` — Done (Phase 2a)
- [x] **2.7** `modules/home-manager/features/media-apps.nix` — Done (Phase 2a)
- [x] **2.8** `modules/home-manager/features/network-tools.nix` — Done (Phase 2a)
- [x] **2.9** `modules/home-manager/features/ai-tools.nix` — Done (Phase 2a)
- [x] **2.10** `modules/home-manager/features/claude-code.nix` — Done (Phase 2c)
- [x] **2.11** `modules/home-manager/features/secrets.nix` — Done (Phase 2c)
- [x] **2.12** `modules/home-manager/features/nixvim.nix` — Done (Phase 2b)
- [x] **2.13** `modules/darwin/features/nix-daemon.nix` — Done (Phase 2b)
- [x] **2.14** `modules/darwin/features/fonts.nix` — Done (Phase 2b)
- [x] **2.15** `modules/darwin/features/user-fdrake.nix` — Done (Phase 2b)
- [x] **2.16** `modules/darwin/features/macos-prefs.nix` — Done (Phase 2b)
- [x] **2.17** `modules/darwin/features/macos-security.nix` — Done (Phase 2b)
- [x] **2.18** `modules/darwin/features/workstation-apps.nix` — Done (Phase 2b)
- [x] **2.21** `modules/home-manager/features/linux-apps.nix` — Done (Phase 2c)

#### Achievable now (Phase 2d)

- [ ] **2.19a** Consolidate `modules/home-manager/hyprland/` (4 files) into
  `modules/home-manager/features/hyprland.nix`. NixOS side stays at
  `modules/nixos/host/fredpc/hyprland.nix` until deferredModule is available.
- [ ] **2.24** Move `modules/home-manager/darwin.nix` to
  `modules/home-manager/features/darwin-hm.nix`, update import in
  `modules/infra/darwin.nix`
- [ ] **2.26** Delete `modules/home-manager/hyprland/` directory (after 2.19a)
- [ ] **2.27** Fold `modules/home-manager/tmux-windev-settings.nix` into
  `modules/home-manager/features/terminal.nix` or move to `features/`

#### Deferred — require deferredModule infrastructure (Phase 1 gap)

- [ ] **2.19b** Add NixOS deferredModule to `hyprland-desktop.nix`:
  `programs.hyprland.enable`, system packages (waybar, wofi, hyprshot),
  XDG portal, polkit. Requires deferredModule option types in
  `modules/infra/nixos.nix`.
- [ ] **2.20** Create `modules/features/gnome-desktop.nix`:
  NixOS deferredModule (services.desktopManager.gnome, GDM, dconf profiles) +
  HM deferredModule (dconf settings, gnome-tweaks, extensions).
  Requires deferredModule. HM dconf content is already in
  `features/linux-apps.nix`.
- [ ] **2.22** Create `modules/features/pipewire-audio.nix`:
  NixOS deferredModule (services.pipewire, pulse, alsa, wireplumber).
  Requires deferredModule. Currently in host configs for fredpc and macbookx86.

#### Cleanup — after all features migrated

- [ ] **2.23** Delete `modules/home-manager/default.nix` — currently the
  import hub; can only be removed when HM infrastructure uses deferredModule
  to compose features without a central import list
- [ ] **2.25** ~~Delete `modules/home-manager/linux-desktop.nix`~~ — Already
  done (renamed to `features/linux-apps.nix` in Phase 2c)
- [ ] **2.28** Delete `modules/darwin/default.nix` — currently the import hub;
  same dependency as 2.23
- [ ] **2.29** Verify `nix flake check` and `just build` / `home-manager switch`

---

## Phase 3: Service Feature Modules (Servers)

### Goal
Extract server services into self-contained feature modules, each owning its
own secrets. Decompose the monolithic per-host secrets files.

### Tasks

- [ ] **3.1** Create `modules/services/nginx-acme-proxy.nix`:
  - Reusable nginx + ACME + Cloudflare DNS validation pattern
  - Currently duplicated across headscale, ironforge (8 services), orgrimmar
    (5 services)
  - Parameterized: takes domain, upstream port, optional extra config
  - Owns the shared `cloudflare-api-key` sops secret

- [ ] **3.2** Create `modules/services/hetzner-server.nix`:
  - Migrate from `colmena/hetzner-common/`
  - SOPS age key path, zram, openssh, authorized_keys, nix.settings
  - Hardware config (qemu-guest, grub, /dev/sda filesystems)
  - Networking with `serverType` option (normal | gateway)
  - Firewall (22/80/443), SSH hardening, useDHCP=false

- [ ] **3.3** Create `modules/services/wsl-server.nix`:
  - Migrate from `colmena/wsl-common/`
  - WSL-specific base configuration

- [ ] **3.4** Create `modules/services/podman-server.nix`:
  - Shared podman configuration for container-running servers
  - Separate disk mount for `/var/lib/containers`
  - Used by ironforge and orgrimmar

- [ ] **3.5** Create `modules/services/gitea.nix`:
  - Migrate from `modules/nixos/host/orgrimmar/gitea.nix`
  - Gitea container + CIFS storage mount + gitea-check-service
  - **Owns its secrets**: gitea storage credentials, gitea-check-service-env
    (extracted from `modules/secrets/orgrimmar.nix`)

- [ ] **3.6** Create `modules/services/woodpecker-ci.nix`:
  - Migrate from `modules/nixos/host/orgrimmar/woodpecker.nix`
  - Woodpecker server + agent + PostgreSQL + podman networking
  - **Owns its secrets**: woodpecker-*-env (extracted from
    `modules/secrets/orgrimmar.nix`)

- [ ] **3.7** Create `modules/services/paperless.nix`:
  - Migrate from `modules/nixos/host/orgrimmar/paperless.nix`
  - Full stack: redis, PostgreSQL, gotenberg, tika, paperless-ai, CIFS storage
  - **Owns its secrets**: paperless-*-env, storage credentials (extracted from
    `modules/secrets/orgrimmar.nix`)

- [ ] **3.8** Create `modules/services/calibre.nix`:
  - Migrate from `modules/nixos/host/orgrimmar/calibre.nix`
  - Calibre + Calibre-web containers + CIFS storage
  - **Owns its secrets**: calibre storage credentials (extracted from
    `modules/secrets/orgrimmar.nix`)

- [ ] **3.9** Create `modules/services/resume.nix`:
  - Migrate from `modules/nixos/host/orgrimmar/resume.nix`
  - Reactive Resume + PostgreSQL + MinIO + Chromium containers
  - **Owns its secrets**: postgresql-env, minio-env, chrome-env, resume-env
    (extracted from `modules/secrets/orgrimmar.nix`)

- [ ] **3.10** Create `modules/services/media-server.nix`:
  - Migrate from `modules/nixos/host/ironforge/nixarr.nix`
  - Full nixarr stack: jellyfin, jellyseerr, sonarr, radarr, lidarr, prowlarr,
    bazarr, sabnzbd, recyclarr
  - CIFS mounts (videos, downloads storage boxes)
  - SABnzbd health check systemd service/timer
  - **Owns its secrets**: ironforge storage credentials, sabnzbd config
    (merges `modules/secrets/ironforge.nix` + `modules/secrets/sabnzbd.nix`)

- [ ] **3.11** Create `modules/services/headscale-vpn.nix`:
  - Migrate from `modules/nixos/host/headscale/headscale.nix` +
    `tailscale-client.nix`
  - Headscale coordination server + Tailscale client with subnet routing
  - IP forwarding, NAT/masquerade for private subnet
  - **Owns its secrets**: cloudflare-api-key (shared via nginx-acme-proxy)

- [ ] **3.12** Create `modules/services/glance-dashboard.nix`:
  - Migrate from `modules/nixos/host/fredpc/glance.nix` + `glance-config.nix`
  - Glance dashboard with IPMI KVM container
  - **Owns its secrets**: glance-env

- [ ] **3.13** Create `modules/services/borg-backup.nix`:
  - **NixOS deferredModule**: Borg backup services + Hetzner storage box targets
    (migrate from `modules/nixos/host/fredpc/borg-backup.nix`)
  - **HM deferredModule**: Storage credential SOPS secrets (deduplicate between
    NixOS borg-backup.nix and HM secrets.nix)
  - Cross-cutting: NixOS + HM in one file

- [ ] **3.14** Create `modules/services/gpu-passthrough.nix`:
  - **NixOS deferredModule**: VFIO, libvirtd, QEMU, virt-manager, kvmfr,
    Looking Glass (from `modules/nixos/host/fredpc/gpu-passthrough.nix`)
  - **HM deferredModule**: Scream audio user service (from
    `modules/home-manager/host/fredpc.nix`)
  - Cross-cutting: NixOS + HM in one file

- [ ] **3.15** Create `modules/services/gaming.nix`:
  - Steam, gamescope, gamemode, protonup-qt, xpadneo controller
  - Bluetooth for controller support
  - From `modules/nixos/host/fredpc/configuration.nix` gaming sections

- [ ] **3.16** Create `modules/services/nvidia-cuda.nix`:
  - NVIDIA driver + CUDA packages
  - Shared between fredpc (full GPU) and anton (WSL passthrough)
  - Configurable: `wsl.useWindowsDriver` (anton) vs native driver (fredpc)
  - CUDA cachix substituter (anton)

- [ ] **3.17** Delete `modules/secrets/orgrimmar.nix` (decomposed into service files)
- [ ] **3.18** Delete `modules/secrets/ironforge.nix` (merged into media-server.nix)
- [ ] **3.19** Delete `modules/secrets/sabnzbd.nix` (merged into media-server.nix)
- [ ] **3.20** Delete `modules/secrets/cloudflare.nix` (moved to nginx-acme-proxy.nix)
- [ ] **3.21** Delete `colmena/` directory (migrated to infra/colmena.nix + hosts)
- [ ] **3.22** Delete `modules/nixos/host/` directory (migrated to services + hosts)
- [ ] **3.23** Verify `nix flake check`, `just build`, and
  `colmena build --on HOST --impure` for all hosts

---

## Phase 4: Host Composition Modules

### Goal
Each host becomes a flake-parts module that composes features. Host files
are thin — they select features and provide host-specific overrides.

### Tasks

- [ ] **4.1** Create `modules/hosts/fredpc.nix`:
  - Hardware configuration (inline or import)
  - Feature imports: hyprland-desktop, gnome-desktop, gpu-passthrough,
    borg-backup, glance-dashboard, gaming, nvidia-cuda, pipewire-audio
  - Host overrides: VLAN networking, Samba, v4l2loopback
  - HM host overrides: wireguard secrets, OBS config
  - Sets `config.my.hostName = "fredpc"`, `config.my.isWorkstation = true`

- [ ] **4.2** Create `modules/hosts/headscale.nix`:
  - Feature imports: hetzner-server, headscale-vpn, nginx-acme-proxy
  - Colmena node definitions (init + full)
  - Static IP networking from soft-secrets

- [ ] **4.3** Create `modules/hosts/ironforge.nix`:
  - Feature imports: hetzner-server, media-server, podman-server,
    nginx-acme-proxy
  - Colmena node definitions (init + full)

- [ ] **4.4** Create `modules/hosts/orgrimmar.nix`:
  - Feature imports: hetzner-server, gitea, woodpecker-ci, paperless, calibre,
    resume, podman-server, nginx-acme-proxy
  - Colmena node definitions (init + full)
  - Note: orgrimmar-init overrides `deployment.targetPort = 22`

- [ ] **4.5** Create `modules/hosts/anton.nix`:
  - Feature imports: wsl-server, nvidia-cuda
  - Colmena node definitions (init + full)
  - WSL-specific: `wsl.useWindowsDriver`, nix-ld

- [ ] **4.6** Create `modules/hosts/macbookx86.nix`:
  - Feature imports: gnome-desktop, linux-apps, pipewire-audio
  - Hardware: Apple T2 (nixos-hardware module), brcm WiFi firmware
  - NixOS system definition

- [ ] **4.7** Create `modules/hosts/nixosaarch64vm.nix`:
  - Minimal: disko, podman, soft-secrets
  - NixOS system definition
  - Note: preserves cross-arch pkgs quirk (x86 pkgsUnstable/pkgsStable on
    aarch64 host) — verify if intentional or a bug

- [ ] **4.8** Create `modules/hosts/mac-studio.nix`:
  - Feature imports: macos-prefs, workstation-apps, macos-security
  - Host overrides: external home dir (`/Volumes/External/Users/fdrake`),
    F13→Fn keyboard remap (Kinesis Advantage), trackpad scaling 2.0
  - Brews: container, steipete/tap/remindctl
  - Casks: mutedeck, naps2, proxy-audio-device, elgato-*, vmware-fusion
  - HM: archive-email launchd agent, ghostty font-size=16 override,
    wireguard-brainrush-stage secret
  - Sets `config.my.isWorkstation = true`

- [ ] **4.9** Create `modules/hosts/macbook-pro.nix`:
  - Feature imports: macos-prefs, workstation-apps, macos-security
  - Host overrides: `remapCapsLockToControl = true`
  - Casks: bartender, vmware-fusion
  - HM: 3 wireguard secrets, tailscale package
  - Sets `config.my.isWorkstation = true`

- [ ] **4.10** Create `modules/hosts/laisas-mac-mini.nix`:
  - Feature imports: macos-prefs, macos-security (minimal)
  - Casks: elgato-camera-hub, elgato-control-center only
  - `ids.gids.nixbld = 350` GID workaround
  - Sets `config.my.isWorkstation = false`

- [ ] **4.11** Delete remaining old directories:
  - `modules/nixos/` (fully migrated)
  - `modules/home-manager/` (fully migrated)
  - `modules/darwin/` (fully migrated)
  - `modules/secrets/` (decomposed into service features)
  - `systems/` (if not already deleted)
  - `colmena/` (if not already deleted)
  - `lib/mk-home-manager.nix` (if not already deleted)

- [ ] **4.12** Final verification:
  - `nix flake check`
  - `just build` on fredpc
  - `just switch` on mac-studio (or current Darwin host)
  - `colmena build --on headscale --impure`
  - `colmena build --on ironforge --impure`
  - `colmena build --on orgrimmar --impure`
  - `colmena build --on anton --impure`
  - `home-manager switch --flake .` standalone test

---

## What Stays Unchanged

| Directory/File | Reason |
|---|---|
| `apps/` | Custom packages, Claude Code config — not configuration modules |
| `homefiles/` | Raw dotfiles referenced by `home.file.*.source` |
| `overlays/` | Package overlays, referenced by `infra/pkgs.nix` |
| `shell.nix` | Dev shell, imported by `infra/devshell.nix` |
| All flake inputs | Only `flake-utils` removed; `flake-parts` + `import-tree` added |
| `secrets` private repo | No structural changes needed |
| Colmena node names | `headscale`, `headscale-init`, etc. — for deployment stability |
| `buildOnTarget = true` | All Colmena hosts build on target |

---

## Risk Register

| ID | Risk | Severity | Mitigation |
|---|---|---|---|
| R1 | `self.colmena._hostname` self-reference breaks | High | Replace with explicit module imports; base config becomes `.nix` file |
| R2 | Large PR — hard to bisect failures | High | Each phase is a separate PR passing `nix flake check` |
| R3 | Deployment breaks during migration | High | Keep Colmena node names stable; `colmena build` before `apply` |
| R4 | `soft-secrets` eval-time imports fail | Medium | Verify `inputs.secrets` accessible at module eval site in flake-parts |
| R5 | Colmena flake-parts module API gaps | Medium | Fall back to raw `flake.colmena` output if needed |
| R6 | nixosaarch64vm cross-arch pkgs quirk | Medium | Preserve as explicit override; investigate if intentional |
| R7 | `_module.args` for secrets in Colmena | Medium | Verify flake-parts colmena `specialArgs` support; keep `_module.args` fallback |
| R8 | HM `mkForce` overrides in host files | Low | Test host overrides still take precedence in deferredModule composition |
| R9 | `home.activation` ordering with new module structure | Low | `lib.hm.dag.entryAfter` is order-independent of module source |
| R10 | import-tree picks up non-module `.nix` files | Low | Keep non-module files in `apps/`, `homefiles/`, `overlays/` (outside `modules/`) |

---

## Reference Implementations

- https://github.com/mightyiam/infra — Pattern author's config
- https://github.com/vic/vix — Victor Borja's config (import-tree author)
- https://github.com/GaetanLepage/nix-config — Gaetan Lepage's config
- https://github.com/drupool/nixos-x260 — Pol Dellaiera (with blog post)

## Key Libraries

- **flake-parts** — `github:hercules-ci/flake-parts`
- **import-tree** — `github:vic/import-tree`
- **den** — `github:vic/den` (optional: aspect-oriented dendritic framework)

---

## Phase 0 Review Findings (2026-04-03)

Reviewed by: flake-manager, nix-module-architect, code-architect

### Warnings

**W1: `x86_64-darwin` dropped from supported systems**
`modules/infra/systems.nix` lists 3 systems (`x86_64-linux`, `aarch64-linux`,
`aarch64-darwin`). The original `flake-utils.lib.eachDefaultSystem` included
`x86_64-darwin` as a 4th system. This means `devShells` and future `perSystem`
outputs won't be available on Intel Macs. Likely intentional (no x86 Macs in
fleet) but is a behavioral change from the original.

**W2: import-tree scope diverges from plan**
Plan task 0.4 shows the target as `(inputs.import-tree ./modules)` but the
implementation correctly uses `(import-tree ./modules/infra)`. This is the
right call — `./modules` would pick up legacy NixOS/HM/Darwin modules that
aren't flake-parts modules.

**import-tree widening strategy**: As Phases 2-4 add new subdirectories, use
multiple `import-tree` calls merged into a list (flake-parts `mkFlake` accepts
a list of modules):
```nix
inputs.flake-parts.lib.mkFlake {inherit inputs;} [
  (import-tree ./modules/infra)
  (import-tree ./modules/features)   # added in Phase 2
  (import-tree ./modules/services)   # added in Phase 3
  (import-tree ./modules/hosts)      # added in Phase 4
];
```
Collapse to `(import-tree ./modules)` only after Phase 4 deletes all legacy
directories.

### Notes

**N1: Pre-existing bug — macbookx86 overlay path**
`systems/nixos.nix:18` (macbookx86 definition) uses
`import ./overlays/default.nix {inherit inputs;}` which resolves to
`systems/overlays/default.nix` — a path that doesn't exist. The fredpc block
correctly uses `../overlays/default.nix`. This means macbookx86 may have never
included the custom overlays. Pre-existing, not caused by Phase 0. Fix
separately.

**N2: Three flake-parts versions in flake.lock**
The lock contains three distinct `flake-parts` revisions:
- `flake-parts` (root) — latest
- `flake-parts_2` (nixvim's transitive dep) — ~2 months old
- `flake-parts_3` (nur's transitive dep) — Dec 2024, quite stale

Could be deduplicated by adding follows:
```nix
nixvim.inputs.flake-parts.follows = "flake-parts";
nur.inputs.flake-parts.follows = "flake-parts";
```
Not a correctness issue. Optional cleanup.

**N3: Unused args in wrapper modules**
- `colmena-config.nix` passes `nixos-hardware` to `colmena/default.nix` but
  it's never used (captured by `...`). Pre-existing in original flake.nix.
- `nixos-configs.nix` passes `colmena` to `systems/nixos.nix` but it's never
  used. Same situation. Both harmless and will be eliminated when the wrappers
  are replaced in Phase 1.

**N4: `outputs = inputs.self` correctness**
The wrappers use `outputs = inputs.self` where the original had
`inherit (self) outputs` (which computes `self.outputs`). In standard flake
evaluation `self` IS the outputs attrset, so `self.outputs` is technically a
self-reference. The wrapper's approach is arguably more correct. No behavioral
difference due to lazy evaluation.

**N5: devshell.nix dual-use preserved**
`shell.nix` has `pkgs ? import <nixpkgs> {}` as its default arg. In
flake-parts context, `perSystem` provides `pkgs` from the flake's nixpkgs.
Both `nix develop` (flake) and `nix-shell shell.nix` (legacy) continue to
work correctly.

**N6: nixvim and nixarr pin their own nixpkgs**
Neither `nixvim` nor `nixarr` have `inputs.nixpkgs.follows = "nixpkgs"`,
meaning they evaluate against their own pinned nixpkgs. This is pre-existing
and intentional for compatibility. Not introduced by Phase 0.
