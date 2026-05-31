# Host Mapping Reference

This reference maps hostnames to their types, locations, and services.

## Hetzner Servers (Colmena-managed)

| Hostname | Type | Deploy User | SSH Port | Services |
|----------|------|-------------|----------|----------|
| headscale | Hetzner VPS | root | 22 | Headscale VPN, Tailscale client |
| ironforge | Hetzner dedicated | root | 2222 | nixarr (jellyfin, jellyseerr, sonarr, radarr, lidarr, prowlarr, sabnzbd, bazarr) |
| orgrimmar | Hetzner dedicated | root | 2222 | gitea, woodpecker, paperless, calibre, resume |
| stormwind | Hetzner dedicated | root | 2222 | traceway (observability stack); pulls its container from gitea's registry on orgrimmar |

## LAN NixOS Hosts (Colmena-managed)

| Hostname | Type | Deploy User | SSH Port | Purpose |
|----------|------|-------------|----------|---------|
| gnomeregan | Home LAN x86_64 box (Wi-Fi) | fdrake (sudo) | 22 | Borg backups, glance dashboard, personal automation jobs (process-daily, archive-email) under fdrake's systemd-user timers |

Gnomeregan is unusual: it tracks `nixpkgs-unstable` (via `meta.nodeNixpkgs.gnomeregan` in `colmena/default.nix`) and runs the full workstation home-manager feature stack for user `fdrake`, including claude-code and the SOPS-managed MCP configs. See `gnomeregan.md` for setup quirks and recovery procedure.

## WSL Hosts (Colmena-managed)

| Hostname | Type | Deploy User | SSH Port | Purpose |
|----------|------|-------------|----------|---------|
| anton | WSL NixOS on Windows | nixos (sudo) | 22 | Gaming and AI processing |
