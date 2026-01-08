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

## Converting Plugins to Direct Installation

The Claude Code plugin system uses feature flags that may not be enabled. To install plugins declaratively via Nix, convert them to direct commands/assets.

### Plugin Conversion Pattern

Given a plugin with this structure:
```
plugin-name/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   ├── command1.md
│   └── command2.md
├── hooks/
│   └── some-hook.sh
└── scripts/
    └── helper-script.sh
```

Convert it as follows:

#### 1. Create Assets Directory

Create `apps/claude-code/assets/<plugin-name>/` with scripts and hooks:

```
apps/claude-code/assets/<plugin-name>/
├── scripts/
│   └── helper-script.sh
└── hooks/
    └── some-hook.sh
```

#### 2. Fix Shebangs

Change `#!/bin/bash` to `#!/usr/bin/env bash` for NixOS compatibility.

#### 3. Patch Command Files

Copy command `.md` files to `apps/claude-code/commands/`.

Replace `${CLAUDE_PLUGIN_ROOT}` references with `$HOME/.claude/assets/<plugin-name>`:

```markdown
# Before
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/helper.sh)"]

# After
allowed-tools: ["Bash($HOME/.claude/assets/<plugin-name>/scripts/helper.sh)"]
```

Also patch any bash code blocks:
```bash
# Before
"${CLAUDE_PLUGIN_ROOT}/scripts/helper.sh"

# After
"$HOME/.claude/assets/<plugin-name>/scripts/helper.sh"
```

#### 4. Add to Nix Config

In `modules/home-manager/claude-code.nix`, add the assets directory:

```nix
".claude/assets/<plugin-name>" = {
  source = ../../apps/claude-code/assets/<plugin-name>;
  recursive = true;
};
```

Commands are automatically included since the entire `commands/` directory is already sourced.

#### 5. Add Hooks to settings.json

If the plugin has hooks, add them to the appropriate hook type in `settings.json`:

```nix
hooks = {
  Stop = [
    {
      hooks = [
        {
          type = "command";
          command = "$HOME/.claude/assets/<plugin-name>/hooks/some-hook.sh";
        }
      ];
    }
  ];
};
```

### Example: ralph-wiggum

The ralph-wiggum plugin was converted following this pattern:

**Commands created:**
- `/ralph-loop` - Start iterative development loop
- `/cancel-ralph` - Cancel active loop
- `/ralph-help` - Show documentation

**Assets location:** `apps/claude-code/assets/ralph-wiggum/`

**Stop hook:** Added to settings.json to intercept session exit when loop is active.

## MCP Server Configuration

MCP servers are configured via SOPS templates in `modules/home-manager/claude-code.nix`. Each server gets its own JSON file in `~/mcp/` with secrets injected at activation time.

## Build Commands

```bash
# Rebuild NixOS system
sudo just switch

# Build NixOS system only
just build

# Rebuild home-manager only
home-manager switch --flake .

# Check flake
nix flake check
```
