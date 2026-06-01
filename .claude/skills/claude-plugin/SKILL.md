---
name: claude-plugin
description: |
  Install a Claude Code plugin or skill collection into this nix flake declaratively,
  the same way superpowers/cmux/cc-skills-golang are wired. Use when the user gives a
  `/plugin marketplace add ...`, `/plugin install ...`, or `npx skills add ...` command,
  or asks to add a Claude plugin/skill repo to the nix config. Covers fetching+pinning
  the repo, classifying its layout (self-contained plugin / marketplace / curated subset
  / no-manifest skills repo), and wiring it into home-manager.
---

# Adding a Claude Code Plugin/Skill to Nix

Claude plugins are installed **declaratively** in this repo, bypassing Claude Code's
mutable marketplace/cache. The flow is: pin the git repo → symlink it into `~/plugins/`
→ load opt-in via `claude --plugin-dir`. Nothing changes unless the pinned hash changes.

Key files:
- `apps/fetcher/claude-plugins.toml` — repos to fetch (you edit this)
- `apps/fetcher/claude-plugins-src.nix` — auto-generated pinned revs/hashes (never hand-edit except to revert drift)
- `modules/home-manager/features/claude-code.nix` — `home.file` symlinks + synthesized manifests

## Convention: opt-in vs auto-load

This repo keeps big bundles **opt-in**: symlinked to `~/plugins/<name>`, loaded manually
with `claude --plugin-dir ~/plugins/<name>`. Only `lsp-plugin` is auto-loaded (listed in
`pluginDirs` in the `claude-code = pkgs.callPackage` call). Default to opt-in to match
superpowers/cmux/cc-skills-golang. **Ask the user** if they want auto-load instead (adds
the path to `pluginDirs`, always active every session).

## Step 1 — Classify the upstream repo

Inspect the repo's tree *before* writing any nix. Don't clone; use the GitHub API:

```bash
gh api "repos/<owner>/<repo>/git/trees/HEAD" --jq '.tree[] | select(.type=="tree") | .path'
gh api "repos/<owner>/<repo>/git/trees/HEAD:.claude-plugin" --jq '.tree[].path'   # plugin.json? marketplace.json?
gh api "repos/<owner>/<repo>/git/trees/HEAD:skills" --jq '.tree[] | select(.type=="tree") | .path'
# Read a skill's frontmatter name (often DIFFERS from its directory name):
gh api "repos/<owner>/<repo>/contents/skills/<dir>/SKILL.md" --jq '.content' | base64 -d | head -6
```

Four layouts, each wired differently:

| Layout | How to detect | Wiring |
|---|---|---|
| **Self-contained plugin** | `.claude-plugin/plugin.json` at root | symlink whole repo; load at `~/plugins/<name>` |
| **Marketplace** (many plugins) | `.claude-plugin/marketplace.json`, `plugins[]` each with `source` + own `plugin.json` | symlink whole repo; load each via its subdir `~/plugins/<name>/<source-path>` |
| **No-manifest skills repo** | `skills/<x>/SKILL.md` but no root `.claude-plugin` | **synthesize** a `plugin.json` + symlink the wanted skill dirs |
| **Curated subset** | user wants only N of many skills | **synthesize** a `plugin.json` exposing just those skills, even if upstream has a manifest |

Notes:
- A plugin dir = `<dir>/.claude-plugin/plugin.json` + skills under `<dir>/skills/<skill>/SKILL.md`.
- `--plugin-dir` points at **one** plugin. A marketplace cannot be loaded with a single
  flag — you load individual sub-plugins by their subdir path.
- The skill's identity is the `name:` in its `SKILL.md` frontmatter, **not** the directory
  name. E.g. vercel's `skills/react-best-practices/` registers as `vercel-react-best-practices`.

## Step 2 — Add to the fetcher TOML

Append to `apps/fetcher/claude-plugins.toml`. The `name` becomes the attr name in the
generated src.nix verbatim (suffix `-src` by convention):

```toml
# <one-line description of what it is and its layout>
[[repos]]
name = "<repo>-src"
url = "https://github.com/<owner>/<repo>"
```

Use `fetcher = "tarball"` **only** if claude-code.nix must read the repo at eval time on
a foreign platform (the `claude-plugins-official-src` case — its `marketplace.json` is
parsed during Linux-host eval from a Darwin workstation). Normal plugins omit it
(default = `fetchFromGitHub`).

## Step 3 — Pin it

```bash
PROJECT_ROOT=$(pwd) update-claude-plugins
```

**GOTCHA:** this regenerates `claude-plugins-src.nix` and re-pins **every** repo to its
current HEAD (none carry an explicit `rev`). It will silently bump unrelated entries
(e.g. `superpowers-src`, `cmux-src`, `claude-plugins-official-src`). After running, diff
`claude-plugins-src.nix` and **revert any entry you didn't intend to update** back to its
prior rev+hash, so the change stays additions-only. (`claude-plugins-official-src` is a
`builtins.fetchTarball` with `url`+`sha256`; the rest are `fetchFromGitHub` with
`rev`+`hash`.)

## Step 4 — Wire into claude-code.nix

In `modules/home-manager/features/claude-code.nix`, under the "Opt-in skill/plugin
bundles" block, add `home.file` entries. `claude-plugins-src` is already in scope.

**Self-contained plugin** (symlink whole repo):
```nix
"plugins/<name>" = {
  source = "${claude-plugins-src.<repo>-src}";
  recursive = true;
};
```

**Marketplace** (symlink whole; load sub-plugins by subdir):
```nix
# Load an individual plugin, e.g. claude --plugin-dir ~/plugins/<name>/plugins/<sub>
"plugins/<name>" = {
  source = "${claude-plugins-src.<repo>-src}";
  recursive = true;
};
```

**Curated subset / no-manifest** (symlink chosen skill dirs + synthesize plugin.json).
Use the directory name in the path; recursive symlinks each file under it. A `.text`
plugin.json at a non-overlapping path coexists fine (this is the cmux pattern):
```nix
"plugins/<name>/skills/<skill-dir>" = {
  source = "${claude-plugins-src.<repo>-src}/skills/<skill-dir>";
  recursive = true;
};
# ...repeat per wanted skill...
"plugins/<name>/.claude-plugin/plugin.json".text = builtins.toJSON {
  name = "<name>";
  description = "Curated <upstream> skills: <skill-a>, <skill-b>.";
  repository = "https://github.com/<owner>/<repo>";
};
```

## Step 5 — Build, switch, verify

```bash
# Build first (host names: macbook-pro, laisas-mac-mini — check `nix eval .#darwinConfigurations --apply 'x: builtins.attrNames x'`)
nix build .#darwinConfigurations.macbook-pro.config.system.build.toplevel --no-link
just switch          # do NOT prefix with sudo — just handles it
```

Then confirm the symlinks resolve to real content and manifests are correct:
```bash
ls ~/plugins/<name>/skills
cat ~/plugins/<name>/.claude-plugin/plugin.json
grep -m1 '^name:' ~/plugins/<name>/skills/<skill-dir>/SKILL.md   # frontmatter name resolves through symlink
```

## Step 6 — Report

Give the user a table of plugin dir → source → skills exposed, and the exact
`claude --plugin-dir ~/plugins/<name>` invocation. For marketplaces, note that no single
flag loads all sub-plugins. Do not commit unless asked.
