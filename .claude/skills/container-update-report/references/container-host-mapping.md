# Container to Host Mapping

Comprehensive mapping of containers to their NixOS hosts.

## docker.io

| Container | Tag | Host | Config Location |
|-----------|-----|------|-----------------|
| amruthpillai/reactive-resume | latest | orgrimmar | modules/nixos/host/orgrimmar/resume.nix |
| apache/tika | latest | ironforge | modules/nixos/host/ironforge/paperless.nix |
| clusterzx/paperless-ai | latest | ironforge | modules/nixos/host/ironforge/paperless.nix |
| gotenberg/gotenberg | latest | ironforge | modules/nixos/host/ironforge/paperless.nix |
| jellyfin/jellyfin | latest | ironforge | modules/nixos/host/ironforge/nixarr.nix |
| library/redis | latest | ironforge | modules/nixos/host/ironforge/paperless.nix |
| postgres | 16-alpine | orgrimmar | modules/nixos/host/orgrimmar/resume.nix |
| postgres | 17 | ironforge | modules/nixos/host/ironforge/paperless.nix |
| postgres | 18 | orgrimmar | modules/nixos/host/orgrimmar/woodpecker.nix |
| woodpeckerci/woodpecker-agent | v3 | orgrimmar | modules/nixos/host/orgrimmar/woodpecker.nix |
| woodpeckerci/woodpecker-server | v3 | orgrimmar | modules/nixos/host/orgrimmar/woodpecker.nix |

## docker.gitea.com

| Container | Tag | Host | Config Location |
|-----------|-----|------|-----------------|
| gitea | 1-rootless | orgrimmar | modules/nixos/host/orgrimmar/gitea.nix |
| act_runner | latest | (gitea-runner hosts - currently unused) | apps/gitea-runner/default.nix |

## ghcr.io

| Container | Tag | Host | Config Location |
|-----------|-----|------|-----------------|
| browserless/chromium | v2.18.0 | orgrimmar | modules/nixos/host/orgrimmar/resume.nix |
| fred-drake/gitea-check-service | latest | orgrimmar | modules/nixos/host/orgrimmar/gitea.nix |
| linuxserver/calibre | latest | ironforge | modules/nixos/host/ironforge/calibre.nix |
| linuxserver/calibre-web | latest | ironforge | modules/nixos/host/ironforge/calibre.nix |
| linuxserver/radarr | latest | ironforge | modules/nixos/host/ironforge/nixarr.nix |
| linuxserver/sabnzbd | latest | ironforge | modules/nixos/host/ironforge/nixarr.nix |
| linuxserver/sonarr | latest | ironforge | modules/nixos/host/ironforge/nixarr.nix |
| monstermuffin/mergerfs-cache-mover | latest | (check usage) | apps/fetcher/containers-sha.nix |
| paperless-ngx/paperless-ngx | latest | ironforge | modules/nixos/host/ironforge/paperless.nix |

## quay.io

| Container | Tag | Host | Config Location |
|-----------|-----|------|-----------------|
| minio/minio | latest | orgrimmar | modules/nixos/host/orgrimmar/resume.nix |

## lscr.io

| Container | Tag | Host | Config Location |
|-----------|-----|------|-----------------|
| linuxserver/lazylibrarian | latest | ironforge | modules/nixos/host/ironforge/calibre.nix |

## Host Summary

| Host | Containers |
|------|------------|
| orgrimmar | gitea, gitea-check-service, woodpecker-server, woodpecker-agent, postgres:18, postgres:16-alpine, reactive-resume, minio, browserless/chromium |
| ironforge | jellyfin, calibre, calibre-web, lazylibrarian, radarr, sabnzbd, sonarr, paperless-ngx, paperless-ai, postgres:17, redis, tika, gotenberg, mergerfs-cache-mover |

## Native NixOS Services (non-containerized)

| Service | Host | Config Location |
|---------|------|-----------------|
| nixarr (jellyseerr, prowlarr, etc.) | ironforge | modules/nixos/host/ironforge/nixarr.nix |

## Finding Container Usage

To find which host uses a container:

```bash
# Search by container name
grep -r "container-name" --include="*.nix" apps/ modules/

# Search in containers-sha.nix for the full image reference
grep "container-name" apps/fetcher/containers-sha.nix
```
