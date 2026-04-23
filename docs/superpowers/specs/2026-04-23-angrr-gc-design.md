# Automatic Nix Garbage Collection (angrr + nix.gc)

**Date:** 2026-04-23
**Status:** Approved, ready for implementation plan
**Scope:** All NixOS and Darwin hosts in this flake

## Problem

This flake has no automatic garbage collection on any NixOS host (`fredpc`,
`macbookx86`, `nixosaarch64vm`, `headscale`, `ironforge`, `orgrimmar`, `anton`).
Darwin hosts already run `nix.gc` weekly with a 7-day cutoff, but the settings
live alongside unrelated daemon config. Over time, servers accumulate store
paths without bound, and workstations keep stale `nix-direnv` GC roots that
prevent `nix-collect-garbage` from reclaiming space even when it runs.

[angrr](https://github.com/linyinfeng/angrr) addresses the GC-root side of this
problem: it prunes stale roots left by `nix-direnv`, `nix-build`, and old
profile generations, so subsequent `nix-collect-garbage` runs can actually
free space. It is a supplement to `nix.gc`, not a replacement — `nix.gc` still
does the actual collection. Angrr's `enableNixGcIntegration` (auto-enabled
whenever `nix.gc.automatic = true`) wires `angrr.service` to run
`Before=nix-gc.service`, so the two always run in the right order on the
same timer.

## Goals

- Automatic Nix garbage collection on every host in the flake.
- Consistent retention policy across NixOS and Darwin.
- Stale `nix-direnv` GC roots and `result/` symlinks get cleaned up.
- Always keep a rollback safety floor of recent generations, even on
  long-idle hosts.
- Any host can opt out of automatic GC with a one-line change.
- Settings live in a dedicated feature module — not scattered across
  daemon config.

## Non-goals

- Enabling `nix.settings.auto-optimise-store` (build-time deduplication).
  Periodic `nix.optimise.automatic` is enough and avoids the historical
  store-corruption risk of the build-time variant.
- Pruning home-manager user-profile generations independently of system
  profiles. Angrr's preset sets `profile-policies.user.enable = false`;
  we accept that default.
- Enabling the angrr direnv auto-touch hook in the MVP. See
  [Deferred: direnv auto-touch](#deferred-direnv-auto-touch) below for why.
- Rolling out to a subset of hosts first. The capability flag defaults to
  `true` on every host.

## Decisions

| Decision | Value | Rationale |
|----------|-------|-----------|
| Scope | All NixOS + Darwin hosts | Uniform behavior simplifies reasoning. |
| Retention | 14 days | Moderate — angrr's preset default. |
| Cadence | Daily | `nix.gc.dates = "daily"`; angrr rides the same timer via `enableNixGcIntegration`. |
| Generation safety floor | Keep last 3 system generations | Override the preset's `keep-latest-n = 5` to trim more aggressively. |
| Store optimisation | Periodic only (`nix.optimise.automatic`) | Dedup without build-time latency or corruption risk. |
| Opt-out mechanism | `my.hasAutoGc` capability flag, default `true` | Matches dendritic pattern; per-host opt-out is one line. |

## Architecture

Two sibling feature modules under `modules/features/`, each registered via
the dendritic `my.modules.{nixos,darwin}` deferred-module pattern:

- `nixos-auto-gc.nix` — NixOS: `nix.gc`, `nix.optimise`, `services.angrr`.
- `darwin-auto-gc.nix` — Darwin: `nix.gc`, `nix.optimise.automatic` only
  (angrr is NixOS-only).

Both modules guard their configuration on `config.my.hasAutoGc` via
`lib.mkIf`. The capability flag is defined in `lib/my-options-module.nix`
alongside the existing `has*` flags.

The angrr flake is added as a new flake input in `flake.nix` with
`inputs.nixpkgs.follows = "nixpkgs"`. Its NixOS module is imported inside
`nixos-auto-gc.nix` (via the feature module's `imports` list), keeping the
angrr dependency fully localized to the feature that needs it.

The existing `modules/darwin/features/nix-daemon.nix` loses its `nix.gc` and
`nix.optimise.automatic` stanzas — those move to `darwin-auto-gc.nix`. What
remains in `nix-daemon.nix` is the daemon's own config (`extraOptions`,
`settings`).

### Why not a single unified module?

A single file registering into both `my.modules.nixos.auto-gc` and
`my.modules.darwin.auto-gc` was considered. Rejected because NixOS-only
concerns (angrr) would sit alongside Darwin code in the same file, and
readers would have to mentally filter. The two-file split matches the
existing convention in `modules/features/` (`darwin-nix-daemon.nix` vs
`prometheus-node-exporter.nix`, etc.).

### Why not extend existing modules?

Adding GC to `nixos-base.nix` was considered and rejected: that module is
unconditional by design, and introducing a capability flag there breaks its
"base = applies to every NixOS host unconditionally" contract. Extending
`darwin/features/nix-daemon.nix` to hold the new numbers was also rejected
because it conflates daemon config with GC policy in the same file.

## Component specifications

### Capability flag (`lib/my-options-module.nix`)

Add alongside other `has*` flags:

```nix
hasAutoGc = lib.mkOption {
  type = lib.types.bool;
  default = true;
  description = ''
    Automatic Nix garbage collection. On NixOS, enables angrr to prune stale
    GC roots (direnv, nix-build) plus nix.gc for actual store collection.
    On Darwin, enables nix.gc and nix.optimise. Disable per-host with
    `my.hasAutoGc = false;` if a host needs manual control.
  '';
};
```

### Flake input (`flake.nix`)

Add to the `inputs` block:

```nix
angrr = {
  url = "github:linyinfeng/angrr";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

### NixOS feature module (`modules/features/nixos-auto-gc.nix`)

```nix
{inputs, ...}: {
  my.modules.nixos.auto-gc = {
    config,
    lib,
    ...
  }: {
    imports = [inputs.angrr.nixosModules.default];
    config = lib.mkIf config.my.hasAutoGc {
      nix.gc = {
        automatic = true;
        dates = "daily";
        options = "--delete-older-than 14d";
        randomizedDelaySec = "45min";
      };
      nix.optimise = {
        automatic = true;
        dates = ["weekly"];
      };

      services.angrr = {
        enable = true;
        # `period` is a preset: configures temporary-root-policies (direnv, result/)
        # and profile-policies (system, user) with 14d retention.
        period = "14d";
        # Trim the preset's 5-generation default down to 3 for tighter disk use.
        settings.profile-policies.system.keep-latest-n = 3;
      };
    };
  };
}
```

- `services.angrr.period = "14d"` triggers angrr's built-in preset, which
  populates `temporary-root-policies` (matching `.direnv/` paths and
  `result*` symlinks) and `profile-policies` (system profile, with user
  profile `enable = false`).
- `services.angrr.enableNixGcIntegration` auto-defaults to `true` when
  `nix.gc.automatic = true`, so angrr runs as a `Before=nix-gc.service`
  dependency and shares the daily `nix-gc` timer. We don't set it
  explicitly — relying on the default keeps it self-adjusting.
- `randomizedDelaySec = "45min"` staggers the nix-gc timer across hosts
  (and angrr along with it) so Hetzner servers don't all wake at the same
  wall-clock moment.
- `nix.optimise.dates = ["weekly"]` because optimisation doesn't benefit
  from daily churn.
- `keep-latest-n = 3` overrides the preset's default of `5`, matching the
  chosen safety floor.

### Darwin feature module (`modules/features/darwin-auto-gc.nix`)

```nix
_: {
  my.modules.darwin.auto-gc = {
    config,
    lib,
    ...
  }:
    lib.mkIf config.my.hasAutoGc {
      nix.gc = {
        automatic = true;
        interval = [
          {
            Hour = 4;
            Minute = 30;
          }
        ];
        options = "--delete-older-than 14d";
      };
      nix.optimise.automatic = true;
    };
}
```

- `interval` is a launchd `StartCalendarInterval` entry; omitting `Weekday`
  makes it fire every day at 04:30.
- No randomized delay (launchd doesn't expose it the same way); acceptable
  since Darwin hosts are few and personal-use.
- No angrr, no direnv hook — both NixOS-only.

### Migration: `modules/darwin/features/nix-daemon.nix`

Remove the `nix.gc` and `nix.optimise.automatic` blocks. The file becomes:

```nix
{config, ...}: {
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings = {
      cores = 0;
      sandbox = false;
      trusted-users = ["root" config.my.username];
    };
  };
}
```

## Deferred: direnv auto-touch

The original design called for angrr's direnv auto-touch hook
(`programs.direnv.angrr.enable`), which calls `angrr touch --project` on
every direnv activation so actively-used projects survive the 14-day
cutoff. This is **deferred** from the MVP.

**Reason:** the angrr NixOS module only activates the hook when
`programs.direnv.enable` is `true` **at the NixOS level**. This flake
enables direnv exclusively through home-manager
(`modules/home-manager/features/dev-tools.nix`). Turning on the NixOS
option alongside the home-manager one risks:

- Duplicate direnv shell hooks in `/etc/*rc` and user shell configs (runtime
  harmless but noisy).
- Option conflicts on shared sub-paths (e.g. `nix-direnv.enable`) where
  both module trees declare opinions.

The safer MVP is to accept that direnv GC roots get pruned after 14 days of
inactivity. Users who re-enter a dormant project after the cutoff will pay
a one-time `nix-direnv` re-evaluation cost on that project's next `cd`.

**Follow-up plan:** after the MVP lands and stabilizes, evaluate on a
single workstation (likely `fredpc`) whether enabling NixOS
`programs.direnv.enable = true` alongside home-manager direnv causes
option conflicts. If not, add `programs.direnv.enable = true` and
`programs.direnv.angrr.enable = true` to `nixos-auto-gc.nix` (guarded by
the same `my.hasAutoGc` flag). Alternatively, wire the angrr direnv stdlib
into home-manager's `programs.direnv.stdlib` directly, bypassing the NixOS
integration entirely.

## Data flow

1. `flake.nix` exposes `inputs.angrr`.
2. `modules/features/nixos-auto-gc.nix` is picked up by `import-tree` and
   registers into `config.my.modules.nixos.auto-gc`.
3. `lib/nixos-infra.nix` collects `my.modules.nixos.*` attributes into
   `deferredNixosModules`, which flows into `commonModules` imported by
   every `nixosSystem` in `modules/hosts/nixos.nix`.
4. For Hetzner servers, the same `commonModules` list is threaded into
   `colmena/default.nix` via `nixosOptionsModule` and
   `deferredNixosModules` passed to each `colmena/hosts/*.nix`.
5. When a host's `config.my.hasAutoGc` is `true` (the default), the
   `lib.mkIf` guard expands the `nix.gc`, `nix.optimise`, and
   `services.angrr` settings into the final system config. The module
   system auto-wires `services.angrr.enableNixGcIntegration = true`
   because `nix.gc.automatic = true`, making angrr run
   `Before=nix-gc.service` on the daily `nix-gc.timer`.
6. Darwin hosts follow the analogous path through `lib/darwin-infra.nix`
   and `modules/hosts/darwin.nix`, activating `darwin-auto-gc.nix`.

## Verification

After `just switch` on a NixOS workstation:

- `systemctl list-timers | grep nix-gc` — timer active with daily schedule.
- `systemctl list-dependencies nix-gc.service` — should show angrr.service
  as a `Before` dependency.
- `journalctl -u angrr.service -n 50` after the first run.
- `sudo nix-collect-garbage --dry-run` — sanity-check what would be freed.

After `just switch` on a Darwin host:

- `sudo launchctl list | grep nix-gc` — scheduled job exists.
- `sudo nix-collect-garbage --dry-run` — same sanity check.

After `colmena apply` on a Hetzner server:

- SSH and run the same NixOS commands above.
- Confirm `randomizedDelaySec` has spread the fire time across servers.

## Rollback

Per-host opt-out:

```nix
my.hasAutoGc = false;
```

Global rollback: `git revert` the PR. All state is in systemd timers and
launchd jobs, which get torn down by the next `just switch` /
`colmena apply` after revert. No persistent data to clean up.

## Open questions

None. The direnv auto-touch conflict is resolved by deferring it from the
MVP (documented above).
