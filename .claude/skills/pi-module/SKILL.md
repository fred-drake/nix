---
name: pi-module
description: |
  Install a pi (pi.dev coding agent) package/extension/skill into this nix flake
  declaratively, instead of running `pi install npm:...`. Use when the user gives a
  `pi install npm:<pkg>` / `pi install git:<repo>` command, links a https://pi.dev/packages/...
  page, or asks to add a pi extension/skill/theme/prompt to the nix config. Also covers
  bumping the pi CLI itself (pi-coding-agent). Pi calls these "packages"; the user may
  call them "modules".
---

# Adding a pi Package/Module to Nix

Pi packages are installed **declaratively** here, replacing `pi install`. The trick:
`pi install npm:X` does two things — (1) drops the package under `~/.pi/agent/npm/` and
(2) appends a reference to the `packages` array in `~/.pi/agent/settings.json`. We
reproduce both with nix: build the package into the store, then register that **store
path as a local-path entry** in the `packages` array via an activation-script merge.

Key files (all already exist — extend them):
- `apps/pi-<name>.nix` — derivation that assembles one pi package directory
- `apps/fetcher/pi-<name>.nix` — auto-generated pin (versions + hashes); never hand-edit except to revert
- `apps/fetcher/update-pi-<name>.sh` — updater that re-resolves the pin
- `modules/home-manager/features/pi.nix` — the `piPackages` list + `piManagedPackages` activation merge
- `justfile` — `update-pi-packages` target (and `update-pi` for the CLI), both in `update-all`

The reference implementation is `@quintinshaw/pi-dynamic-workflows` (apps/pi-dynamic-workflows.nix).
Copy it.

## Read the real docs first

Pi ships authoritative docs **inside the built package** — read these, not the website
(the website's `npm view ... pi` manifest can even be stale vs the published package.json):

```bash
# The docs dir is inside the built pi store path:
docs=$(find /nix/store -maxdepth 5 -type d -path '*pi-monorepo/docs' 2>/dev/null | sort | tail -1)
ls "$docs"                    # packages.md, settings.md, extensions.md, skills.md, ...
```

## Critical facts (these bit me; don't relearn them)

1. **Local-path packages are NOT `npm install`-ed by pi.** For `npm:`/`git:` sources pi
   runs `npm install`; for a local path it just loads the directory as-is. So the
   derivation **must ship `node_modules/` with all runtime `dependencies`** already
   present. (Docs: packages.md "Local Paths".)
2. **Peer deps are provided by pi core — never bundle them.** `@earendil-works/pi-ai`,
   `@earendil-works/pi-agent-core`, `@earendil-works/pi-coding-agent`, `@earendil-works/pi-tui`,
   `typebox`. They appear in `peerDependencies`. Only real `dependencies` get vendored.
3. **Published npm tarballs have no lockfile** → `buildNpmPackage` from the tarball fails.
   Two strategies depending on the dep tree (Step 2).
4. **`settings.json` is mutable and pi writes to it** (`lastChangelogVersion` on update,
   plus interactive `/settings`, `/model`). Do **NOT** manage it with read-only
   `home.file` (the claude-code style) — that breaks pi's own writes. Merge with jq in an
   activation script instead (already implemented; you just add to the `piPackages` list).
5. **The whole tarball is needed**, not just `dist/`. Pi loads `.ts` extensions directly
   (via jiti); the package typically ships `src/`, `dist/`, and `extensions/`. Unpack all.

## Step 1 — Inspect the package

```bash
npm view <pkg> version dependencies peerDependencies pi
# Confirm what the manifest declares + which deps are real vs peer:
url=$(npm view <pkg> dist.tarball); f=$(nix store prefetch-file --json "$url" | jq -r .storePath)
tar -xzf "$f" -O package/package.json | jq '{main, files, pi, dependencies, peerDependencies}'
tar -tzf "$f" | grep -E 'extensions/|src/|skills/'   # what resources ship
```

For every entry in `dependencies`, check whether it is itself dependency-free:
`npm view <dep> dependencies`. That decides Step 2.

## Step 2 — Pick a build strategy

| Dep tree | Strategy |
|---|---|
| **No deps, or a few dependency-free pure-JS deps** | Fetch each tarball with `fetchurl` and assemble `node_modules/<dep>` by hand. This is the dynamic-workflows/acorn case — simplest, fully reproducible. |
| **Deep or native dep tree** | Build from the **GitHub source** with `buildNpmPackage` (the repo has a lockfile even though the npm tarball doesn't) — same approach as the pi CLI itself (`apps/pi-coding-agent.nix`). Needs `npmDepsHash`. |

Most extensions are light (the reference one has only `acorn`). Prefer the hand-assemble
strategy when the deps are dependency-free.

## Step 3 — Get the hashes

```bash
# npm tarball (the package and each pure-JS dep):
nix store prefetch-file --json "$(npm view <pkg> dist.tarball)" | jq -r .hash
# GitHub source (buildNpmPackage strategy only):
nix run nixpkgs#nurl -- https://github.com/<owner>/<repo> v<version>
# npmDepsHash (buildNpmPackage strategy only):
src=$(nix flake prefetch --json github:<owner>/<repo>/v<version> | jq -r .storePath)
nix run nixpkgs#prefetch-npm-deps -- "$src/package-lock.json" 2>/dev/null
```

## Step 4 — Write the pin + derivation + updater

Copy the three `pi-dynamic-workflows` files, renaming to `pi-<name>`:
- `apps/fetcher/pi-<name>.nix` — `{ workflows = {version,url,hash;}; <dep> = {...}; }`
- `apps/pi-<name>.nix` — `stdenvNoCC.mkDerivation` that unpacks the package tarball to
  `$out --strip-components=1` and each dep tarball to `$out/node_modules/<dep>`.
- `apps/fetcher/update-pi-<name>.sh` — `chmod +x`; re-resolves versions/hashes via npm.

## Step 5 — Register it

In `modules/home-manager/features/pi.nix`, add to the `piPackages` list:

```nix
(pkgs.callPackage ../../../apps/pi-<name>.nix {
  pin = import ../../../apps/fetcher/pi-<name>.nix;
})
```

That's it — the `piManagedPackages` activation merge is **generic**: it sets `.packages`
to all `piPackages` store paths, strips any stale `^/nix/store/` entries from prior
generations (so version bumps don't duplicate), and preserves every other settings key
and any user-added `npm:`/`git:` entry. If `settings.json` is invalid JSON it is left
untouched.

## Step 6 — Wire the updater into justfile

Add the script to the `update-pi-packages` recipe (and it is already in `update-all`):

```make
update-pi-packages:
    ./apps/fetcher/update-pi-dynamic-workflows.sh
    ./apps/fetcher/update-pi-<name>.sh
```

## Step 7 — Build, switch, verify

```bash
darwin-rebuild --flake .#macbook-pro build      # no sudo, no activation (hosts: macbook-pro, laisas-mac-mini)
just switch                                      # do NOT prefix sudo — just handles it
```

**Verify in isolation** (don't touch the user's real config) using `PI_CODING_AGENT_DIR`:

```bash
pkg=<store-path-of-built-package>
d=$(mktemp -d); cp ~/.pi/agent/auth.json "$d/auth.json"   # reuse local login; pi gates `list` on a valid key
jq -n --arg p "$pkg" '{packages:[$p], defaultProjectTrust:"always"}' > "$d/settings.json"
PI_CODING_AGENT_DIR="$d" pi list                          # package should appear, no load error
PI_CODING_AGENT_DIR="$d" pi --offline -p "say hi"         # real startup → extension load errors surface here
rm -rf "$d"
```

Gotchas while verifying:
- `pi list` / most commands gate on a **valid API key and hit the network even with
  `--offline`** (model validation) — a dummy key 401s. Copy the real `auth.json` into the
  isolated dir.
- The **TUI needs a TTY** — piping `/help` into `pi` produces nothing. Use `-p` instead.
- `--offline` only skips update/telemetry checks, not the model auth call.

After a real `just switch`, confirm the merge landed:
```bash
jq '.packages' ~/.pi/agent/settings.json      # store path present, other keys intact
pi list
```
In a running pi, `/reload` (or restart) activates new/changed extensions.

## Bumping the pi CLI itself (related)

`pi-coding-agent` is built **from the GitHub monorepo source** (not nixpkgs, which lags
even on unstable; and not the npm tarball, which has no lockfile). Pin: `apps/fetcher/pi-coding-agent.nix`
(version + src `hash` + `npmDepsHash`); derivation: `apps/pi-coding-agent.nix`; updater:
`apps/fetcher/update-pi.sh` (justfile `update-pi`). It is the one **from-source** build
in this repo, so the first `switch` after a bump compiles the TS workspaces (minutes)
until cached.

## Report

Tell the user: the package, the build strategy used, the bump command
(`just update-pi-packages` then `just switch`), and that they run `/reload` in pi. Don't
commit unless asked.
