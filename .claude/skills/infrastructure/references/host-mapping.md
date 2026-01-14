# Host to Proxmox VMID Mapping

This reference maps hostnames to their Proxmox container IDs and physical locations.

## thrall (Proxmox Host)

| VMID | Hostname | Status |
|------|----------|--------|
| 100 | jellyseerr | running |
| 103 | radarr | stopped |
| 104 | prowlarr | running |
| 106 | n8n | running |
| 107 | gitea | running |
| 109 | brainrush-dev | running |
| 110 | uptime-kuma | running |
| 112 | grafana | running |
| 118 | gitea-runner-3 | running |
| 122 | woodpecker | running |
| 123 | resume | running |
| 700 | brainrush-auth | stopped |

## sylvanas (Proxmox Host)

*Update this section when hosts are discovered*

| VMID | Hostname | Status |
|------|----------|--------|
| TBD | TBD | TBD |

## voljin (Proxmox Host)

*Update this section when hosts are discovered*

| VMID | Hostname | Status |
|------|----------|--------|

## Non-Proxmox Hosts

| Hostname | Type | Architecture | Notes |
|----------|------|--------------|-------|
| dns1 | Raspberry Pi | aarch64 | Primary DNS, Blocky |
| dns2 | Raspberry Pi | aarch64 | Secondary DNS, Blocky |
| larussa | Bare Metal | x86_64 | Media storage, NAS |
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
