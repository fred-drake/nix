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

## Nix Versioning

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

## Debugging Common Issues

### Missing Nix Files

If you encounter an error indicating that a Nix file does not exist, this is typically because:
- The file is newly created and not yet tracked by Git
- The file exists in your working directory but hasn't been staged

**Solution**:
```bash
git add /path/to/new/file.nix
```

This ensures Nix can properly resolve file paths during evaluation. This is particularly important when using `import` statements or file-based configurations.

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

## Development Guidelines

### Code Organization

- **Modularity**: Break down configurations into reusable modules
- **DRY (Don't Repeat Yourself)**: Extract common patterns into functions or modules
- **Naming Conventions**: Use descriptive, consistent names for modules and variables

### Nix Best Practices

1. **Package References**:
   - Use `outPath` when creating symlinks to package locations
   - Prefer `mkOutOfStoreSymlink` for package paths

2. **VS Code Extensions**:
   - Path: `${config.home.path}/share/vscode/extensions`
   - Configuration:
     - Enable in `programs.vscode`
     - Configure extensions using the `extensions` attribute

### Tooling

- **MCP Servers**:
  - Use `nixos` MCP for NixOS-specific functionality
  - Use `context7` MCP for proper Nix syntax assistance

### Remote Deployment

- Use Colmena for remote configuration management
- Build artifacts are created locally and pushed to target machines
- Architecture-specific builds are handled by designated builders

## Common Patterns

### Module Structure

```nix
{
  # Function arguments
  config,
  lib,
  pkgs,
  ...
}:

with lib;


{
  # Module implementation
  options = {
    # Define your module options here
  };


  config = mkIf config.yourmodule.enable {
    # Configuration implementation
  };
}
```

## Getting Help

For Nix-related questions, use the available MCP servers:

- `nixos` for NixOS-specific functionality
- `context7` for general Nix syntax and best practices

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

## Testing

This project uses `just` for command running:

- To test that a build will compile without errors, run:
  ```bash
  just build
  ```
  
**Important**: Only run this command on the local machine. Do not execute it using colmena on remote machines.

## Contributing

When making changes:

1. Test configurations locally when possible
2. Document new modules and functions
3. Keep configurations modular and reusable
4. Follow existing patterns for consistency
