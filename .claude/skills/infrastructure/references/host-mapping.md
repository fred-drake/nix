# Host to Proxmox VMID Mapping

This reference maps hostnames to their Proxmox container IDs and physical locations.

## Active Colmena Hosts

| Hostname | Type | Services |
|----------|------|----------|
| headscale | Hetzner VPS | Headscale VPN |
| ironforge | Hetzner dedicated | gitea, woodpecker, paperless, calibre, nixarr (jellyfin, jellyseerr, sonarr, radarr, lidarr, prowlarr, sabnzbd, bazarr) |
| orgrimmar | Hetzner dedicated | gitea, woodpecker, paperless, calibre, resume |

## Non-Proxmox Hosts

| Hostname | Type | Architecture | Notes |
|----------|------|--------------|-------|
| nixosaarch64vm | VM | aarch64 | Build host for arm64 deploys |

## Quick Lookup Commands

Find which Proxmox host has a container:
```bash
for host in thrall sylvanas voljin; do
  echo "=== $host ==="
  ssh $host "pct list" 2>/dev/null | grep -i "<hostname>"
done
```

Get VMID for a hostname on specific Proxmox host:
```bash
ssh <proxmox-host> "pct list | grep <hostname>"
```
