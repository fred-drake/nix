# Nix Homelab Configuration

This document provides essential context for working with this Nix-based homelab configuration.

## Project Purpose

This repository serves as the single source of truth for infrastructure as code (IaC) across all servers in the homelab environment. The primary goals are:

- **Declarative Configuration**: Define the desired state of all systems
- **Reproducibility**: Ensure consistent environments across all machines
- **Maintainability**: Keep configurations DRY and well-organized

## System Architecture

### Host Types

1. **Directly Configured Hosts** (local configuration):

   - `fredpc` (Linux with GUI)
   - `nixosaarch64vm` (aarch64 Linux)
   - `laisas-mac-mini` (macOS with nix-darwin)
   - `mac-studio` (macOS with nix-darwin)
   - `macbook-pro` (macOS with nix-darwin)

2. **Remotely Configured Hosts** (via Colmena):
   - x86_64-linux: Built on `fredpc`
   - aarch64-linux: Built on `nixosaarch64vm`

### Platform-Specific Notes

#### macOS (Darwin)
- Uses nix-homebrew for cask management
- System names match computer names (e.g., "Freds-MacBook-Pro")
- Homebrew required for initial setup

#### NixOS
- Direct configurations for local machines
- Colmena for remote deployments
- Architecture-specific builders (x86_64 on fredpc, aarch64 on nixosaarch64vm)

## Nix Versioning

### Multi-Channel Nixpkgs
- `nixpkgs` (unstable) - Primary for workstations
- `nixpkgs-stable` - For servers (25.05)
- `nixpkgs-fred` - Custom fork with specific fixes

### Workstations

- Use the latest packages from the `nixpkgs` repository
- Exceptions are made for packages with build issues
- Fallback options when issues arise:
  - Use the unstable version of the problematic package
  - Or pin to the stable version of that specific package

### Servers

- Use the latest stable NixOS release (currently **25.05**)
- All server configurations are pinned to this release for stability
- Updates to the next stable release should be tested thoroughly before deployment

## Container Management

This project uses containers for certain applications, managed with the following approach:

### Container Runtime

- **Podman** is used as the container runtime
- Preferred over Docker for better security and rootless operation

### Container Images

- Container images are managed with content-addressable hashes for reproducibility
- The `container-digest` tool is used to generate Nix files containing the proper SHA256 hashes
- **Important**: LLMs should never update container-digest files - these are for reference only and should only be updated manually by authorized maintainers

### Versioning Strategy

- Each container tag is pinned to a specific digest
- Updates to container versions are explicit and intentional
- The process to update a container:
  1. Update the container tag in the relevant configuration
  2. Run `container-digest` to generate new hash files
  3. Review and commit the updated hash files

This ensures that container deployments are:

- Reproducible (same hash = same container)
- Verifiable (hashes are committed to version control)
- Controllable (updates are explicit and traceable)

## Network Architecture

The network is segmented into multiple VLANs for security and organization:

### Untagged VLAN (Administration)

- **Purpose**: Primary network for server administration and management
- **Access**:
  - SSH access to servers
  - Prometheus metrics and monitoring
  - Internal service communication
- **Permissions**:
  - Can access: Services, Workstation, and IoT networks
  - Inbound access: Restricted to administration interfaces only

### VLAN 50 (Services)

- **Purpose**: Public-facing services and applications
- **Examples**:
  - Web interfaces
  - Public APIs
  - Application endpoints
- **Permissions**:
  - Can access: IoT network
  - Cannot access: Workstation or Administration networks
  - Accessible from: Internet (as needed) and internal networks

### VLAN 40 (IoT)

- **Purpose**: Internet of Things devices and related services
- **Examples**:
  - Home Assistant
  - Homebridge
  - IoT device communication
- **Permissions**:
  - Cannot access: Other internal networks
  - Isolated for security of IoT devices

### VLAN 30 (Workstations)

- **Purpose**: User workstations and devices
- **Examples**:
  - Laptops
  - Desktops
  - User devices
- **Permissions**:
  - Can access: Services and IoT networks
  - Cannot access: Administration network
  - Intended for regular user traffic

## Monitoring

The homelab uses a comprehensive monitoring strategy to ensure system health and reliability:

### Uptime Monitoring

- **Uptime Kuma** is the primary tool for monitoring service availability
- Monitors:
  - Server uptime and response
  - Web service endpoints
  - SSL/TLS certificate expiration
- Sends notifications for:
  - Service outages
  - Certificate expiration warnings
  - Other critical alerts

### Metrics Collection

- **Prometheus** is used for metrics collection and storage
- Metrics are pulled from services where possible (pull-based model)
- Monitored components include:
  - System metrics (CPU, memory, disk, network)
  - Application-specific metrics
  - Service health endpoints

### Alerting

- Alerts are configured based on predefined thresholds
- Critical alerts are sent immediately
- Warning-level alerts are used for attention-required but non-critical issues

### Access

- Monitoring dashboards are accessible via the Services network (VLAN 50)
- Administrative access to monitoring systems is restricted to the Administration network

## Key Management

This project uses two distinct SSH keys for managing encrypted secrets:

### id_ed25519 (Personal Key)

- **Purpose**: General encryption/decryption of personal secrets
- **Usage**:
  - Used for all sensitive information
  - Applies to both workstations and servers
  - Used for secrets of a personal nature
- **Scope**:
  - User-specific configurations
  - Personal access tokens
  - Individual developer settings

### id_infrastructure (Infrastructure Key)

- **Purpose**: Server-specific secret management
- **Usage**:
  - Dedicated to server infrastructure
  - Used for encoding and decoding server-specific secrets
  - Managed separately from personal keys
- **Scope**:
  - Service credentials
  - System-level configurations
  - Shared infrastructure secrets

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

## Development Guidelines

### Code Organization

- Repository structure follows a clear hierarchy:
  - `flake.nix` - Entry point defining all systems
  - `modules/` - Reusable configuration modules
  - `apps/` - Application-specific configurations
  - `colmena/` - Remote server deployment definitions
  - `systems/` - System builder functions
  - `lib/` - Helper functions

### Module Pattern

All modules follow this structure:
```nix
{ config, lib, pkgs, ... }:
with lib;
{
  options = { /* module options */ };
  config = mkIf config.module.enable { /* implementation */ };
}
```

### Helper Functions

- `lib.mkHomeManager` - Creates home-manager configurations
- `mkDarwinSystem` - Builds Darwin systems with standard setup
- `mkColmenaSystem` - Defines remote deployments

### Tooling

- **MCP Servers**:
  - Use `nixos` MCP for NixOS-specific functionality
  - Use `context7` MCP for proper Nix syntax assistance
- **Development Environment**:
  - `devenv` provides consistent tooling
  - Activated automatically with direnv
  - Includes colmena, just, alejandra formatter

### Remote Deployment

- Use Colmena for remote configuration management
- Build artifacts are created locally and pushed to target machines
- Architecture-specific builds are handled by designated builders

## Common Workflows

### Adding a new package to home-manager
1. Edit relevant module in `modules/home-manager/`
2. Add package to `home.packages` or appropriate program config
3. Run `just switch` to apply

### Creating a new service module
1. Create module file in appropriate directory
2. Follow existing module patterns
3. Import in relevant system configuration
4. Add to git before building: `git add path/to/module.nix`

### Updating a container version
1. Change container tag in configuration
2. Run `just update-container-digests`
3. Review and commit the updated SHA files

## Best Practices

- After modifying code, run `just build` to ensure that everything builds without errors. If there are errors, fix them. Use `brave-search` and `context7` MCPs if you are not confident with the solution.
- Before modifying any code, use the context7 and brave-search MCP servers to understand syntax and best practices

## Secrets Management

This project uses a separate `nix-secrets` repository to manage sensitive information. There are two types of secrets:

### 1. Soft Secrets

- **Purpose**: Store non-sensitive configuration that should be kept separate from the main repository
- **Examples**:
  - IP addresses
  - Host domains
  - Non-sensitive configuration values

### 2. Regular Secrets

- **Purpose**: Store sensitive private information
- **Examples**:
  - API keys
  - Passwords
  - Authentication tokens
  - Encryption keys

### Implementation

- The `sops-nix` library is used for secret decryption and management
- Secrets are stored in the `nix-secrets` repository
- Access to the secrets repository should be restricted to authorized personnel only
