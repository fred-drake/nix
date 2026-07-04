# Goal: Verify Flake Evaluates Cleanly After Recent Changes

## Objective

Run `nix flake check` and `colmena eval` only for the remote hosts provably
affected by the current `git diff` — skipping hosts whose configs are not
reachable from the changed files — and confirm all evaluations pass cleanly.

## Success Criteria

1. `nix flake check` exits 0 with no errors.
2. Every affected remote host produces a successful `colmena eval --impure`.
3. Every skipped host is justified: no import path from any changed file reaches it.
4. A final report lists: changed files · AFFECTED hosts + result · SKIPPED hosts + reason.

## Boundaries

**In scope:** Nix evaluation only — no builds, no deploys, no SSH.  
**Out of scope:** Darwin hosts (not colmena-managed); packages that fail to
build but evaluate correctly; any host not in the colmena hive.

## Constraints

- **Never** run `colmena apply` or any command that touches remote machines.
- Use `--impure` with every `colmena eval` call — the dirty working tree makes
  the `git+file://` flake ref unlocked, and pure mode will fail with
  "cannot update unlocked flake input 'hive'".
- Capture exit codes directly (`cmd; echo "EXIT:$?"`), not through a pipe to
  `grep` (which clobbers `$?` with grep's own exit code).

## Implementation Steps

### Step 1 — nix flake check

```bash
cd /Users/fdrake/nix
nix flake check 2>&1 | tail -20
echo "EXIT:$?"
```

Expected: `all checks passed!`, exit 0.  
Acceptable warnings: dirty tree, `colmena` output unknown, Linux systems
omitted on Darwin host.

### Step 2 — Identify changed files

```bash
git diff HEAD --name-only        # unstaged changes vs HEAD
git diff --cached --name-only    # staged changes
```

Combine both lists. Ignore untracked files (e.g. `.pi/`).

### Step 3 — Map changed files → affected colmena hosts

The 6 colmena-managed hosts are:
`headscale`, `ironforge`, `orgrimmar`, `anton`, `gnomeregan`, `stormwind`

**Key structural facts (re-verify if the repo changes):**

| Mechanism | Which hosts are affected |
|-----------|--------------------------|
| `modules/home-manager/features/*.nix` | Only hosts with home-manager: **anton** (user=`nixos`), **gnomeregan** (user=`fdrake`) |
| `modules/features/hm-*.nix` | Same — registered via `my.modules.home-manager.*`, collected by `mk-home-manager.nix` |
| `modules/features/nixos-*.nix` / `modules/services/*.nix` | All NixOS hosts (varies by mkIf guards — check each feature's capability flags) |
| `colmena/hetzner-common/` | headscale, ironforge, orgrimmar, stormwind |
| `colmena/wsl-common/` | anton |
| `colmena/hosts/<name>.nix` | Only that specific host |
| `lib/mk-home-manager.nix` | anton, gnomeregan |
| `lib/my-options-module.nix` | All hosts |
| `lib/nixos-infra.nix` | All NixOS hosts |
| `overlays/*.nix` | Hosts that use the overlay (check `colmena/default.nix` nodeNixpkgs) |

To verify home-manager username for a host:
```bash
grep "username" colmena/hosts/<name>.nix
```

To trace which hosts use a feature module:
```bash
# Feature modules self-register — all HM hosts get all hm-*.nix features.
# NixOS feature modules guard with mkIf config.my.<flag>; check each host's
# capability flags in colmena/hosts/<name>.nix or modules/nixos/<name>*.nix.
grep -n "mk-home-manager\|home-manager" colmena/hosts/<name>.nix
```

### Step 4 — colmena eval for each AFFECTED host

Use a meaningful expression that exercises the changed module, e.g.:

```bash
# Confirm the host evaluates at all:
colmena eval --impure -E '{ nodes, ... }: nodes.<name>.config.networking.hostName'
echo "EXIT:$?"

# For home-manager changes, also confirm the module is included:
colmena eval --impure -E \
  '{ nodes, ... }: builtins.map (p: p.name or p.pname or "?")
     (nodes.<name>.config.home-manager.users.<username>.home.packages)' \
  2>&1 | grep -o '"<relevant-package>[^"]*"'
echo "EXIT:$?"
```

A host evaluates successfully when `colmena eval --impure` exits 0 with no
`error:` lines in stdout/stderr.

### Step 5 — Final report

Produce a summary table:

```
## nix flake check: PASS / FAIL

## Changed files
- <path>

## AFFECTED hosts
| Host       | Eval result | Evidence                              |
|------------|-------------|---------------------------------------|
| anton      | ✅ exit 0   | pi-coding-agent in home.packages      |
| gnomeregan | ✅ exit 0   | pi-coding-agent-x.y.z in home.packages|

## SKIPPED hosts
| Host       | Reason                                              |
|------------|-----------------------------------------------------|
| headscale  | No home-manager; pi.nix import chain not reachable |
| ...        | ...                                                 |

## Overall verdict: PASS / FAIL
```

## If Blocked

Stop and ask the user. Do not guess at import chains for unfamiliar module
patterns — read the relevant `.nix` files to confirm reachability before
classifying a host as SKIPPED.

## Known Gotchas

- **`colmena eval` without `--impure` always fails on a dirty tree.**
- **`anton` uses `username = "nixos"`, not `fdrake`** — accessing
  `home-manager.users.fdrake` on `anton` will fail with "attribute missing".
- **`$?` after a pipe** captures the pipeline's last command, not colmena.
  Always use `cmd; echo "EXIT:$?"` (semicolon, not pipe) to capture the real
  exit code.
- The `colmena` flake output is not a standard `nix flake check` output type —
  the "unknown flake output 'colmena'" warning is expected and harmless.
- `nix flake check` only checks the local Darwin system by default; the warning
  "omitted these incompatible systems: aarch64-linux, x86_64-linux" is expected.
