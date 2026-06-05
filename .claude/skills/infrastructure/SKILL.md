---
name: infrastructure
description: |
  Manage NixOS infrastructure for this nix flake project. Deploy configurations with Colmena, troubleshoot services, and maintain servers.

  Use when: (1) Deploying NixOS configurations with colmena, (2) Troubleshooting server issues via SSH, (3) Checking service status across hosts, (4) Any infrastructure maintenance task.

  IMPORTANT architecture notes:
  - Hetzner servers are remote VPS/dedicated hosts, deployed as root.
  - anton is a WSL NixOS host on a Windows laptop, deployed as the nixos user via sudo.
  - gnomeregan is a home LAN NixOS box (Wi-Fi). Unusual: tracks nixpkgs-unstable, runs the full workstation home-manager stack, uses its own SSH host key as sops identity. See references/gnomeregan.md before changing its config or rebuilding it.
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

## Server Inventory

### Hetzner Servers (Colmena-managed, root user)

| Host | Type | Services |
|------|------|----------|
| headscale | Hetzner VPS | Headscale VPN, Tailscale client |
| ironforge | Hetzner dedicated | nixarr (jellyfin, jellyseerr, sonarr, radarr, lidarr, prowlarr, sabnzbd, bazarr) |
| orgrimmar | Hetzner dedicated | gitea, woodpecker, paperless, calibre, resume |
| stormwind | Hetzner dedicated | traceway (observability stack) |

### LAN NixOS Hosts (Colmena-managed, fdrake user with sudo)

| Host | Type | Services |
|------|------|----------|
| gnomeregan | Home LAN x86_64 box (Wi-Fi) | Borg backups, glance dashboard, personal automation jobs (process-daily, archive-email) under fdrake's systemd-user timers. Runs full workstation home-manager stack. See `references/gnomeregan.md`. |

### WSL Hosts (Colmena-managed, nixos user with sudo)

| Host | Type | Purpose |
|------|------|---------|
| anton | WSL NixOS on Windows laptop | Gaming and AI processing |

## Troubleshooting Workflows

### Service Not Working

1. Check service status:
   ```bash
   ssh <hostname> "systemctl status <service>"
   ```
2. Check logs:
   ```bash
   ssh <hostname> "journalctl -u <service> -n 100"
   ```
3. Restart service:
   ```bash
   ssh <hostname> "systemctl restart <service>"
   ```

Note: For Hetzner servers, SSH as root. For anton, SSH as nixos and use sudo.

### Podman/Container Issues

Check socket status:
```bash
ssh <hostname> "systemctl status podman.socket"
```

List running containers:
```bash
ssh <hostname> "podman ps -a"
```

### SSH Connection Issues

If colmena fails with SSH errors:
1. Verify the host is reachable: `ping <hostname>`
2. Check if SSH is listening: `ssh <hostname> "ss -tlnp | grep 22"`
3. For Hetzner servers, check via Hetzner console if needed

## Common Colmena Patterns

### Deploy All Hetzner Hosts
```bash
colmena apply --on headscale,ironforge,orgrimmar,stormwind --impure
```

### Deploy All Hosts
```bash
colmena apply --on headscale,ironforge,orgrimmar,stormwind,gnomeregan,anton --impure
```

### Update Secrets Before Deploy
```bash
just update-secrets
colmena apply --on <hostname> --impure
```

## Workaround Hygiene (unstable hosts)

The unstable hosts (anton, gnomeregan, and the macbook) periodically hit a
package that is broken in `nixpkgs-unstable` — a redundant patch, a flaky test,
a build failure. The fix is a per-package override in `overlays/`. These are
**temporary**: once upstream fixes the package, the override becomes dead
weight and can subtly mask later regressions.

Each temporary override carries a greppable marker comment:

```
# WORKAROUND(<pkg>): <reason>; remove when <condition>.
```

**Before an unstable deploy (or when bumping `nixpkgs-unstable`), audit them:**

```bash
grep -rn 'WORKAROUND(' overlays/
```

For each marker:

1. Comment out (or remove) that override in the overlay.
2. Rebuild the affected unstable host: `colmena build --on gnomeregan --impure`
   (or `anton`). Build both if unsure which consumes the package.
3. **Builds clean** → upstream fixed it → delete the override and its marker.
4. **Still fails** → keep it; leave the marker in place.

Then restore any overrides you only commented out for testing.

Notes:
- Only override packages tagged `WORKAROUND(` are candidates for removal.
  Other entries in `overlays/default.nix` are **intentional pins**, not
  staleness-driven — leave them alone:
  - `glance` (built from main on purpose),
  - `woodpecker-agent` (locked to the server image; governed by the
    woodpecker-upgrade skill),
  - `spotify` darwin src override.
- When you add a new workaround, give it a `WORKAROUND(<pkg>)` marker with a
  concrete removal condition so the next audit can retire it.
- A new overlay file must be `git add`-ed before `colmena ... --impure` — a
  `git+file` flake only sees tracked files, so an untracked overlay fails with
  `path '.../overlays/<name>.nix' does not exist`.

## File Locations

| Purpose | Path |
|---------|------|
| Colmena host configs | `colmena/hosts/<hostname>.nix` |
| Hetzner common modules | `colmena/hetzner-common/` |
| WSL common modules | `colmena/wsl-common/` |
| NixOS host configs | `modules/nixos/host/<hostname>/configuration.nix` |
| Application configs | `apps/<appname>.nix` |
| Service modules (incl. secrets) | `modules/services/<service>.nix` |
| Container image SHAs | `apps/fetcher/containers-sha.nix` |
| Container definitions | `apps/fetcher/containers.toml` |

## Related Skills

- **provision-nixos-server**: Create new Hetzner servers from scratch

## References

- `references/host-mapping.md` — Inventory of every managed host (SSH user, port, role).
- `references/gnomeregan.md` — Gnomeregan-specific setup, sops identity model, and disaster-recovery procedure. Read first before changing its config or rebuilding it.
