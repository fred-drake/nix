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
| paperless-ngx/paperless-ngx | latest | paperless | modules/nixos/host/paperless/paperless.nix |

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
| uptime-kuma | uptime-kuma:latest |

## Finding Container Usage

To find which host uses a container:

```bash
# Search by container name
grep -r "container-name" --include="*.nix" apps/ modules/

# Search in containers-sha.nix for the full image reference
grep "container-name" apps/fetcher/containers-sha.nix
```

## Ironforge Services

| Service | Container | Config Location |
|---------|-----------|-----------------|
| gitea | gitea/gitea | modules/nixos/host/ironforge/gitea.nix |
| woodpecker | woodpecker-server, woodpecker-agent | modules/nixos/host/ironforge/woodpecker.nix |
| paperless | paperless-ngx, postgres, redis | modules/nixos/host/ironforge/paperless.nix |
| calibre | calibre, calibre-web | modules/nixos/host/ironforge/calibre.nix |
| resume | resume containers | modules/nixos/host/ironforge/resume.nix |

## Native NixOS Services (non-containerized)

| Service | Host | Config Location |
|---------|------|-----------------|
| glance | fredpc | modules/nixos/host/fredpc/glance.nix |

## Notes

- Most hosts are Proxmox LXC containers
- ironforge is a Hetzner dedicated server hosting multiple services
- glance runs as a native NixOS service on fredpc (residential IP avoids API blocks)
