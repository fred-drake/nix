---
name: nix-dendritic-pattern
description: |
  Reference for the Nix dendritic design pattern — a module system usage pattern
  for organizing large Nix configuration codebases. Use when restructuring or
  refactoring Nix flake configurations, evaluating architecture decisions, or
  applying the dendritic pattern to this project.
---

# The Dendritic Design Pattern for Nix

Reference: https://github.com/mightyiam/dendritic

## What It Is

The dendritic pattern is a **Nixpkgs module system usage pattern** for organizing
large Nix configuration codebases (NixOS, home-manager, nix-darwin, etc.).

**Core principle**: Every Nix file (except entry points like `flake.nix` and
`default.nix`) is a module of a **single top-level configuration** — typically a
flake-parts configuration. Each file implements a single feature across all
configuration classes that the feature touches. The file's path names the feature.

**The name** comes from dendrites — branching structures where all branches
connect back to a central structure (the top-level configuration).

## The Problem It Solves

Traditional Nix configurations suffer from complexity caused by:

- Multiple configuration classes (NixOS, home-manager, nix-darwin)
- Sharing modules across configurations
- Configuration nesting (NixOS contains home-manager contains programs)
- Cross-cutting concerns spanning multiple configuration classes
- Passing shared values through `specialArgs` chains

## Three Core Benefits

### 1. Type of every file is known
Every non-entry-point file is a Nixpkgs module of the same class as the
top-level configuration. No ambiguity about what a file contains or how it
connects to the system.

### 2. Automatic importing
Since file paths convey meaning to the author (not the evaluator), all
non-entry-point files can be automatically imported using trivial expressions
or libraries like `import-tree`. No manual import lists to maintain.

### 3. File path independence
File paths represent **features**, not configuration types. Files can be
freely renamed, moved, split, or reorganized without breaking anything.
A file called `desktop.nix` configures the "desktop" feature across NixOS,
home-manager, and whatever else it touches — it doesn't live inside a
`nixos/` or `home-manager/` directory.

## How It Works

### Architecture

```
┌─────────────────────────────────────────────────┐
│            Top-Level Configuration               │
│              (flake-parts)                        │
│                                                   │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────┐ │
│  │ meta.nix │ │admin.nix │ │  desktop.nix     │ │
│  │          │ │          │ │                    │ │
│  │ username │ │ NixOS:   │ │ NixOS: display   │ │
│  │ option   │ │  wheel   │ │ HM: browser, wm  │ │
│  │          │ │ Darwin:  │ │ Darwin: defaults  │ │
│  │          │ │  primary │ │                    │ │
│  └──────────┘ └──────────┘ └──────────────────┘ │
│                                                   │
│  Lower-level configs stored as option values:     │
│  config.my.modules.nixos.<feature>             │
│  config.my.modules.home-manager.<feature>      │
│  config.configurations.nixos.<name>.module         │
└─────────────────────────────────────────────────┘
```

### Key Mechanism: `deferredModule`

Lower-level configuration modules are stored as values of type `deferredModule`
in the top-level configuration. This type allows module definitions to be
composed and merged properly before they're evaluated in their target context.

```nix
# Declaring a container for NixOS feature modules
options.my.modules.nixos = lib.mkOption {
  type = lib.types.lazyAttrsOf lib.types.deferredModule;
  default = {};
};
```

### Required Knowledge

- Nix language fundamentals
- Nixpkgs module system (options, config, mkOption, mkIf, etc.)
- The `deferredModule` type and how deferred evaluation works

## Complete Example

### File Structure

```
project/
├── flake.nix           # Entry point — auto-imports all modules
└── modules/
    ├── meta.nix        # Shared options (username, etc.)
    ├── flake-parts.nix # Framework setup
    ├── systems.nix     # Supported systems
    ├── nixos.nix       # NixOS configuration infrastructure
    ├── admin.nix       # Admin access (cross-platform feature)
    ├── desktop.nix     # Desktop configuration (composes features)
    └── shell.nix       # Shell configuration
```

### flake.nix — Entry point with automatic importing

```nix
{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    nixpkgs.url = "github:nixos/nixpkgs/25.11";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; }
      (inputs.import-tree ./modules);
}
```

All files in `./modules/` are automatically imported as top-level modules.
No manual import list needed.

### meta.nix — Shared top-level options

```nix
{ lib, ... }:
{
  options.username = lib.mkOption {
    type = lib.types.singleLineStr;
    readOnly = true;
    default = "iam";
  };
}
```

Any module can access `config.username` — no `specialArgs` needed.

### admin.nix — Cross-platform feature module

```nix
{ config, ... }:
{
  my.modules = {
    nixos.pc = {
      # Grant wheel group membership on NixOS
      users.groups.wheel.members = [ config.username ];
    };
    darwin.pc = {
      # Set primary user on Darwin
      system.primaryUser = config.username;
    };
  };
}
```

One file, one feature ("admin access"), touching multiple configuration
classes (NixOS and Darwin). The `config.username` value comes from the
top-level configuration — no threading through `specialArgs`.

### nixos.nix — Configuration infrastructure

```nix
{ lib, config, ... }:
{
  options.configurations.nixos = lib.mkOption {
    type = lib.types.lazyAttrsOf (
      lib.types.submodule {
        options.module = lib.mkOption {
          type = lib.types.deferredModule;
        };
      }
    );
  };

  config.flake = {
    nixosConfigurations = lib.flip lib.mapAttrs config.configurations.nixos (
      name: { module }: lib.nixosSystem { modules = [ module ]; }
    );
  };
}
```

This creates a `configurations.nixos.<name>.module` option where feature
modules register their NixOS configuration pieces. The infrastructure module
then assembles them into actual `nixosConfigurations`.

### desktop.nix — Composing features into a configuration

```nix
{ config, ... }:
let
  inherit (config.my.modules) nixos;
in
{
  configurations.nixos.desktop.module = {
    imports = [ nixos.admin nixos.shell ];
    nixpkgs.hostPlatform = "x86_64-linux";
  };
}
```

The desktop configuration imports feature modules (`admin`, `shell`) that
were registered in `config.my.modules.nixos` by other files.

## Anti-Pattern: `specialArgs` Pass-Through

The primary anti-pattern the dendritic pattern eliminates is threading values
through nested `specialArgs` / `extraSpecialArgs` chains.

### The Problem

In traditional patterns, sharing a value across configuration boundaries requires:

```
flake.nix
  → specialArgs = { inherit username; }
    → nixos/laptop.nix (receives username)
      → extraSpecialArgs = { inherit username; }
        → home-manager evaluation (receives username)
          → home-manager module (finally uses username)
```

Every intermediate layer must explicitly forward values. Adding a new shared
value means touching every layer in the chain.

### The Dendritic Solution

In the dendritic pattern, shared values are top-level options:

```
top-level config
  → config.username is available everywhere
  → admin.nix reads config.username, writes to NixOS and Darwin modules
  → shell.nix reads config.username, writes to home-manager modules
```

No forwarding. No `specialArgs`. Every file can read any top-level option
directly because every file is a module of the same top-level configuration.

## Comparison: Traditional vs Dendritic

| Aspect | Traditional | Dendritic |
|--------|------------|-----------|
| File organization | By config class (`nixos/`, `home/`) | By feature (`admin.nix`, `desktop.nix`) |
| Sharing values | `specialArgs` chains | Top-level options |
| Import management | Manual import lists | Automatic (import-tree) |
| File type | Varies (NixOS module? HM module? function?) | Always top-level module |
| Cross-cutting features | Split across directories | Single file per feature |
| Adding a new shared value | Touch every forwarding layer | Add one option |

## Key Libraries

- **flake-parts** (`github:hercules-ci/flake-parts`) — The typical top-level
  configuration framework
- **import-tree** (`github:vic/import-tree`) — Automatic directory importing
- **den** (`github:vic/den`) — Aspect-oriented dendritic framework by Victor Borja

## Real-World Implementations

- https://github.com/mightyiam/infra — Shahar "Dawn" Ori (pattern author)
- https://github.com/vic/vix — Victor Borja
- https://github.com/GaetanLepage/nix-config — Gaëtan Lepage
- https://github.com/drupool/nixos-x260 — Pol Dellaiera (with blog post)
- https://github.com/bivsk/nix-iv — bivsk

## Community

- GitHub Discussions: https://github.com/mightyiam/dendritic/discussions
- Matrix room: `#dendritic:matrix.org`

## Applying to This Project

When asked to apply the dendritic pattern to this repository, consider:

1. **Current structure**: This project uses a traditional layout with `modules/nixos/`,
   `modules/home-manager/`, and `systems/` directories organized by configuration class.

2. **Migration path**: A dendritic refactor would:
   - Add `flake-parts` and `import-tree` as flake inputs
   - Create a `modules/` directory with feature-oriented files
   - Move cross-cutting concerns (e.g., a user that needs NixOS + HM config)
     into single feature files
   - Replace `specialArgs` usage with top-level options
   - Store lower-level configs as `deferredModule` option values
   - Keep Colmena integration (flake-parts has Colmena support)

3. **What stays the same**: Entry points (`flake.nix`), the `apps/` package
   directory, `homefiles/` dotfiles, and `overlays/` would remain unchanged.

4. **Risk areas**: The SOPS secrets integration, Colmena deployment setup,
   and per-host hardware configurations need careful handling during migration.

5. **Incremental adoption**: The pattern can be adopted incrementally — start
   by wrapping existing configs in flake-parts modules, then gradually
   consolidate cross-cutting features into single files.
