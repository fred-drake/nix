# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Essential Commands

### System Management
```bash
# Build and switch to new configuration (local)
just switch

# Build without switching
just build

# Deploy to remote host via Colmena
just colmena <hostname>

# Deploy to DNS servers
just colmena-dns
```

### Maintenance Commands
```bash
# Update everything (flake inputs, extensions, repos, containers, secrets)
just update-all

# Update individual components
just update              # Update flake inputs
just update-secrets      # Update secrets flake (required when secrets change)
just update-vscode-extensions
just update-repos       # Update repository hashes in apps/fetcher/repos.toml
just update-container-digests
```

### Debugging Git Issues
```bash
# Add new Nix files to git (required for import statements)
git add /path/to/new/file.nix

# If secrets repository is not found
just update-secrets
```

## Architecture Overview

### Repository Structure
This is a Nix flake-based configuration managing both workstations (macOS/Linux) and homelab infrastructure:

```
flake.nix           # Entry point defining all systems
├── modules/        # Reusable configuration modules
│   ├── darwin/     # macOS-specific system configs
│   ├── home-manager/   # User environment configs
│   ├── nixos/      # NixOS system configs
│   └── secrets/    # Secret configuration modules
├── apps/           # Application-specific configurations
├── colmena/        # Remote server deployment definitions
├── systems/        # System builder functions
└── lib/            # Helper functions
```

### Key Concepts

**1. Multi-Channel Nixpkgs**
- `nixpkgs` (unstable) - Primary for workstations
- `nixpkgs-stable` - For servers (25.05)
- `nixpkgs-fred` - Custom fork with specific fixes

**2. System Types**
- **Darwin Systems**: macOS machines using nix-darwin
- **NixOS Systems**: Linux machines (local and remote)
- **Colmena Deployments**: Remote NixOS servers

**3. Secret Management**
- Uses `sops-nix` with age encryption
- Secrets stored in separate `nix-secrets` repository
- Decryption key: `~/.ssh/id_ed25519`
- Personal vs infrastructure keys for different secret types
- Secrets contain two types: secrets and soft-secrets. Soft secrets are not encrypted but store information that is a bit more personalized, such as IP addresses. Secrets, such as API keys or passwords, are encrypted with sops.

**4. Module Pattern**
All modules follow this structure:
```nix
{ config, lib, pkgs, ... }:
with lib;
{
  options = { /* module options */ };
  config = mkIf config.module.enable { /* implementation */ };
}
```

**5. Helper Functions**
- `lib.mkHomeManager` - Creates home-manager configurations
- `mkDarwinSystem` - Builds Darwin systems with standard setup
- `mkColmenaSystem` - Defines remote deployments

### Platform-Specific Notes

**macOS (Darwin)**
- Uses nix-homebrew for cask management
- System names match computer names (e.g., "Freds-MacBook-Pro")
- Homebrew required for initial setup

**NixOS**
- Direct configurations for local machines
- Colmena for remote deployments
- Architecture-specific builders (x86_64 on fredpc, aarch64 on nixosaarch64vm)

### Container Management
- Uses Podman runtime
- Containers pinned to specific SHA digests
- Update process: modify tag → run `update-container-digests` → commit

### Development Environment
- `devenv` provides consistent tooling
- Activated automatically with direnv
- Includes colmena, just, alejandra formatter

### Network Architecture
- VLAN 1: Administration (SSH, monitoring)
- VLAN 50: Services (public-facing)
- VLAN 40: IoT (isolated)
- VLAN 30: Workstations

### Common Workflows

**Adding a new package to home-manager:**
1. Edit relevant module in `modules/home-manager/`
2. Add package to `home.packages` or appropriate program config
3. Run `just switch` to apply

**Creating a new service module:**
1. Create module file in appropriate directory
2. Follow existing module patterns
3. Import in relevant system configuration
4. Add to git before building: `git add path/to/module.nix`

**Updating a container version:**
1. Change container tag in configuration
2. Run `just update-container-digests`
3. Review and commit the updated SHA files

## Best Practices

- After modifying code, run `just build` to ensure that everything builds without errors. If there are errors, fix them. Use `brave-search` and `context7` MCPs if you are not confident with the solution.
- Before modifying any code, use the context7 and brave-search MCP servers to understand syntax and best practices
