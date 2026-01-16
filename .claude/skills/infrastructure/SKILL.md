---
name: infrastructure
description: |
  Manage NixOS infrastructure for this nix flake project. Deploy configurations with Colmena, manage Proxmox LXC containers, troubleshoot services, and maintain servers.

  Use when: (1) Deploying NixOS configurations with colmena, (2) Managing Proxmox LXC containers (start, stop, reboot, status), (3) Troubleshooting server issues via SSH or pct exec, (4) Checking service status across hosts, (5) Any infrastructure maintenance task.

  IMPORTANT architecture notes:
  - dns1 and dns2 run on Raspberry Pis (aarch64). Cannot deploy from x86 hosts. Use nixosaarch64vm or another arm64 NixOS machine.
  - larussa is bare metal (not Proxmox LXC) - media storage and containers.
  - All other servers are Proxmox LXC containers.
---

# Infrastructure Management

## Quick Reference

### Deploy with Colmena

```bash
# Single host
colmena apply --on <hostname> --impure

# Multiple hosts
colmena apply --on host1,host2,host3 --impure

# DNS servers (arm64 - run from nixosaarch64vm)
colmena apply --on dns1,dns2 --impure

# Build only (no deploy)
colmena build --on <hostname> --impure
```

### Proxmox Container Management

SSH to Proxmox host first, then use `pct`:

```bash
# List containers on a host
ssh <proxmox-host> "pct list"

# Container status
ssh <proxmox-host> "pct status <vmid>"
ssh <proxmox-host> "pct status <vmid> --verbose"

# Start/stop/reboot
ssh <proxmox-host> "pct start <vmid>"
ssh <proxmox-host> "pct stop <vmid>"
ssh <proxmox-host> "pct reboot <vmid>"

# Execute command in container
ssh <proxmox-host> "pct exec <vmid> -- /run/current-system/sw/bin/<command>"

# Common commands via pct exec
ssh <proxmox-host> "pct exec <vmid> -- /run/current-system/sw/bin/systemctl status <service>"
ssh <proxmox-host> "pct exec <vmid> -- /run/current-system/sw/bin/journalctl -u <service> -n 50"
```

## Server Inventory

### Proxmox Hosts

| Host | Description |
|------|-------------|
| thrall | Proxmox cluster node |
| sylvanas | Proxmox cluster node |
| voljin | Proxmox cluster node |

### Special Hosts (NOT on Proxmox)

| Host | Architecture | Notes |
|------|--------------|-------|
| dns1 | aarch64 (Raspberry Pi) | Deploy from arm64 machine only |
| dns2 | aarch64 (Raspberry Pi) | Deploy from arm64 machine only |
| larussa | x86_64 (bare metal) | Media storage, containers |

### Proxmox LXC Containers

All other hosts are LXC containers. Use `pct list` on Proxmox hosts to see VMIDs.

Common hosts: gitea, gitea-runner-1/2/3, prometheus, grafana, uptime-kuma, sonarqube, jellyseerr, prowlarr, n8n, minio, scanner, paperless, woodpecker, resume, glance, external-metrics

## Troubleshooting Workflows

### Container Won't Respond

1. Check status: `ssh <proxmox-host> "pct status <vmid> --verbose"`
2. If running but commands fail: `ssh <proxmox-host> "pct reboot <vmid>"`
3. Wait 15-30 seconds, verify: `ssh <proxmox-host> "pct status <vmid>"`
4. Re-deploy if needed: `colmena apply --on <hostname> --impure`

### Service Not Working

1. Check service status:
   ```bash
   ssh <proxmox-host> "pct exec <vmid> -- /run/current-system/sw/bin/systemctl status <service>"
   ```
2. Check logs:
   ```bash
   ssh <proxmox-host> "pct exec <vmid> -- /run/current-system/sw/bin/journalctl -u <service> -n 100"
   ```
3. Restart service:
   ```bash
   ssh <proxmox-host> "pct exec <vmid> -- /run/current-system/sw/bin/systemctl restart <service>"
   ```

### Podman/Container Issues

Check socket status:
```bash
ssh <proxmox-host> "pct exec <vmid> -- /run/current-system/sw/bin/systemctl status podman.socket"
```

List running containers:
```bash
ssh <proxmox-host> "pct exec <vmid> -- /run/current-system/sw/bin/podman ps -a"
```

### SSH Connection Issues

If colmena fails with SSH errors:
1. Verify container is running on Proxmox
2. Check if SSH is listening: `pct exec <vmid> -- /run/current-system/sw/bin/ss -tlnp | grep 22`
3. Reboot container if necessary

## DNS Server Deployment (ARM64)

dns1 and dns2 are Raspberry Pis. Cannot cross-compile from x86_64.

**Option 1**: SSH to nixosaarch64vm (or any arm64 NixOS)
```bash
ssh nixosaarch64vm
cd /path/to/nix  # Clone repo or use shared mount
colmena apply --on dns1,dns2 --impure
```

**Option 2**: Use justfile shortcut (requires arm64 host)
```bash
just colmena-dns
```

## Common Colmena Patterns

### Deploy All Gitea Runners
```bash
colmena apply --on gitea-runner-1,gitea-runner-2,gitea-runner-3 --impure
```

### Deploy Monitoring Stack
```bash
colmena apply --on prometheus,grafana --impure
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
| NixOS host configs | `modules/nixos/host/<hostname>/configuration.nix` |
| Application configs | `apps/<appname>.nix` |
| Secrets configs | `modules/secrets/<hostname>.nix` |
| Container image SHAs | `apps/fetcher/containers-sha.nix` |
| Container definitions | `apps/fetcher/containers.toml` |

## Related Skills

- **provision-nixos-server**: Create new servers from scratch
- For creating new hosts, use `/provision-nixos-server` skill instead
