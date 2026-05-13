---
name: provision-nixos-server
description: |
  Provision new NixOS hosts for this nix flake project (Hetzner cloud servers
  or Proxmox LXC containers). Guides through host creation, SSH setup, Colmena
  registration (init/full pattern), SOPS infrastructure-key bootstrap, and
  application deployment with nginx proxy, PostgreSQL, and container images.

  Use when: (1) Setting up a new Hetzner server, (2) Setting up a new Proxmox
  LXC NixOS host, (3) Adding a new host to Colmena, (4) Deploying applications
  with nginx SSL proxy and/or PostgreSQL database, (5) Adding new container
  images to the repository.
---

# Provision NixOS Server

## Platform branch (read first)

The high-level workflow is the same across platforms, but the host
config and Colmena triplet differ. Pick the platform up front, then
use the matching reference file from `references/`:

| Platform | Host template | OS config template |
|---|---|---|
| **Hetzner** (cloud / dedicated) | `hetzner-host-template.md` | `hetzner-config-template.md` |
| **Proxmox LXC** | `proxmox-lxc-host-template.md` | `proxmox-lxc-config-template.md` |

App-layer templates (nginx proxy, postgres container, etc.) live in
`app-templates.md` and are platform-agnostic.

Other platforms (WSL, bare-metal LAN) don't have references yet — the
existing hosts of those shapes (anton for WSL, gnomeregan for LAN)
are good starting points to copy.

## Workflow Overview

1. Gather requirements + add soft-secrets entries
2. Create the host (Hetzner console / Proxmox UI / nixos-infect)
3. Verify SSH access from your workstation
4. **Copy infrastructure SSH key onto the host** (required before any deploy that imports a module declaring sops secrets — which is most non-trivial services)
5. Add the host's age key to `.sops.yaml` (only if any sops secrets are encrypted *for this specific host*; shared infra-key secrets don't need this)
6. Write the Colmena host files + register in `colmena/default.nix`
7. Initial deploy (`colmena apply --on <host>-init`)
8. Application layer + full deploy (`colmena apply --on <host>`)

## Step 1: Gather Requirements

Ask the user for:

- **Hostname**: e.g. `ironforge`, `stormwind`
- **Platform**: Hetzner or Proxmox LXC (or other — note as such)
- **Internal IP**: the address this host will own on the tailnet
  (e.g. `10.1.1.5`). Existing range as of writing: headscale=`.2`,
  ironforge=`.3`, orgrimmar=`.4`, stormwind=`.5`. Next free is `.6`.
- **Role**: basic server / app server / monitoring-only / etc.
- **Application**: what will eventually run here

Then verify (or have the user add) `soft-secrets` entries for the new
host in the nix-secrets repo:

- `host.<host>.admin_ip_address` — required by `prometheus-node-exporter`
  when `hasMonitoring = true`
- Any service-specific soft-secrets the host will need

If soft-secrets for this host don't exist yet, the safest path is:

- **Option A**: have the user add them now, commit, and pin via
  `just update-secrets`. Then deploy with `my.hasMonitoring = true` from
  the start.
- **Option B**: set `my.hasMonitoring = false` for the first deploy,
  add soft-secrets afterward, then flip the flag and redeploy.

Option A is cleaner. Option B is fine when the user wants to verify
the box boots before touching the secrets repo.

## Step 2: Create the Host

### Hetzner

Order through the Hetzner console using a NixOS image (or any image
+ `nixos-infect`). Attach a second block device if this will be an
app server — `hetzner-app-server.nix` expects one mounted at
`/var/lib/containers`. After the box boots, format it
(`mkfs.ext4 /dev/sdb`) and capture its UUID with `blkid`; you'll
need it for `configuration.nix`.

Servers in this repo are typically reachable on a private tailnet IP
(`10.1.1.x`) once provisioning is done. For brand-new boxes that only
have a public IP, you may need to do one deploy targeting the public
IP, then switch the colmena `targetHost` to the internal address
after the box joins the tailnet.

### Proxmox LXC

Create the container in the Proxmox UI with a NixOS template image,
allocate CPU/memory/disk, attach to the appropriate VLAN if relevant.

## Step 3: Verify SSH

```bash
ssh root@<server-ip> "hostname; nixos-version"
```

Hetzner cloud images often pre-populate `~/.ssh/authorized_keys` from
the order; if not:

```bash
ssh root@<server-ip> \
  "mkdir -p ~/.ssh && curl -s https://github.com/fred-drake.keys > ~/.ssh/authorized_keys"
```

## Step 4: Copy Infrastructure SSH Key (do this BEFORE Step 7)

**Critical**: any deploy whose host config imports a module that declares
`sops.secrets.*` will fail at activation time without this key. That
includes `hetzner-app-server.nix` (cloudflare-api-key for ACME), any
service module wiring secrets, and the prometheus-node-exporter feature
(transitively if it pulls soft-secrets — not strictly a sops secret,
but check before you assume).

```bash
scp ~/.ssh/id_infrastructure root@<server-ip>:/root/id_infrastructure
ssh root@<server-ip> "chmod 600 /root/id_infrastructure"
```

The matching age public key (for `.sops.yaml`, if the host needs
per-host secrets) is:

```
age1rnarwmx5yqfhr3hxvnnw2rxg3xytjea7dhtg00h72t26dn6csdxqvsryg5
```

## Step 5: Add Age Key to .sops.yaml (only if needed)

This step is only required when the user is creating secrets
*specifically encrypted for this new host's age key*. The shared
infrastructure key is already in `.sops.yaml`, so for most hosts
(which use that shared key) Step 4 is sufficient.

If you do need to add a per-host key: edit `.sops.yaml` in
nix-secrets, then run `sops updatekeys` on the affected secret files.

## Step 6: Write Colmena Host Files

Use the templates from `references/`:

- For Hetzner: `hetzner-host-template.md` + `hetzner-config-template.md`
- For Proxmox LXC: `proxmox-lxc-host-template.md` + `proxmox-lxc-config-template.md`

Create these files:

1. `mkdir -p modules/nixos/host/<host>`
2. Write `modules/nixos/host/<host>/configuration.nix` from the config
   template
3. Write `colmena/hosts/<host>.nix` from the host template
4. Edit `colmena/default.nix` to register the host (4 spots: function
   arg/import, `inherit` line, init line, full line — see template)

Stage and sanity-check evaluation:

```bash
git add colmena/hosts/<host>.nix modules/nixos/host/<host>/ colmena/default.nix
nix flake check --no-build 2>&1 | tail -20
colmena build --on <host>-init --impure
```

A successful `colmena build` proves the host config evaluates and the
target box has nix-store reachable.

## Step 7: Deploy Init

```bash
colmena apply --on <host>-init --impure
```

For Hetzner app servers, expect the activation step to switch SSH
from port 22 to 2222. Colmena's connection is established BEFORE
activation, so the deploy completes normally; the next deploy must
use `--on <host>` (which inherits port 2222 from `_<host>`).

If you misjudged the port and Colmena hangs trying to connect, the
fix is usually:

- For Hetzner: ensure `<host>-init.deployment.targetPort = mkForce 22`
- For LXC: ensure `targetUser = "root"` for the very first deploy,
  before the `default` user exists

Verify post-deploy:

```bash
ssh -p <port> root@<server-ip> 'hostname; systemctl is-system-running; systemctl --failed'
```

## Step 8: Application Layer + Full Deploy

### Add container images

If the application uses any not-yet-pinned container images:

1. Edit `apps/fetcher/containers.toml` with each image
2. `just update-container-digests` to refresh `containers-sha.nix`
3. Stage both files

### Write the service module

Create `modules/services/<service>.nix` following the patterns in
`app-templates.md`:

- Nginx proxy via `lib/mk-nginx-proxy.nix` (Let's Encrypt + DNS-01)
- Podman network via `lib/mk-podman-network.nix` (if multiple
  containers need to talk to each other by name)
- `sops.secrets.*` declarations colocated in the module
- `systemd.tmpfiles.rules` for data directories (mind the postgres /
  clickhouse / other uid:gid requirements)
- `virtualisation.oci-containers.containers.*`

### Add the service to the host's full config

In `colmena/hosts/<host>.nix`, add to the `"<host>"` (not `_<host>`)
imports:

```nix
../../modules/services/<service>.nix
```

### Deploy

```bash
just update-secrets
git add <new-files>
colmena apply --on <host> --impure
```

Verify each container started and end-to-end connectivity works:

```bash
ssh -p <port> root@<server-ip> \
  'podman ps; systemctl --failed; curl -sI -o /dev/null -w "%{http_code}\n" http://127.0.0.1:<proxy-port>/'
```

For external HTTPS verification (testing the ACME cert + nginx):

```bash
curl -sI --resolve <host>.<domain>:443:<server-ip> https://<host>.<domain>/
```

The `--resolve` flag is useful when running from a machine that
doesn't have internal-DNS resolution for the domain.

## Common Issues

### "SSH connection refused" mid-deploy

You probably set `_<host>.targetPort = 2222` and forgot the
`mkForce 22` override on `<host>-init`. See
`hetzner-host-template.md` for the transition explanation.

### "could not decrypt sops file" at activation

Either:

- `/root/id_infrastructure` is missing on the box (see Step 4), OR
- This host's age key isn't in `.sops.yaml` AND the secret was
  encrypted only for per-host keys (see Step 5)

The activation log will mention `sops-install-secrets` — verify
fingerprints match what you expect.

### "lookup <hostname>: no such host" from a container

The host is trying to resolve an internal hostname that isn't in
public DNS. Add it to the host's `networking.extraHosts` (see the
example block in `hetzner-host-template.md`).

### Nginx duplicate directive

Don't add `proxy_http_version` to `extraConfig` when using
`proxyWebsockets = true` — the latter sets it implicitly, and
duplicate `proxy_http_version` is a nginx error.

### PostgreSQL 18 fails to init

Mount at `/var/lib/postgresql`, NOT `/var/lib/postgresql/data`.
Postgres 18 changed the layout. Postgres 17 still uses
`/var/lib/postgresql/data`.

### Container can't reach postgres on host

Use `0.0.0.0:5432:5432` for the port binding (not `127.0.0.1`), and
`host.containers.internal` in the container's connection string.
Alternatively, put the containers on the same podman network and
reference postgres by container name.

### Image pull fails: "no such host" for an internal registry

The host doesn't resolve your gitea hostname. Either:

- Add the hostname to `networking.extraHosts`, OR
- Configure the host to use an internal DNS resolver

### Image pull fails: 401 from gitea registry

The container package in gitea is private. Either:

- Mark the package public in gitea (Package settings → visibility), OR
- Configure `podman` auth on the host via
  `/etc/containers/auth.json` (typically sops-managed)
