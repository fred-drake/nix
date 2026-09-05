# Host Mapping Reference

This reference maps hostnames to their types, locations, services, and web endpoints.
The "Web Endpoints" tables below are the **source of truth for deployment health
checks**: the `mass-deploy` skill requires every URL listed there to be probed
after each clean host switch and to return the expected status before advancing.

## Hetzner Servers (Colmena-managed)

| Hostname | Type | Deploy User | SSH Port | Services |
|----------|------|-------------|----------|----------|
| headscale (aka "gateway") | Hetzner VPS | root | 22 | Legacy-named official Tailscale SaaS subnet/DNS gateway; advertises the Hetzner private net 10.1.0.0/16 and runs no Headscale control plane |
| ironforge | Hetzner dedicated | root | 2222 | media stack, all podman: jellyfin, seerr (+ jellyseerr redirect), sonarr, radarr, lidarr, prowlarr, sabnzbd, bazarr |
| orgrimmar | Hetzner dedicated | root | 2222 | gitea (+ gitea-status checker), woodpecker, paperless (+ paperless-ai), calibre-web, resume, filebrowser |
| stormwind | Hetzner dedicated | root | 2222 | traceway (observability stack; container pulled from gitea's registry on orgrimmar), gatus (internal uptime dashboard) |

## LAN NixOS Hosts (Colmena-managed)

| Hostname | Type | Deploy User | SSH Port | Purpose |
|----------|------|-------------|----------|---------|
| gnomeregan | Home LAN x86_64 box (Wi-Fi) | fdrake (sudo) | 22 | Borg backups, glance dashboard, personal automation jobs (process-daily, archive-email) under fdrake's systemd-user timers |

Gnomeregan is unusual: it tracks `nixpkgs-unstable` (via `meta.nodeNixpkgs.gnomeregan` in `colmena/default.nix`) and runs the full workstation home-manager feature stack for user `fdrake`, including claude-code and the SOPS-managed MCP configs. See `gnomeregan.md` for setup quirks and recovery procedure.

## WSL Hosts (Colmena-managed)

| Hostname | Type | Deploy User | SSH Port | Purpose |
|----------|------|-------------|----------|---------|
| anton | WSL NixOS on Windows | nixos (sudo) | 22 | Gaming and AI processing |

## Canonical Deploy Order

Full-fleet deployments apply hosts **one at a time**, in this order:

1. stormwind
2. ironforge
3. orgrimmar
4. anton
5. gnomeregan
6. headscale ("gateway")

## Web Endpoints (deployment health checks)

Every URL below must return its expected status (after following redirects;
`curl -skL -o /dev/null -w '%{http_code}' --max-time 20 '<url>'`) for the fleet
to be considered healthy. All `*.internal.freddrake.com` names resolve through
the `headscale` gateway on official Tailscale SaaS, so the probing machine must
be on the tailnet. If every internal name fails DNS at once, run `tailscale
status` locally first; a disconnected local client looks exactly like a
fleet-wide outage.

### stormwind

| URL | Service | Expect |
|-----|---------|--------|
| https://traceway.internal.freddrake.com/ | traceway observability app | 2xx |
| https://gatus.internal.freddrake.com/ | gatus uptime dashboard | 2xx |

### ironforge

| URL | Service | Expect |
|-----|---------|--------|
| https://jellyfin.internal.freddrake.com/ | jellyfin | 2xx (redirects to /web/) |
| https://seerr.internal.freddrake.com/ | seerr | 2xx (redirects to /login) |
| https://jellyseerr.internal.freddrake.com/ | nginx 301 redirect to seerr | 2xx after redirects |
| https://sonarr.internal.freddrake.com/ | sonarr | 2xx (redirects to /login) |
| https://radarr.internal.freddrake.com/ | radarr | 2xx (redirects to /login) |
| https://lidarr.internal.freddrake.com/ | lidarr | 2xx (redirects to /login) |
| https://prowlarr.internal.freddrake.com/ | prowlarr | 2xx (redirects to /login) |
| https://sabnzbd.internal.freddrake.com/ | sabnzbd | 2xx |
| https://bazarr.internal.freddrake.com/ | bazarr | 2xx |

### orgrimmar

| URL | Service | Expect |
|-----|---------|--------|
| https://gitea.internal.freddrake.com/ | gitea | 2xx |
| https://gitea-status.internal.freddrake.com/health | gitea-check-service (root path is 404 by design — probe /health) | 2xx |
| https://woodpecker.internal.freddrake.com/ | woodpecker CI | 2xx |
| https://paperless.internal.freddrake.com/ | paperless-ngx | 2xx (redirects to login) |
| https://paperless-ai.internal.freddrake.com/ | paperless-ai | 2xx (redirects to /login) |
| https://resume.internal.freddrake.com/ | reactive-resume | 2xx |
| https://calibre-web.internal.freddrake.com/ | calibre-web | 2xx (redirects to /login) |
| https://files.internal.freddrake.com/ | filebrowser | 2xx |

### anton

No web endpoints. Health = the colmena switch verified active over ssh.

### gnomeregan

| URL | Service | Expect |
|-----|---------|--------|
| http://gnomeregan.internal.freddrake.com:8084/ | glance dashboard (plain HTTP, no TLS on this host) | 2xx |

### headscale ("gateway")

No web endpoints. Despite its legacy hostname, this machine does not run a
Headscale control plane or nginx. Deployment health comes from SSH reachability,
active-generation equality after the Colmena switch, local Tailscale readiness,
and successful probes of the private Hetzner applications listed above.

Those application names resolve through this machine's DNS service and their
`10.1.1.x` addresses are reached through the `10.1.0.0/16` subnet route it
advertises to official Tailscale SaaS. Successful application probes therefore
exercise the gateway indirectly; do not add a synthetic gateway URL.

### Intentionally excluded from health checks

- `http://10.1.1.3:9000/metrics`, `http://10.1.1.4:9000/metrics`, and the other
  node-exporter `:9000` endpoints — firewall-filtered from tailnet clients by
  design. Do not "fix" them to make a probe pass.
