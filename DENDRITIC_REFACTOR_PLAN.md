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

- [ ] **2.1** Create `modules/features/shells.nix`:
  - System-level: `programs.fish.enable`, `programs.zsh.enable` (NixOS + Darwin)
  - HM-level: oh-my-posh, fzf, zoxide, carapace, fish config
  - `home.sessionVariables` (LANG, TERM, PAGER, CLICOLOR, GHQ_ROOT, etc.)
  - `home.shellAliases` (man=batman, lg, ranger=yy, vpn-*)
  - Imports `apps/zsh.nix`, `apps/fish.nix`
  - Darwin-only: HOMEBREW_* session vars (via `mkIf isDarwin`)

- [ ] **2.2** Create `modules/features/editor.nix`:
  - `programs.helix` (full config: theme, settings, keys, language servers, languages)
  - `programs.lazygit`
  - `programs.jq`
  - `editorconfig` settings

- [ ] **2.3** Create `modules/features/dev-tools.nix`:
  - `programs.git` (full config with delta, lfs, signing)
  - `programs.direnv`, `programs.atuin`
  - `programs.nix-index`, `programs.nix-index-database.comma`
  - Language server packages: nil, nixd, rust-analyzer, pylyzer, gopls,
    clang-tools, vscode-langservers-extracted, yaml-language-server, prettier,
    taplo, jdt-language-server, marksman, markdown-oxide
  - Dev packages: age, delta, devenv, fd, ghq, gnupg, jaq, ripgrep, tokei
  - Container tools: docker-compose, kind, kubectl, lazydocker
  - Darwin brew additions: cmake, ruby-install (via `mkIf isDarwin`)

- [ ] **2.4** Create `modules/features/terminal.nix`:
  - Imports `apps/tmux.nix`, tmux-windev-settings
  - `programs.bat` (with bat-extras), `programs.bottom`, `programs.yazi`
  - Packages: btop, chafa, curl, dua, duf, eza, fastfetch, highlight, imgcat,
    ncdu, skim, television, tldr, tmux, tmux-mem-cpu-load
  - Platform split: `wl-clipboard` (Linux), `mermaid-cli-wrapped` (Darwin)

- [ ] **2.5** Create `modules/features/dotfiles.nix`:
  - `home.file` entries: SSH config (from soft-secrets), `.ssh/*`, `.config/*`,
    ghostty config, television config, Pictures, `.hgignore_global`,
    `.ideavimrc`, `.wezterm.lua`
  - `home.activation` entries: ssh-restrict, ssh-authorized-keys-copy,
    zed-settings-copy
  - Platform-conditional paths for discordo config

- [ ] **2.6** Create `modules/features/vscode-family.nix`:
  - VS Code / Cursor / Windsurf settings.json and keybindings.json
  - Platform-conditional paths: `Library/Application Support/` (Darwin) vs
    `.config/` (Linux)
  - `windsurf-code` wrapper script (Darwin only)

- [ ] **2.7** Create `modules/features/media-apps.nix`:
  - Packages: ffmpeg, imagemagick, openai-whisper, yt-dlp, chafa
  - Workstation-only packages (gated by `config.my.isWorkstation`): discord,
    slack, spotify, inkscape, podman, podman-tui
  - localsend, wiki-tui

- [ ] **2.8** Create `modules/features/network-tools.nix`:
  - Packages: curl, wget, inetutils, lsof, rsync, wireguard-tools,
    minio-client, restic, syncthing, stc-cli, woodpecker-cli, hclfmt,
    openssl, sops, unzip

- [ ] **2.9** Create `modules/features/ai-tools.nix`:
  - Packages: llama-cpp, tdd-guard, agent-browser, ccstatusline, gws
  - `SOPS_AGE_KEY_FILE`, `PODMAN_COMPOSE_WARNING_LOGS` session vars

- [ ] **2.10** Create `modules/features/claude-code.nix`:
  - Migrate from `modules/home-manager/claude-code.nix`
  - Claude Code package, MCP SOPS templates, `.claude/*` files, agents, skills,
    commands, assets, LSP plugin
  - Deduplicate LSP packages shared with dev-tools

- [ ] **2.11** Create `modules/features/secrets.nix` (HM secrets):
  - Migrate from `modules/home-manager/secrets.nix`
  - Workstation sops declarations
  - Darwin launchd sops-nix PATH workaround (via `mkIf isDarwin`)

- [ ] **2.12** Create `modules/features/nixvim.nix`:
  - Nixvim import (from `apps/nixvim`)
  - Currently imported as part of HM base — becomes its own feature

- [ ] **2.13** Create `modules/features/nix-daemon.nix`:
  - `nix.gc`, `nix.settings`, `nix.optimise`, `nix.extraOptions`
  - `trusted-users`, `sandbox` settings
  - Shared between NixOS and Darwin (both support these options)

- [ ] **2.14** Create `modules/features/fonts.nix`:
  - `fonts.packages` — nerd-fonts.hack, jetbrains-mono, meslo-lg
  - Shared between NixOS and Darwin

- [ ] **2.15** Create `modules/features/user-fdrake.nix`:
  - NixOS: `users.users.fdrake` definition
  - Darwin: `users.knownUsers`, `users.users.fdrake` with uid/home/shell
  - Darwin: `system.primaryUser = "fdrake"`
  - Platform-conditional via `mkIf`

- [ ] **2.16** Create `modules/features/macos-prefs.nix`:
  - `system.defaults.*` (dock, finder, trackpad, NSGlobalDomain,
    screencapture, SoftwareUpdate, WindowManager, menuExtraClock)
  - `system.stateVersion = 4`
  - Darwin-only feature

- [ ] **2.17** Create `modules/features/macos-security.nix`:
  - Touch ID sudo (`security.pam.services.sudo_local.touchIdAuth`)
  - pam-reattach (`environment.etc."pam.d/sudo_local"`)
  - Darwin-only feature

- [ ] **2.18** Create `modules/features/workstation-apps.nix`:
  - Homebrew casks list (gated by `config.my.isWorkstation`)
  - masApps (RunCat, Unarchiver, WireGuard, Xcode)
  - `homebrew.onActivation`, `homebrew.global.brewfile`
  - Darwin-only feature

- [ ] **2.19** Create `modules/features/hyprland-desktop.nix`:
  - **NixOS deferredModule**: `programs.hyprland.enable`, system packages
    (waybar, wofi, hyprshot), XDG portal, polkit
  - **HM deferredModule**: `wayland.windowManager.hyprland` settings, waybar
    config, spotifatius, mako notifications, hypridle, hyprlock, GTK/Qt dark
    themes, wlogout
  - Consolidates `modules/nixos/host/fredpc/hyprland.nix` +
    `modules/home-manager/hyprland/*`

- [ ] **2.20** Create `modules/features/gnome-desktop.nix`:
  - **NixOS deferredModule**: services.desktopManager.gnome, GDM, dconf
    profiles
  - **HM deferredModule**: dconf settings, gnome-tweaks, extensions
  - Consolidates `modules/nixos/host/fredpc/gnome.nix` + parts of
    `modules/home-manager/linux-desktop.nix`

- [ ] **2.21** Create `modules/features/linux-apps.nix`:
  - HM packages: albert, bitwarden-desktop, brave, gnome-tweaks, zed-editor
  - `services.mako` (notification daemon)
  - `programs.firefox` with addons (guarded by `inputs.firefox-addons`)
  - Linux-only feature

- [ ] **2.22** Create `modules/features/pipewire-audio.nix`:
  - NixOS: Pipewire stack (services.pipewire, pulse, alsa, wireplumber)
  - Used by fredpc and macbookx86

- [ ] **2.23** Delete `modules/home-manager/default.nix`
- [ ] **2.24** Delete `modules/home-manager/darwin.nix`
- [ ] **2.25** Delete `modules/home-manager/linux-desktop.nix`
- [ ] **2.26** Delete `modules/home-manager/hyprland/` directory
- [ ] **2.27** Delete `modules/home-manager/tmux-windev-settings.nix`
- [ ] **2.28** Delete `modules/darwin/default.nix` (content migrated to features)
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
