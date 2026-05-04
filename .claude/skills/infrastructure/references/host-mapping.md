# Host Mapping Reference

This reference maps hostnames to their types, locations, and services.

## Hetzner Servers (Colmena-managed)

| Hostname | Type | Deploy User | SSH Port | Services |
|----------|------|-------------|----------|----------|
| headscale | Hetzner VPS | root | 22 | Headscale VPN, Tailscale client |
| ironforge | Hetzner dedicated | root | 2222 | nixarr (jellyfin, jellyseerr, sonarr, radarr, lidarr, prowlarr, sabnzbd, bazarr) |
| orgrimmar | Hetzner dedicated | root | 2222 | gitea, woodpecker, paperless, calibre, resume |

## WSL Hosts (Colmena-managed)

| Hostname | Type | Deploy User | SSH Port | Purpose |
|----------|------|-------------|----------|---------|
| anton | WSL NixOS on Windows | nixos (sudo) | 22 | Gaming and AI processing |
