# Container to Host Mapping

Comprehensive mapping of containers to their NixOS hosts.

## docker.io

| Container | Tag | Host | Config Location |
|-----------|-----|------|-----------------|
| library/redis | latest | paperless | modules/nixos/host/paperless/paperless.nix |
| postgres | 16-alpine | resume | apps/resume.nix |
| postgres | 17 | paperless, sonarqube | modules/nixos/host/paperless/paperless.nix, apps/sonarqube.nix |
| postgres | 18 | woodpecker | apps/woodpecker.nix |
| woodpeckerci/woodpecker-agent | v3 | woodpecker | apps/woodpecker.nix |
| woodpeckerci/woodpecker-server | v3 | woodpecker | apps/woodpecker.nix |
| louislam/uptime-kuma | latest | uptime-kuma | (check apps/ or modules/) |
| solarkennedy/ipmi-kvm-docker | latest | (check usage) | apps/fetcher/containers-sha.nix |

## docker.n8n.io

| Container | Tag | Host | Config Location |
|-----------|-----|------|-----------------|
| n8nio/n8n | latest | n8n | (check apps/ or modules/) |

## ghcr.io

| Container | Tag | Host | Config Location |
|-----------|-----|------|-----------------|
| linuxserver/calibre | latest | larussa | (check larussa config) |
| linuxserver/calibre-web | latest | larussa | (check larussa config) |
| linuxserver/sabnzbd | latest | larussa | (check larussa config) |
| linuxserver/sonarr | latest | larussa | (check larussa config) |
| linuxserver/radarr | latest | larussa | (check larussa config) |
| paperless-ngx/paperless-ngx | latest | paperless | modules/nixos/host/paperless/paperless.nix |

## lscr.io

| Container | Tag | Host | Config Location |
|-----------|-----|------|-----------------|
| linuxserver/lazylibrarian | latest | larussa | (check larussa config) |

## docker.gitea.com

| Container | Tag | Host | Config Location |
|-----------|-----|------|-----------------|
| act_runner | latest | gitea-runner | (check gitea-runner config) |

## Host Summary

| Host | Containers |
|------|------------|
| woodpecker | postgres:18, woodpecker-agent:v3, woodpecker-server:v3 |
| paperless | postgres:17, redis:latest, paperless-ngx:latest |
| sonarqube | postgres:17 |
| resume | postgres:16-alpine |
| n8n | n8n:latest |
| larussa | calibre, calibre-web, sabnzbd, sonarr, radarr, lazylibrarian |
| uptime-kuma | uptime-kuma:latest |

## Finding Container Usage

To find which host uses a container:

```bash
# Search by container name
grep -r "container-name" --include="*.nix" apps/ modules/

# Search in containers-sha.nix for the full image reference
grep "container-name" apps/fetcher/containers-sha.nix
```

## Notes

- **larussa** is bare metal (not Proxmox LXC) - handles media containers
- **dns1/dns2** are Raspberry Pis (aarch64) - no containers, run Blocky natively
- Most other hosts are Proxmox LXC containers
