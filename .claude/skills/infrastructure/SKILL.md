---
name: infrastructure
description: |
  Manage NixOS infrastructure for this nix flake project. Deploy configurations with Colmena, manage Proxmox LXC containers, troubleshoot services, and maintain servers.

  Use when: (1) Deploying NixOS configurations with colmena, (2) Managing Proxmox LXC containers (start, stop, reboot, status), (3) Troubleshooting server issues via SSH or pct exec, (4) Checking service status across hosts, (5) Any infrastructure maintenance task.

  IMPORTANT architecture notes:
  - dns1 and dns2 are critical infrastructure. NEVER deploy both simultaneously - deploy dns1 first, verify DNS works, then deploy dns2.
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
| dns1 | aarch64 (Raspberry Pi) | Critical DNS - deploy sequentially, verify before dns2 |
| dns2 | aarch64 (Raspberry Pi) | Critical DNS - deploy only after dns1 verified |
| larussa | x86_64 (bare metal) | Media storage, containers, NVIDIA GPU |

### Larussa Post-Deploy Verification

After deploying to larussa, **always verify GPU access**:

```bash
# 1. Deploy to larussa
colmena apply --on larussa --impure

# 2. Verify NVIDIA GPU is accessible
ssh larussa nvidia-smi
```

**If `nvidia-smi` errors out**, the NVIDIA driver failed to reload properly. Reboot is required:

```bash
# Reboot larussa
ssh larussa sudo reboot
```

**Recovery timeline:**
- Machine reboot: ~3-4 minutes
- Podman containers start: additional ~1-2 minutes
- Total: ~5-6 minutes before fully operational

**Verify recovery:**
```bash
# Check if machine is back
ssh larussa hostname

# Verify GPU after reboot
ssh larussa nvidia-smi

# Check podman containers are running
ssh larussa podman ps
```

**If issues persist**, use SSH to diagnose:
```bash
ssh larussa journalctl -u nvidia-persistenced -n 50
ssh larussa systemctl status podman.socket
ssh larussa podman ps -a
```

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

## DNS Server Deployment (Critical Infrastructure)

dns1 and dns2 are the backbone of the entire DNS infrastructure. **NEVER deploy both simultaneously.**

### Sequential Deployment Procedure

**Step 1: Deploy dns1**
```bash
colmena apply --on dns1 --impure
```

**Step 2: Verify dns1 is working**
```bash
# Test DNS resolution through dns1
dig @dns1 google.com

# Check that dns1 responds correctly
ssh dns1 systemctl status blocky
```

**Step 3: Only after dns1 is verified, deploy dns2**
```bash
colmena apply --on dns2 --impure
```

**Step 4: Verify dns2 is working**
```bash
# Test DNS resolution through dns2
dig @dns2 google.com

# Check that dns2 responds correctly
ssh dns2 systemctl status blocky
```

### DNS Verification Commands

```bash
# Quick DNS health check
dig @dns1 google.com +short
dig @dns2 google.com +short

# Check service status
ssh dns1 systemctl status blocky
ssh dns2 systemctl status blocky

# View recent logs
ssh dns1 journalctl -u blocky -n 20
ssh dns2 journalctl -u blocky -n 20
```

### If DNS Fails After Deploy

1. Check if the service is running: `ssh dns1 systemctl status blocky`
2. Check logs for errors: `ssh dns1 journalctl -u blocky -n 50`
3. Verify network connectivity: `ssh dns1 ping -c 3 8.8.8.8`
4. If necessary, reboot: `ssh dns1 sudo reboot`

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
