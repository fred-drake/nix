---
name: infrastructure
description: |
  Manage NixOS infrastructure for this nix flake project. Deploy configurations with Colmena, troubleshoot services, and maintain servers.

  Use when: (1) Deploying NixOS configurations with colmena, (2) Troubleshooting server issues via SSH, (3) Checking service status across hosts, (4) Any infrastructure maintenance task.

  IMPORTANT architecture notes:
  - Hetzner servers are remote VPS/dedicated hosts, deployed as root.
  - anton is a WSL NixOS host on a Windows laptop, deployed as the nixos user via sudo.
  - gnomeregan is a home LAN NixOS box (Wi-Fi). Unusual: tracks nixpkgs-unstable, runs the full workstation home-manager stack, uses its own SSH host key as sops identity. See references/gnomeregan.md before changing its config or rebuilding it.
  - Full-fleet deployments run through the `colmena-deploy` workflow (one host at a time, with web health verification after every switch) — not ad-hoc colmena calls.
---

# Infrastructure Management

## Quick Reference

### Full-fleet deployment: the `colmena-deploy` workflow

**Any "deploy everything" request (including `/update-all-remote`) runs through
the `colmena-deploy` workflow**, defined in
`/Users/fdrake/nix/.claude/workflows/colmena-deploy.js`. It auto-registers as
the `colmena-deploy` skill (slash command `/colmena-deploy`) — invoke it with
the Skill tool, or with the Workflow tool in sessions that expose one:

```
Skill({ skill: "colmena-deploy" })
# or, when the Workflow tool is available:
Workflow({ name: "colmena-deploy" })
Workflow({ scriptPath: "/Users/fdrake/nix/.claude/workflows/colmena-deploy.js" })
```

The workflow encodes the deployment contract; do not re-implement it inline:

- Hosts are applied **one machine at a time**, in canonical order:
  **stormwind → ironforge → orgrimmar → anton → gnomeregan → headscale
  ("gateway")**.
- After each successful switch, **every web endpoint in the fleet** (the
  tables in `references/host-mapping.md`) is probed and must return its
  expected status (default: 2xx after redirects).
- If a host **fails to switch**, a fix agent diagnoses and repairs the root
  cause, then the sequence **restarts from stormwind** (max 3 full restarts).
- If the switch succeeds but **any site is unhealthy**, heal agents fix it
  (max 3 rounds); the sequence does not advance until the whole fleet is
  healthy.
- After pre-flight, a **workaround audit** runs the "Workaround Hygiene"
  procedure (below): every `WORKAROUND(`-tagged override under `overlays/` is
  tested as a stock build at the pinned `nixpkgs-unstable` rev on a reachable
  unstable host, and overrides upstream has fixed are retired before the
  unstable hosts rebuild. Advisory — it never blocks the deploy. Markers
  outside `overlays/` (e.g. container digest holds) are reported, not modified.
- A pre-flight agent blocks the run on untracked `*.nix` files (invisible to
  the git+file flake). **Unreachable machines never block**: whether detected
  at pre-flight or at deploy time, a down host is skipped, its endpoints are
  excluded from the health checks, and it is reported under `skipped` in the
  result (status `partial`). A sleeping laptop must not hold up the fleet —
  deploy it later with an ad-hoc single-host run once it's back.

When the workflow aborts, it returns a timeline of what switched, what failed,
and what was fixed — surface that to the user rather than silently retrying.

### Ad-hoc single-host deploys: the `colmena-deployer` subagent

For one-off work on a single host (build checks, a quick iteration loop on one
machine), run the colmena call through the **colmena-deployer** subagent — one
subagent per colmena call. A deploy emits thousands of lines of flake-lock diff
and per-host build output; running it in the main context buries everything
else. The subagent runs the command, watches it to completion, and returns just
a pass/fail summary (plus the root-cause lines on failure). Do not call
`colmena` directly from the main context.

Spawn it with the Task tool, for example:

> Use the **colmena-deployer** subagent: "Run `colmena apply --on
> gnomeregan --impure` from `/Users/fdrake/nix`. Return the host's
> activation result. Note: anton can exit 4 on a spurious user dbus-broker
> reload timeout even when the switch succeeded — verify its current generation
> against the built path rather than trusting the exit code."

The underlying commands the subagent runs:

```bash
colmena apply --on <hostname> --impure        # single host
colmena build --on <hostname> --impure        # build only, no deploy
```

After an ad-hoc apply, verify the host's web endpoints from the tables in
`references/host-mapping.md` before declaring success.

## Server Inventory

### Hetzner Servers (Colmena-managed, root user)

| Host | Type | Services |
|------|------|----------|
| headscale (aka "gateway") | Hetzner VPS | Headscale VPN, Tailscale client, subnet router for 10.1.0.0/16 (all tailnet access to the other Hetzner boxes rides through it) |
| ironforge | Hetzner dedicated | media stack, all podman: jellyfin, seerr (+ jellyseerr redirect), sonarr, radarr, lidarr, prowlarr, sabnzbd, bazarr |
| orgrimmar | Hetzner dedicated | gitea (+ gitea-status), woodpecker, paperless (+ paperless-ai), calibre-web, resume, filebrowser |
| stormwind | Hetzner dedicated | traceway (observability stack), gatus (internal uptime dashboard) |

### LAN NixOS Hosts (Colmena-managed, fdrake user with sudo)

| Host | Type | Services |
|------|------|----------|
| gnomeregan | Home LAN x86_64 box (Wi-Fi) | Borg backups, glance dashboard, personal automation jobs (process-daily, archive-email) under fdrake's systemd-user timers. Runs full workstation home-manager stack. See `references/gnomeregan.md`. |

### WSL Hosts (Colmena-managed, nixos user with sudo)

| Host | Type | Purpose |
|------|------|---------|
| anton | WSL NixOS on Windows laptop | Gaming and AI processing |

## Troubleshooting Workflows

### Many `*.internal.freddrake.com` names unreachable at once

If "service X is down" but *other* internal sites are **also** unreachable, the
problem is almost never that service — it's the internal DNS resolver
(hearthstone, `100.64.0.13`) having dropped off the headscale tailnet. The
servers stay fine; names just stop resolving (the whole `internal.freddrake.com`
zone is split-DNS'd to `100.64.0.13`). This has happened (2026-06-23: an OpenWrt
package upgrade wiped hearthstone's tailscaled state). See
`references/hearthstone-dns.md` for the fast diagnosis and the re-register
recovery procedure. Quick first checks:

```bash
tailscale status | grep -i hearthstone   # offline / last seen 15h ago?
tailscale status                         # if LOCAL tailscale is down, the fleet only LOOKS dead
```

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

### Deploy All Hosts

Use the `colmena-deploy` workflow (see "Full-fleet deployment" above). Do NOT
hand a comma-separated all-hosts `colmena apply` to a subagent — that deploys
in parallel with no health gating between machines.

### Update Secrets Before Deploy
```bash
just update-secrets
```
Run this first when secrets changed, then deploy (workflow or single-host).

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

The `colmena-deploy` workflow runs this audit automatically (its "Workaround
Audit" phase, between pre-flight and the first apply). Run it manually before
ad-hoc single-host unstable deploys, macbook rebuilds, or when bumping
`nixpkgs-unstable` outside a fleet deploy:

```bash
grep -rn 'WORKAROUND(' overlays/
```

For each marker, test whether the workaround is still needed by building the
**stock** package (override absent) from the pinned unstable rev on an
x86_64-linux unstable host. Do *not* just rebuild the whole host: a host build
exercises the *overridden* package (standalone overlays like `highlight.nix`
are applied via `nodeNixpkgs` in `colmena/default.nix`), so it cannot tell you
whether the **stock** package is fixed upstream. Building the stock package
directly is the accurate check.

```bash
REV=$(jq -r '.nodes["nixpkgs-unstable"].locked.rev' flake.lock)   # the pinned rev
# on an unstable x86_64-linux host (anton or gnomeregan):
ssh anton "NIXPKGS_ALLOW_UNFREE=1 nix build --no-link -L --impure \
  github:nixos/nixpkgs/$REV#<pkg>"   # e.g. tailscale, python313Packages.uvloop
```

- **Builds or substitutes clean** → upstream is green at this rev → delete the
  override and its marker. A substitute from `cache.nixos.org` is itself a
  strong signal: Hydra built that stock derivation with its tests enabled.
- **Fails** → keep it; leave the marker. (e.g. `highlight`'s patch still
  double-applies → not fixed, never cached.)

For **flaky-test / timeout** workarounds (a test that flakes or times out
rather than failing deterministically), one green is necessary but not
sufficient — yet removal is still low-risk: with the override gone, normal
builds just substitute Hydra's green binary and only re-run the test on a cache
miss, like any other package. Re-adding the one-line override later is trivial.

After deciding to remove one, confirm the consuming config still resolves with
it gone — e.g. `nix build --dry-run \
.#darwinConfigurations.macbook-pro.config.system.build.toplevel`: the package
should appear under **"will be fetched"** (substituted), not **"will be
built"** (which would run its tests locally).

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
- `references/hearthstone-dns.md` — The gateway/OpenWrt box (`ssh root@192.168.8.1`) that hosts the `internal.freddrake.com` DNS resolver on headscale (`100.64.0.13`). Read first when *many* internal names fail at once; covers diagnosis and the headscale re-register recovery.
