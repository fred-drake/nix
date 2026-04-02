---
name: infrastructure
description: |
  Manage NixOS infrastructure for this nix flake project. Deploy configurations with Colmena, troubleshoot services, and maintain servers.

  Use when: (1) Deploying NixOS configurations with colmena, (2) Troubleshooting server issues via SSH, (3) Checking service status across hosts, (4) Any infrastructure maintenance task.

  IMPORTANT architecture notes:
  - Hetzner servers are remote VPS/dedicated hosts, deployed as root.
  - anton is a WSL NixOS host on a Windows laptop, deployed as the nixos user via sudo.
---

# Infrastructure Management

## Quick Reference

### Deploy with Colmena

```bash
# Single host
colmena apply --on <hostname> --impure

# Multiple hosts
colmena apply --on host1,host2,host3 --impure

# Build only (no deploy)
colmena build --on <hostname> --impure
```

## Server Inventory

### Hetzner Servers (Colmena-managed, root user)

| Host | Type | Services |
|------|------|----------|
| headscale | Hetzner VPS | Headscale VPN, Tailscale client |
| ironforge | Hetzner dedicated | nixarr (jellyfin, jellyseerr, sonarr, radarr, lidarr, prowlarr, sabnzbd, bazarr) |
| orgrimmar | Hetzner dedicated | gitea, woodpecker, paperless, calibre, resume |

### WSL Hosts (Colmena-managed, nixos user with sudo)

| Host | Type | Purpose |
|------|------|---------|
| anton | WSL NixOS on Windows laptop | Gaming and AI processing |

### On-Prem Workstations (locally configured)

| Host | Type | Notes |
|------|------|-------|
| fredpc | x86_64-linux | GUI, NVIDIA CUDA, glance dashboard |
| nixosaarch64vm | aarch64-linux | ARM64 build host |

## Troubleshooting Workflows

### Service Not Working

1. Check service status:
   ```bash
   ssh <hostname> "systemctl status <service>"
   ```
2. Check logs:
   ```bash
   ssh <hostname> "journalctl -u <service> -n 100"
   ```
3. Restart service:
   ```bash
   ssh <hostname> "systemctl restart <service>"
   ```

Note: For Hetzner servers, SSH as root. For anton, SSH as nixos and use sudo.

### Podman/Container Issues

Check socket status:
```bash
ssh <hostname> "systemctl status podman.socket"
```

List running containers:
```bash
ssh <hostname> "podman ps -a"
```

### SSH Connection Issues

If colmena fails with SSH errors:
1. Verify the host is reachable: `ping <hostname>`
2. Check if SSH is listening: `ssh <hostname> "ss -tlnp | grep 22"`
3. For Hetzner servers, check via Hetzner console if needed

## Common Colmena Patterns

### Deploy All Hetzner Hosts
```bash
colmena apply --on headscale,ironforge,orgrimmar --impure
```

### Deploy All Hosts
```bash
colmena apply --on headscale,ironforge,orgrimmar,anton --impure
```

### Update Secrets Before Deploy
```bash
just update-secrets
colmena apply --on <hostname> --impure
```

## File Locations

| Purpose | Path |
|---------|------|
| Colmena host configs | `colmena/hosts/<hostname>.nix` |
| Hetzner common modules | `colmena/hetzner-common/` |
| WSL common modules | `colmena/wsl-common/` |
| NixOS host configs | `modules/nixos/host/<hostname>/configuration.nix` |
| Application configs | `apps/<appname>.nix` |
| Secrets configs | `modules/secrets/<hostname>.nix` |
| Container image SHAs | `apps/fetcher/containers-sha.nix` |
| Container definitions | `apps/fetcher/containers.toml` |

## Related Skills

- **provision-nixos-server**: Create new Hetzner servers from scratch
