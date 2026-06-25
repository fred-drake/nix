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
- `apps/fetcher/pi-<name>-lock.json` — generated lockfile, if GitHub source has none (see Step 2)
- `apps/fetcher/update-pi-<name>.sh` — updater that re-resolves the pin
- `modules/home-manager/features/pi.nix` — the `piPackages` list + `piManagedPackages` activation merge
- `justfile` — `update-pi-packages` target (and `update-pi` for the CLI), both in `update-all`

The reference implementation is `@quintinshaw/pi-dynamic-workflows` (apps/pi-dynamic-workflows.nix).
For the `buildNpmPackage`+injected-lockfile strategy, see `apps/pi-web-access.nix` and
`apps/pi-mcp-adapter.nix`.

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
   `typebox`. They appear in `peerDependencies` by convention. Only real `dependencies` get
   vendored. Exception: if a package lists them in `dependencies` (not `peerDependencies`),
   they will be bundled — pi's separate module roots mean they coexist with pi core's own
   copies without conflict.
3. **Published npm tarballs have no lockfile** → `buildNpmPackage` from the tarball fails.
   Two strategies depending on the dep tree (Step 2). **Important:** GitHub source repos
   also frequently have no lockfile — do not assume one exists; always check with
   `ls "$src/package-lock.json"` after prefetching the source.
4. **`settings.json` is mutable and pi writes to it** (`lastChangelogVersion` on update,
   plus interactive `/settings`, `/model`). Do **NOT** manage it with read-only
   `home.file` (the claude-code style) — that breaks pi's own writes. Merge with jq in an
   activation script instead (already implemented; you just add to the `piPackages` list).
5. **The whole tarball is needed**, not just `dist/`. Pi loads `.ts` extensions directly
   (via jiti); the package typically ships `src/`, `dist/`, and `extensions/`. Unpack all.
6. **`git add` all new files before evaluating.** Nix flakes only see git-tracked files.
   A `darwin-rebuild build` will fail with "Path '...' is not tracked by Git" until you
   `git add apps/pi-<name>.nix apps/fetcher/pi-<name>.nix apps/fetcher/pi-<name>-lock.json ...`.
7. **`buildNpmPackage` output layout for pi.** The default `installPhase` copies to
   `$out/lib/node_modules/<pkgname>`, but pi needs the package root at `$out` (so it can
   find `index.ts`, `skills/`, etc. directly). Always override `installPhase` with
   `cp -r . $out/`. Also override `buildPhase` to be empty when there is no build script
   (pi loads TypeScript via jiti — no compile step needed).
8. **Use `cp -r source/. dest/` not `cp -rT source dest`.** macOS BSD `cp` does not
   support `-T`. The portable form is `cp -r "$src"/. "$dst"/`.

## Step 1 — Inspect the package

```bash
npm view <pkg> version dependencies peerDependencies devDependencies pi
# Inspect the tarball manifest:
url=$(npm view <pkg> dist.tarball); f=$(nix store prefetch-file --json "$url" | jq -r .storePath)
tar -xzf "$f" -O package/package.json | jq '{main, files, pi, dependencies, peerDependencies}'
tar -tzf "$f" | grep -E 'extensions/|src/|skills/'   # what resources ship
# Check if GitHub source has a lockfile:
src=$(nix flake prefetch --json github:<owner>/<repo>/v<version> | jq -r .storePath)
ls "$src/package-lock.json" 2>/dev/null || echo "NO LOCKFILE IN GITHUB SOURCE"
```

For every entry in `dependencies`, check whether it is itself dependency-free:
`npm view <dep> dependencies`. That decides Step 2.

## Step 2 — Pick a build strategy

| Dep tree | Lockfile in GitHub source? | Strategy |
|---|---|---|
| **No deps, or a few dependency-free pure-JS deps** | N/A | Fetch each tarball with `fetchurl` and assemble `node_modules/<dep>` by hand. This is the dynamic-workflows/acorn case — simplest, fully reproducible. |
| **Deep or native dep tree** | **Yes** | Build from GitHub source with `buildNpmPackage` — same approach as the pi CLI itself (`apps/pi-coding-agent.nix`). Run `nix run nixpkgs#prefetch-npm-deps -- "$src/package-lock.json"` for `npmDepsHash`. |
| **Deep or native dep tree** | **No** | Generate a lockfile locally (see Step 3b), commit it to `apps/fetcher/pi-<name>-lock.json`, inject it via `runCommand` in the derivation. See `apps/pi-web-access.nix` as the reference. |

Most extensions are light (the reference one has only `acorn`). Prefer the hand-assemble
strategy when the deps are dependency-free.

## Step 3a — Get hashes (GitHub source has a lockfile)

```bash
# GitHub source hash:
nix run nixpkgs#nurl -- https://github.com/<owner>/<repo> v<version>
# npmDepsHash:
src=$(nix flake prefetch --json github:<owner>/<repo>/v<version> | jq -r .storePath)
nix run nixpkgs#prefetch-npm-deps -- "$src/package-lock.json" 2>/dev/null
```

## Step 3b — Generate a lockfile (GitHub source has NO lockfile)

```bash
# 1. Prefetch source
src=$(nix flake prefetch --json github:<owner>/<repo>/v<version> | jq -r .storePath)

# 2. Generate the lockfile in a temp dir.
#    IMPORTANT: use a full `npm install`, NOT `--package-lock-only`.
#    `--package-lock-only` does not fetch packages and omits integrity hashes,
#    which causes `prefetch-npm-deps` to panic with:
#    "non-git dependencies should have associated integrity"
tmp=$(mktemp -d)
cp -r "$src"/. "$tmp/"
chmod -R u+w "$tmp"
cd "$tmp"
npm install --ignore-scripts --omit=peer   # baseline; add --omit=dev if needed (see below)

# 3. Check for missing integrity hashes before running prefetch-npm-deps:
jq '[.packages | to_entries[]
     | select(.value.resolved != null and .value.integrity == null)
     | .key]' package-lock.json
# If the list is non-empty, you have a problem. Common causes:
#   a) A peer dep was installed (add --omit=peer if not already present)
#   b) A devDep (e.g. @earendil-works/pi-coding-agent) pulls in nested pi-* packages
#      at a different version without integrity hashes → add --omit=dev and regenerate.
# Re-run npm install with the appropriate --omit=* flags until the list is [].

# 4. Get npmDepsHash from the clean lockfile:
nix run nixpkgs#prefetch-npm-deps -- package-lock.json 2>/dev/null

# 5. Copy the lockfile into the repo:
cp package-lock.json /path/to/repo/apps/fetcher/pi-<name>-lock.json
```

**Common `--omit` flag patterns:**
- `--omit=peer` — baseline; always use this (pi-core peer deps are runtime-provided)
- `--omit=dev` — add when devDeps pull in pi-core packages at mismatched versions
  (e.g. `@earendil-works/pi-coding-agent` is a devDep in several packages)

## Step 4 — Write the pin + derivation + updater

### Pin file (`apps/fetcher/pi-<name>.nix`)

For the hand-assemble strategy, copy `pi-dynamic-workflows.nix`:
```nix
{ pkg = {version = "..."; url = "..."; hash = "...";}; dep = {...}; }
```

For the `buildNpmPackage` strategy (with or without injected lockfile), copy
`pi-coding-agent.nix`:
```nix
# Auto-generated by update-pi-<name>.sh
{
  version = "x.y.z";
  hash = "sha256-...";       # GitHub source hash from nurl
  npmDepsHash = "sha256-..."; # from prefetch-npm-deps
}
```

### Derivation (`apps/pi-<name>.nix`)

**Hand-assemble strategy** — copy `apps/pi-dynamic-workflows.nix` and adapt.

**`buildNpmPackage` with lockfile in source** — copy `apps/pi-coding-agent.nix` and
strip the pi-specific build/install steps.

**`buildNpmPackage` with injected lockfile** (no lockfile in GitHub source) — use this
pattern (see `apps/pi-web-access.nix` for a complete example):

```nix
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  runCommand,
  pin,
}:
let
  rawSrc = fetchFromGitHub {
    owner = "<owner>";
    repo = "<repo>";
    tag = "v${pin.version}";
    inherit (pin) hash;
  };
  # Inject the generated lockfile — upstream ships none.
  # Use cp -r source/. dest/ (not cp -rT) for macOS BSD cp compatibility.
  src = runCommand "pi-<name>-src" {} ''
    mkdir -p $out
    cp -r ${rawSrc}/. $out/
    chmod -R +w $out
    cp ${./pi-<name>-lock.json} $out/package-lock.json
  '';
in
  buildNpmPackage {
    pname = "pi-<name>";
    inherit (pin) version;
    inherit src;
    inherit (pin) npmDepsHash;

    # Match the --omit flags used to generate the lockfile.
    npmFlags = ["--ignore-scripts" "--omit=peer"];   # add --omit=dev if needed

    # Pi loads TypeScript via jiti — no compile step needed.
    # Override buildPhase to skip `npm run build` (which would fail if there's no
    # build script, and is unnecessary for jiti-loaded extensions anyway).
    buildPhase = ''
      runHook preBuild
      runHook postBuild
    '';

    # Pi needs the package root at $out (index.ts, skills/, node_modules/).
    # buildNpmPackage's default puts things under $out/lib/node_modules/<name>,
    # which pi cannot find.
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r . $out/
      rm -f $out/package-lock.json   # drop injected lockfile; not needed at runtime
      runHook postInstall
    '';

    meta = {
      description = "...";
      homepage = "https://pi.dev/packages/<name>";
      license = lib.licenses.mit;
    };
  }
```

### Updater (`apps/fetcher/update-pi-<name>.sh`)

For packages with no GitHub lockfile, the updater must also regenerate and save the
lockfile (see `apps/fetcher/update-pi-web-access.sh` for a complete example):

```bash
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIN_FILE="$SCRIPT_DIR/pi-<name>.nix"
LOCK_FILE="$SCRIPT_DIR/pi-<name>-lock.json"   # only for no-lockfile packages
PKG="<npm-pkg-name>"
REPO="<owner>/<repo>"

version=$(npm view "$PKG" version)
hash=$(nix run nixpkgs#nurl -- "https://github.com/$REPO" "v$version" 2>/dev/null \
  | grep 'hash =' | sed 's/.*hash = "\(.*\)".*/\1/')

# Generate lockfile (no-lockfile packages only):
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
srcPath=$(nix flake prefetch --json "github:$REPO/v$version" | jq -r .storePath)
cp -r "$srcPath"/. "$tmp/"; chmod -R u+w "$tmp"; cd "$tmp"
npm install --ignore-scripts --omit=peer -q   # adjust --omit flags as needed
cp package-lock.json "$LOCK_FILE"
npmDepsHash=$(nix run nixpkgs#prefetch-npm-deps -- "$LOCK_FILE" 2>/dev/null)

cat > "$PIN_FILE" <<EOF
# Auto-generated by update-pi-<name>.sh
{ version = "$version"; hash = "$hash"; npmDepsHash = "$npmDepsHash"; }
EOF
alejandra --quiet "$PIN_FILE" 2>/dev/null || true
```

`chmod +x` the script.

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
# IMPORTANT: git add all new files first — Nix flakes only see tracked files.
git add apps/pi-<name>.nix apps/fetcher/pi-<name>.nix \
        apps/fetcher/pi-<name>-lock.json apps/fetcher/update-pi-<name>.sh

darwin-rebuild --flake .#macbook-pro build      # no sudo, no activation (hosts: macbook-pro, laisas-mac-mini)
just switch                                      # do NOT prefix sudo — just handles it
```

**Verify the output layout** — pi needs `index.ts` (or the declared extension entry) and
`node_modules/` at the store-path root:

```bash
store_path=$(ls -d /nix/store/*-pi-<name>-<version> | grep -v 'npm-deps\|src' | head -1)
ls "$store_path"          # should show index.ts, node_modules/, package.json, skills/ etc.
jq '.pi' "$store_path/package.json"   # confirm pi manifest is intact
```

**Verify packages are registered:**

```bash
jq '.packages' ~/.pi/agent/settings.json   # all store paths present, other keys intact
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
