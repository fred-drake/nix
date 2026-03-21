# CLAUDE.md - Project Context for Claude Code

## Project Overview

This is a Nix flake-based configuration repository managing:
- NixOS systems (servers, workstations, VMs)
- Home Manager configurations
- Colmena deployments
- Custom packages and overlays

### Key Directories

- `apps/` - Custom packages and Claude Code configurations
- `modules/` - NixOS and Home Manager modules
- `systems/` - Per-machine system configurations
- `homefiles/` - Dotfiles and home directory configurations
- `overlays/` - Nix package overlays

## Claude Code Configuration

Claude Code is configured declaratively via Nix in `modules/home-manager/claude-code.nix`.

### Structure

```
apps/claude-code/
├── commands/           # Slash commands (*.md files)
├── agents/             # Custom agents
├── skills/             # Skill definitions
├── assets/             # Plugin assets (scripts, hooks)
│   └── ralph-wiggum/   # Example: converted plugin
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

#### 3. Wire into `modules/home-manager/claude-code.nix`

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

### Converting Plugins to Direct Installation (Legacy)

For plugins that need decomposition (e.g. extracting commands/hooks
into the local `apps/claude-code/` structure), see the ralph-wiggum
example:

1. Copy commands to `apps/claude-code/commands/`
2. Copy scripts/hooks to `apps/claude-code/assets/<plugin-name>/`
3. Fix shebangs: `#!/bin/bash` → `#!/usr/bin/env bash`
4. Replace `${CLAUDE_PLUGIN_ROOT}` with
   `$HOME/.claude/assets/<plugin-name>`
5. Add `home.file` entry for the assets directory
6. Add hooks to `settings.json` if needed

**Example:** ralph-wiggum plugin lives at
`apps/claude-code/assets/ralph-wiggum/` with commands at
`/ralph-loop`, `/cancel-ralph`, `/ralph-help`.

## MCP Server Configuration

MCP servers are configured via SOPS templates in `modules/home-manager/claude-code.nix`. Each server gets its own JSON file in `~/mcp/` with secrets injected at activation time.

## Build Commands

**IMPORTANT:** Do NOT use `sudo` with `just` commands — they handle `sudo` internally.

```bash
# Rebuild NixOS system
just switch

# Build NixOS system only
just build

# Rebuild home-manager only
home-manager switch --flake .

# Check flake
nix flake check
```
