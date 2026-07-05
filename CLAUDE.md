# CLAUDE.md - Project Context for Claude Code

## Project Overview

This is a Nix flake-based configuration repository managing:
- NixOS systems (servers, workstations, VMs)
- Home Manager configurations
- Colmena deployments
- Custom packages and overlays

### Key Directories

- `lib/` - Helper functions: `mkPkgs.nix` (centralized pkgs factory),
  `my-options-module.nix` (capability flags), `nixos-infra.nix`,
  `darwin-infra.nix`, `mk-home-manager.nix`
- `modules/features/` - Dendritic feature modules (flake-parts, self-registering)
- `modules/services/` - NixOS server service modules (with inline sops secrets)
- `modules/hosts/` - Host definitions (`nixos.nix`, `darwin.nix`)
- `modules/infra/` - Flake-parts plumbing (colmena, devshell, pkgs, systems)
- `modules/home-manager/` - Home Manager feature implementations + host overrides
- `modules/darwin/` - Darwin feature implementations + per-host dirs
- `modules/nixos/` - NixOS per-host configs (thin)
- `colmena/` - Per-host deployment files + hetzner-common, wsl-common
- `apps/` - Custom packages and Claude Code configurations
- `homefiles/` - Dotfiles and home directory configurations
- `overlays/` - Package overlays

## Package Workarounds (overlays/)

When you add a **temporary** package override to work around an upstream
breakage in `nixpkgs` (a redundant patch, a flaky or timeout-prone test, a
build failure) anywhere under `overlays/`, tag it with a greppable marker
comment the moment you write it:

```nix
# WORKAROUND(<pkg>): <reason>; remove when <condition>.
```

This applies whenever you create such an override — not only during a deploy or
while the `infrastructure` skill is active. **Intentional** pins (a version
locked on purpose, e.g. lockstep with another component) are NOT workarounds and
must NOT carry the marker. The infrastructure skill's "Workaround Hygiene" audit
greps these markers to test whether each override is still needed; an untagged
workaround is invisible to that audit and silently rots.

## Claude Code Configuration

Claude Code is configured declaratively via Nix in
`modules/home-manager/features/claude-code.nix`.

### Structure

```
apps/claude-code/
├── commands/           # Slash commands (*.md files)
├── agents/             # Custom agents
├── skills/             # Skill definitions
├── assets/             # Plugin assets (scripts, hooks)
└── marketplace/        # Original plugin sources (reference only)
```

### How Commands Work

Commands in `apps/claude-code/commands/` are symlinked to `~/.claude/commands/` via home-manager. Each `.md` file becomes a `/command-name` slash command.

## Declarative Plugin Installation

Plugins are installed declaratively via Nix using `--plugin-dir` flags,
bypassing Claude Code's mutable marketplace/cache system entirely.

### How It Works

1. Plugin git repos are pinned in `apps/fetcher/claude-plugins.toml`
2. `update-claude-plugins` fetches latest commits and generates
   `apps/fetcher/claude-plugins-src.nix` with pinned rev/hash
3. Plugins are symlinked to `~/.claude/` via home-manager
4. The `pluginDirs` list in `apps/claude-code/default.nix` passes
   `--plugin-dir` flags to the claude wrapper automatically

Nothing changes unless you explicitly update the pinned hashes.

### Adding a Self-Contained Plugin

Most plugins (not LSP) are self-contained with a proper
`.claude-plugin/plugin.json`. To add one:

#### 1. Add to `apps/fetcher/claude-plugins.toml`

```toml
[[repos]]
name = "my-plugin-src"
url = "https://github.com/owner/repo"
```

#### 2. Run `just update-claude` (or `update-claude-plugins`)

This generates the pinned entry in `claude-plugins-src.nix`.

#### 3. Wire into `modules/home-manager/features/claude-code.nix`

Symlink the plugin directory:
```nix
".claude/plugins/my-plugin" = {
  source = "${claude-plugins-src.my-plugin-src}";  # or a subdir
  recursive = true;
};
```

Add to `pluginDirs` in the `claude-code` package call:
```nix
claude-code = pkgs.callPackage ../../apps/claude-code {
  pluginDirs = [
    "$HOME/.claude/lsp-plugin"
    "$HOME/.claude/plugins/my-plugin"
  ];
};
```

#### 4. `just switch`

### LSP Plugin (Special Case)

LSP plugins in `claude-plugins-official` are not self-contained — their
config lives centrally in `marketplace.json`. The LSP plugin is
generated at Nix build time by `apps/claude-code/lsp-plugin.nix`:

1. Parses `marketplace.json` from the pinned `claude-plugins-official`
   repo and extracts all `lspServers` entries
2. Merges in custom LSP servers not available upstream (e.g. `nil`
   for Nix) defined in `customLspServers` in `lsp-plugin.nix`
3. Produces a plugin directory with `.claude-plugin/plugin.json`
   and `.lsp.json`

To add a custom LSP server, add it to `customLspServers` in
`apps/claude-code/lsp-plugin.nix`.

### Updating Plugins

`just update-claude` updates both the Claude Code binary and all
plugin repos in `claude-plugins.toml`. Repos are only updated when
you run this — pinned hashes guarantee idempotency.

## MCP Server Configuration

MCP servers are configured via SOPS templates in `modules/home-manager/features/claude-code.nix`. Each server gets its own JSON file in `~/mcp/` with secrets injected at activation time.

## Git and Nix File Visibility

**IMPORTANT:** Nix flakes only see files that have been added to git. Any new file
created in this repository must be staged with `git add <file>` before Nix can
reference it in configuration. Until a file is staged, Nix will error with
`path '...' does not exist` even if the file is present on disk.

After creating any new file: `git add <file>`

## Nix Formatting

Use `alejandra` for formatting Nix files in this repository. Do not use
`nix fmt` unless explicitly requested; the flake may not expose a formatter for
all systems. The git commit pre-hook is expected to run the configured formatter.

## Build Commands

**IMPORTANT:** Do NOT use `sudo` with `just` commands — they handle `sudo` internally.

```bash
# Rebuild NixOS system (always pipe through tail to avoid token waste)
just switch 2>&1 | tail -20

# Build NixOS system only
just build

# Rebuild home-manager only
home-manager switch --flake .

# Check flake
nix flake check
```

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
