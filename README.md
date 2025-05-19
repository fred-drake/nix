# Nix Configuration for Homelab and Workstations

## Overview

This repository contains Nix configurations for managing both personal workstations and homelab infrastructure. It serves as the single source of truth for all system configurations, ensuring consistency, reproducibility, and maintainability across all environments.

## System Architecture

### Workstations

- **macOS Workstations**: Managed via nix-darwin
  - `fredpc` (Linux with GUI)
  - `mac-studio`
  - `macbook-pro`
  - `laisas-mac-mini`
- **Linux Workstation**:
  - `fredpc` (Linux with GUI)

### Servers

- **Build Machines**:
  - `fredpc`: Builds x86_64-linux configurations
  - `nixosaarch64vm`: Builds aarch64-linux configurations
- **Deployment**: Remote servers are configured using Colmena

## Network Overview

The infrastructure uses multiple VLANs for security and organization:

- **Administration (VLAN 1)**: Server management and monitoring
- **Services (VLAN 50)**: Public-facing services and applications
- **IoT (VLAN 40)**: Internet of Things devices (isolated)
- **Workstations (VLAN 30)**: User devices and workstations

## Monitoring

- **Uptime Monitoring**: Uptime Kuma tracks service availability and SSL certificates
- **Metrics**: Prometheus collects system and application metrics
- **Alerting**: Configured for both critical and warning-level notifications

## Prerequisites

1. **Nix** installed on your system
2. **SSH Key** (`id_ed25519`) in your `~/.ssh` directory
3. **Homebrew** installed for package management
4. **Git** for version control

> **Note**: The `id_ed25519` key is used for personal secrets and must be properly secured with 600 permissions.

## Development Environment

This repository uses [devenv](https://devenv.sh/) to provide a consistent development environment. The `devenv.nix` file contains all the libraries and helper scripts needed for processing this repository.

### Features Provided by devenv

- **Development Tools**: Includes tools like `colmena`, `just`, `alejandra`, and other utilities
- **Helper Scripts**: Automated scripts for updating VSCode extensions, container digests, and more
- **Consistent Environment**: Ensures all contributors have the same tooling and dependencies

### Using devenv

To enter the development environment:

```bash
cd ~/nix
devenv up
```

This will load all the tools and environment variables defined in `devenv.nix`. Once inside the environment, you can use the helper scripts and tools without additional installation.

If you have [direnv](https://direnv.net/) installed and configured, the development environment will be automatically activated when you enter the repository directory.

## Just Targets

This project uses `just` for task automation. Here are the available targets:

- `switch` - Switches the system to the current configuration
- `build` - Builds the system in its current form
- `update-all` - Updates everything (runs update, update-vscode-extensions, update-repos, update-container-digests, and update-secrets)
- `update` - Updates input definitions from remote resources
- `update-vscode-extensions` - Refreshes VSCode Extensions
- `update-repos` - Pulls the latest hashes and shas from the repos in `apps/fetcher/repos.toml`
- `update-container-digests` - Updates the SHA digests of container images
- `update-secrets` - Updates the secrets flake
- `colmena HOST` - Runs colmena remote switch on the specified host
- `colmena-dns` - Runs colmena apply on dns1 and dns2 hosts (runs on nixosaarch64vm under aarch64-linux architecture)

## Container Management

This project uses Podman for container runtime with the following practices:

- **Image Management**:
  - Images are pinned to specific digests for reproducibility
  - The `container-digest` tool generates Nix files with SHA256 hashes
  - Container updates are explicit and intentional

## Initial Setup

1. Install Nix (if not already installed):

   ```bash
   sh <(curl -L https://nixos.org/nix/install)
   ```

2. Install Homebrew (required):

   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

3. Clone this repository:

   ```bash
   git clone https://github.com/fred-drake/nix ~/nix
   cd ~/nix
   ```

4. Build the flake for your system. This will take a while the first time.
   - Macbook Pro: `nix --extra-experimental-features "nix-command flakes" build .#darwinConfigurations.Freds-MacBook-Pro.system`
   - Mac Studio: `nix --extra-experimental-features "nix-command flakes" build .#darwinConfiguratiions.Freds-Mac-Studio.system`
   - My better half's Mac Mini: `nix --extra-experimental-features "nix-command flakes" build .#darwinConfiguratiions.Laisas-Mac-mini.system`

## Key Management

### Personal Key (`id_ed25519`)

- Used for personal secrets and configurations
- Applies to both workstations and servers
- Manages user-specific settings and access tokens

### Infrastructure Key

- Dedicated to server infrastructure
- Manages service credentials and system configurations
- Separate from personal keys for better security

## Development Practices

### Code Organization

- **Modular Design**: Configurations are broken into reusable modules
- **DRY Principle**: Common patterns are extracted into functions
- **Naming**: Descriptive and consistent naming conventions are used throughout

### Nix Best Practices

- **Package References**: Use `outPath` for symlinks to package locations
- **VS Code Extensions**: Managed through Home Manager configuration
- **Remote Deployment**: Colmena is used for managing remote server configurations

## Getting Help

For assistance with Nix configurations:

- Use `nixos` MCP server for NixOS-specific functionality
- Use `context7` MCP server for general Nix syntax assistance

## Final Steps

1. Run the initial switch into the flake. This will take a long while the first time: `./result/sw/bin/darwin-rebuild switch --flake ~/nix`
2. Reboot the machine to ensure all Mac settings were applied.

## Post-setup That Can't Be Automated Yet

1. Allow Apple Watch to be unlock the computer or sudo: `Settings -> Touch ID & Password -> Use Apple Watch to unlock applications and your Mac`
2. Open Raycast and import configuration from iCloud Drive
3. Disable spotlight search: `Settings -> Keyboard shortcuts -> Disable Spotlight Search`. Raycast will now be the default search tool when hitting Cmd+Space.
