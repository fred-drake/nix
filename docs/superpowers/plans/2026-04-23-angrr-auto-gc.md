# Automatic Nix Garbage Collection (angrr + nix.gc) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire automatic Nix garbage collection into every NixOS and Darwin host in this flake, gated behind a new `my.hasAutoGc` capability flag that defaults to `true`.

**Architecture:** Two sibling dendritic feature modules (`modules/features/nixos-auto-gc.nix` and `modules/features/darwin-auto-gc.nix`) register into `config.my.modules.{nixos,darwin}.auto-gc`. The NixOS module uses angrr's `period = "14d"` preset and relies on its auto-enabled `nix-gc.service` integration so angrr rides the existing `nix-gc.timer`. The Darwin module only sets `nix.gc` + `nix.optimise.automatic`. Existing Darwin GC stanzas in `modules/darwin/features/nix-daemon.nix` move out.

**Tech Stack:** Nix flakes (flake-parts, import-tree), NixOS module system, nix-darwin, Colmena, [angrr](https://github.com/linyinfeng/angrr) (Rust service via NixOS module).

---

## File Structure

| Path | Action | Responsibility |
|------|--------|----------------|
| `lib/my-options-module.nix` | Modify | Add `hasAutoGc` capability flag option |
| `flake.nix` | Modify | Add `angrr` flake input |
| `flake.lock` | Modify (tool-generated) | Lock new angrr input |
| `modules/features/nixos-auto-gc.nix` | Create | NixOS feature: `nix.gc`, `nix.optimise`, `services.angrr` |
| `modules/features/darwin-auto-gc.nix` | Create | Darwin feature: `nix.gc`, `nix.optimise.automatic` |
| `modules/darwin/features/nix-daemon.nix` | Modify | Remove `nix.gc` and `nix.optimise.automatic` stanzas |

Each feature module is self-contained — the NixOS one imports angrr's module locally so the dependency isn't leaked into `commonModules`. The Darwin module never references angrr.

---

### Task 1: Add `my.hasAutoGc` capability flag

**Files:**
- Modify: `lib/my-options-module.nix`

The flag must exist before any feature module references it, otherwise `config.my.hasAutoGc` evaluates to an error during flake eval.

- [ ] **Step 1: Add the option to `my-options-module.nix`**

Open `lib/my-options-module.nix`. Add the new `hasAutoGc` option inside `options.my` — alphabetical position doesn't matter (existing flags aren't strictly sorted), but put it near the other `has*` flags. Recommended placement: directly after `hasWoodpeckerAgent`, before the closing brace.

Exact text to add (indented to match existing `has*` entries):

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

- [ ] **Step 2: Verify the flake still evaluates**

Run:

```bash
nix eval .#nixosConfigurations.headscale.config.my.hasAutoGc
```

Expected output: `true`

Run:

```bash
nix eval .#darwinConfigurations.mac-studio.config.my.hasAutoGc
```

Expected output: `true`

If either errors with "option ... does not exist", the option wasn't added into the correct `options.my` attrset — re-check the placement.

- [ ] **Step 3: Commit**

```bash
git add lib/my-options-module.nix
git commit -m "feat(options): add my.hasAutoGc capability flag

Default true. Gates automatic Nix GC (angrr + nix.gc) in the
upcoming nixos-auto-gc and darwin-auto-gc feature modules."
```

---

### Task 2: Add angrr flake input

**Files:**
- Modify: `flake.nix`
- Modify: `flake.lock` (tool-generated)

- [ ] **Step 1: Add angrr to the `inputs` block**

Open `flake.nix`. Locate the `inputs = { ... }` block. Add the angrr input. The exact placement doesn't matter — a natural spot is after `nixarr` (the last existing input). Add:

```nix
    # Auto Nix GC root retention — prunes stale direnv, result/, and profile
    # GC roots so nix-collect-garbage can actually free disk. Runs as
    # Before=nix-gc.service via angrr's enableNixGcIntegration (auto-true
    # when nix.gc.automatic = true).
    angrr = {
      url = "github:linyinfeng/angrr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
```

- [ ] **Step 2: Lock the new input**

Run:

```bash
nix flake lock --update-input angrr
```

Expected: command emits "• Added input 'angrr'" and updates `flake.lock` with a resolved rev/narHash. No error output.

If the command is not recognized (Nix versions before 2.19), use:

```bash
nix flake lock
```

Either way, confirm `flake.lock` now contains a top-level `"angrr"` entry:

```bash
grep -c '"angrr"' flake.lock
```

Expected: count `>= 1`.

- [ ] **Step 3: Verify the flake still evaluates**

Run:

```bash
nix flake check --no-build
```

Expected: no errors. Warnings are acceptable.

Then verify the angrr NixOS module is reachable:

```bash
nix eval .#inputs.angrr.nixosModules.default --apply 'x: builtins.typeOf x'
```

Expected output: `"lambda"` or `"set"` (module functions are lambdas; module sets are sets — either is fine).

- [ ] **Step 4: Commit**

```bash
git add flake.nix flake.lock
git commit -m "feat(flake): add angrr input for auto GC root pruning

Pins nixpkgs to the flake's main nixpkgs. Not yet consumed by any
module — the nixos-auto-gc feature module in the next commit wires it in."
```

---

### Task 3: Create NixOS feature module `nixos-auto-gc.nix`

**Files:**
- Create: `modules/features/nixos-auto-gc.nix`

This is the dendritic feature module that registers into `config.my.modules.nixos.auto-gc`. It imports angrr's NixOS module locally (so the dependency stays contained) and applies the full set of GC options guarded by `my.hasAutoGc`.

- [ ] **Step 1: Create the file**

Create `modules/features/nixos-auto-gc.nix` with exactly this content:

```nix
# Automatic Nix garbage collection for NixOS hosts.
# Combines angrr (prunes stale GC roots: direnv, result/, old generations)
# with nix.gc (actually deletes unreferenced store paths) and
# nix.optimise (hard-links duplicate store files on a weekly timer).
#
# angrr.enableNixGcIntegration auto-defaults to true whenever
# nix.gc.automatic = true, which wires angrr.service to run
# Before=nix-gc.service on the same daily nix-gc.timer.
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
        # Preset: generates temporary-root-policies (direnv, result/) and
        # profile-policies (system with keep-latest-n=5, user disabled) with
        # the given retention period.
        period = "14d";
        # Trim the preset's 5-generation default to 3 for tighter disk use.
        settings.profile-policies.system.keep-latest-n = 3;
      };
    };
  };
}
```

- [ ] **Step 2: Verify the module is discovered and evaluates**

Run:

```bash
nix eval .#nixosConfigurations.fredpc.config.nix.gc.automatic
```

Expected: `true` (because `my.hasAutoGc` defaults to `true`).

Run:

```bash
nix eval .#nixosConfigurations.fredpc.config.nix.gc.options
```

Expected: `"--delete-older-than 14d"`

Run:

```bash
nix eval .#nixosConfigurations.fredpc.config.services.angrr.enable
```

Expected: `true`

Run:

```bash
nix eval .#nixosConfigurations.fredpc.config.services.angrr.enableNixGcIntegration
```

Expected: `true` (module auto-defaults this when nix.gc.automatic = true).

Run (confirm the keep-latest-n override landed):

```bash
nix eval .#nixosConfigurations.fredpc.config.services.angrr.settings.profile-policies.system.keep-latest-n
```

Expected: `3`

Spot-check one Hetzner server to confirm the feature reaches Colmena hosts too:

```bash
nix eval .#nixosConfigurations.headscale.config.services.angrr.enable
```

Expected: `true`

- [ ] **Step 3: Verify opt-out works**

Without making a permanent change, override `my.hasAutoGc` at eval time:

```bash
nix eval --impure --expr '
  let flake = builtins.getFlake (toString ./.);
      sys = flake.nixosConfigurations.fredpc.extendModules {
        modules = [{ my.hasAutoGc = false; }];
      };
  in sys.config.nix.gc.automatic
'
```

Expected: `false` (since the `lib.mkIf` guard turns off the whole config block).

- [ ] **Step 4: Build one host to prove the closure evaluates**

```bash
nix build .#nixosConfigurations.fredpc.config.system.build.toplevel --no-link --dry-run
```

Expected: command reports what *would* be built/fetched, then exits 0 without errors. The output of `--dry-run` for a host not yet deployed with angrr will list angrr-related store paths to fetch.

- [ ] **Step 5: Format and commit**

```bash
just format
git add modules/features/nixos-auto-gc.nix
git commit -m "feat(features): add nixos-auto-gc dendritic feature module

Enables nix.gc (daily, 14d retention), nix.optimise (weekly), and
services.angrr (14d preset, keep-latest-n=3 override) on every
NixOS host where my.hasAutoGc is true (the default). Angrr rides
the nix-gc.timer via enableNixGcIntegration."
```

---

### Task 4: Create Darwin feature module and migrate existing GC settings

**Files:**
- Create: `modules/features/darwin-auto-gc.nix`
- Modify: `modules/darwin/features/nix-daemon.nix`

These two changes must happen in a **single commit**. If we add `darwin-auto-gc.nix` while the old stanzas still exist in `nix-daemon.nix`, both modules set `nix.gc.automatic` — leading to option merging with conflicting values (`dates` vs `interval.Weekday=2`, different `--delete-older-than`).

- [ ] **Step 1: Create `modules/features/darwin-auto-gc.nix`**

Create the file with exactly this content:

```nix
# Automatic Nix garbage collection for Darwin hosts.
# Darwin has no angrr equivalent — we rely on nix.gc to clean up store
# paths and nix.optimise to hard-link duplicates on its own timer.
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

- [ ] **Step 2: Strip GC stanzas from `modules/darwin/features/nix-daemon.nix`**

Open `modules/darwin/features/nix-daemon.nix`. Replace the entire file contents with:

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

The removed portion was the `gc = { automatic, interval, options }` block and the `optimise.automatic = true` line. Everything else stays.

- [ ] **Step 3: Verify Darwin config still evaluates and GC is set correctly**

Run:

```bash
nix eval .#darwinConfigurations.mac-studio.config.nix.gc.automatic
```

Expected: `true`

Run:

```bash
nix eval .#darwinConfigurations.mac-studio.config.nix.gc.options
```

Expected: `"--delete-older-than 14d"`

Run (confirm daily cadence — no Weekday key means every day):

```bash
nix eval .#darwinConfigurations.mac-studio.config.nix.gc.interval --json
```

Expected JSON: `[{"Hour":4,"Minute":30}]` (no `Weekday` field).

Run:

```bash
nix eval .#darwinConfigurations.mac-studio.config.nix.optimise.automatic
```

Expected: `true`

Spot-check the other two Darwin hosts to confirm the feature reaches all of them:

```bash
nix eval .#darwinConfigurations.macbook-pro.config.nix.gc.automatic
nix eval .#darwinConfigurations.laisas-mac-mini.config.nix.gc.automatic
```

Expected: `true` for both.

- [ ] **Step 4: Build one Darwin host to prove the closure evaluates**

```bash
nix build .#darwinConfigurations.mac-studio.system --no-link --dry-run
```

Expected: command succeeds (may list paths to fetch/build), exits 0.

- [ ] **Step 5: Format and commit**

```bash
just format
git add modules/features/darwin-auto-gc.nix modules/darwin/features/nix-daemon.nix
git commit -m "feat(features): add darwin-auto-gc; strip GC from nix-daemon

Moves nix.gc and nix.optimise.automatic out of the darwin-nix-daemon
feature into a dedicated darwin-auto-gc feature guarded by
my.hasAutoGc. Also changes retention from 7d weekly to 14d daily
to match the new uniform policy across NixOS and Darwin."
```

---

### Task 5: Validate the full flake

**Files:** (none modified — validation only)

Confirm every host config in the flake builds after the changes.

- [ ] **Step 1: Full flake check**

```bash
nix flake check
```

Expected: exits 0. Warnings about things unrelated to this change (e.g. pre-existing deprecation warnings in other modules) are fine. Any evaluation error or `option '...' is already defined` error is a **stop** — investigate before proceeding.

- [ ] **Step 2: Dry-build every NixOS host**

Run each of these in sequence. Each should succeed with exit 0.

```bash
nix build .#nixosConfigurations.fredpc.config.system.build.toplevel --no-link --dry-run
nix build .#nixosConfigurations.macbookx86.config.system.build.toplevel --no-link --dry-run
nix build .#nixosConfigurations.nixosaarch64vm.config.system.build.toplevel --no-link --dry-run
nix build .#nixosConfigurations.headscale.config.system.build.toplevel --no-link --dry-run
nix build .#nixosConfigurations.ironforge.config.system.build.toplevel --no-link --dry-run
nix build .#nixosConfigurations.orgrimmar.config.system.build.toplevel --no-link --dry-run
nix build .#nixosConfigurations.anton.config.system.build.toplevel --no-link --dry-run
```

Expected: each exits 0.

- [ ] **Step 3: Dry-build every Darwin host**

```bash
nix build .#darwinConfigurations.mac-studio.system --no-link --dry-run
nix build .#darwinConfigurations.macbook-pro.system --no-link --dry-run
nix build .#darwinConfigurations.laisas-mac-mini.system --no-link --dry-run
```

Expected: each exits 0.

- [ ] **Step 4: Confirm timer wiring on a NixOS host**

```bash
nix eval .#nixosConfigurations.fredpc.config.systemd.services.angrr.before
```

Expected: list containing `"nix-gc.service"` (this is how `enableNixGcIntegration` expresses itself).

```bash
nix eval .#nixosConfigurations.fredpc.config.systemd.services.angrr.wantedBy
```

Expected: list containing `"nix-gc.service"`.

```bash
nix eval .#nixosConfigurations.fredpc.config.systemd.timers.nix-gc.timerConfig.OnCalendar --json
```

Expected: `"daily"` (or an equivalent calendar spec that resolves to daily).

If any of these fail with "attribute ... missing", angrr's module didn't get imported or `nix.gc.automatic` didn't flip the integration. Verify Task 3's module wrote `services.angrr.enable = true` and that the eval in Task 3 Step 2 succeeded.

- [ ] **Step 5: No commit**

This task is validation-only. Nothing to commit.

---

### Task 6: Deploy to one workstation as a smoke test

**Files:** (none — deployment)

Roll out to a single workstation first. This catches any runtime issue (e.g. angrr package failing to build for a specific arch) before we touch servers.

- [ ] **Step 1: Pick the local workstation**

If running on Darwin (mac-studio, macbook-pro, laisas-mac-mini):

```bash
just switch
```

If running on NixOS (fredpc, macbookx86):

```bash
just switch
```

Either way, expected: build succeeds, new generation activated. The switch output should reference `nix-gc.service` (NixOS) or the renamed `nix-gc` launchd job (Darwin).

- [ ] **Step 2: Confirm timers/jobs actually exist on disk**

On NixOS:

```bash
systemctl list-timers nix-gc.timer
```

Expected: one row showing `nix-gc.timer` with a next-activation time within ~24h.

```bash
systemctl list-dependencies nix-gc.service | grep angrr
```

Expected: shows `angrr.service` listed under `Before`/wants. If nothing prints, the integration didn't wire — re-check `services.angrr.enableNixGcIntegration` eval from Task 5 Step 4.

```bash
systemctl status angrr.service
```

Expected: unit is loaded, `Active: inactive (dead)` is normal before first run; `Loaded: loaded` is what matters.

On Darwin:

```bash
sudo launchctl list | grep -i nix-gc
```

Expected: one line showing the nix-gc launchd job.

- [ ] **Step 3: Trigger an immediate angrr run (NixOS only) and inspect the log**

```bash
sudo systemctl start angrr.service
journalctl -u angrr.service -n 50 --no-pager
```

Expected: log entries ending with a success/exit status. Typical output mentions scanned GC roots and how many (if any) were pruned. No traceback or "error:" lines.

- [ ] **Step 4: Sanity-check with a dry-run GC**

```bash
sudo nix-collect-garbage --dry-run | tail -20
```

Expected: command succeeds; output lists what *would* be freed. Numbers will vary.

- [ ] **Step 5: No commit**

This task is deployment validation only.

---

### Task 7: Roll out to remaining workstation and servers

**Files:** (none — deployment)

- [ ] **Step 1: Deploy to the other local workstation class**

If Task 6 ran on Darwin, now switch to a NixOS workstation (or vice versa). Boot into it, pull the latest commits, and run `just switch`.

If there is no second local workstation available right now, skip to Step 2. The flake evaluation in Task 5 already proved all host closures evaluate; remote rebuild is the only outstanding risk.

- [ ] **Step 2: Deploy to each Hetzner server via Colmena**

Deploy one at a time, waiting for each to finish before starting the next:

```bash
just colmena headscale
just colmena ironforge
just colmena orgrimmar
```

Expected for each: `colmena apply` completes with "All done!" and no red error output. Note the `randomizedDelaySec = "45min"` setting means their `nix-gc.timer` fire times will differ — that's intentional.

- [ ] **Step 3: Deploy to the WSL host**

```bash
just colmena anton
```

Expected: same as above. If `anton` is not online (laptop closed), skip and defer until it's available.

- [ ] **Step 4: Post-deploy verification on servers**

For each deployed server (headscale, ironforge, orgrimmar, anton):

```bash
ssh root@<server> 'systemctl list-timers nix-gc.timer && systemctl list-dependencies nix-gc.service | grep angrr'
```

Expected: timer exists with a next activation, angrr.service listed as dependency.

- [ ] **Step 5: No commit**

Rollout complete.

---

## Self-Review

### Spec coverage check

| Spec section / requirement | Covered by |
|----------------------------|------------|
| `hasAutoGc` capability flag, default `true` | Task 1 |
| angrr as flake input, nixpkgs follows | Task 2 |
| NixOS feature module at `modules/features/nixos-auto-gc.nix` | Task 3 |
| `nix.gc` with daily cadence, 14d retention, 45min randomized delay | Task 3 Step 1 |
| `nix.optimise.automatic` weekly | Task 3 Step 1 |
| `services.angrr` with `period = "14d"` preset | Task 3 Step 1 |
| `keep-latest-n = 3` override on system profile policy | Task 3 Step 1 + Step 2 eval |
| Angrr rides `nix-gc.timer` via `enableNixGcIntegration` | Verified Task 5 Step 4 |
| Darwin feature module at `modules/features/darwin-auto-gc.nix` | Task 4 Step 1 |
| Darwin `nix.gc` daily at 04:30, 14d retention | Task 4 Step 1 + Step 3 eval |
| Migration: remove GC stanzas from `darwin/features/nix-daemon.nix` | Task 4 Step 2 |
| direnv auto-touch deferred (not in MVP) | Intentionally absent from all tasks |
| Verification plan from spec | Task 5 + Task 6 Steps 2–4 |
| Rollback via `my.hasAutoGc = false` | Verified Task 3 Step 3 |

All spec requirements map to a task.

### Placeholder scan

No "TBD", "TODO", "implement later", "add error handling", or "similar to Task N" text in this plan. Every code block is complete.

### Type / name consistency

- `my.hasAutoGc` used consistently in all three code locations (option definition, NixOS module guard, Darwin module guard).
- `my.modules.nixos.auto-gc` and `my.modules.darwin.auto-gc` — hyphenated `auto-gc` consistently.
- `services.angrr.settings.profile-policies.system.keep-latest-n` — exact key names verified against angrr's module source (`nixos/angrr.nix`).
- `services.angrr.period` used (not `period` inside `settings` — that's a per-policy key, not a top-level one).
- Feature module file names (`nixos-auto-gc.nix`, `darwin-auto-gc.nix`) match what's referenced in the commit messages and spec.

---

## Execution choice

Plan complete and saved to `docs/superpowers/plans/2026-04-23-angrr-auto-gc.md`. Two execution options:

1. **Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration.
2. **Inline Execution** — Execute tasks in this session, batch execution with checkpoints for review.

Which approach?
