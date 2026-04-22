---
name: woodpecker-upgrade
description: Upgrade Woodpecker CI across the server, Linux agent, and macOS agent while keeping the gRPC protocol version in lockstep. Use when the user wants to upgrade Woodpecker, bump the agent or server, or investigate a "GRPC version mismatch" error.
---

# Woodpecker Upgrade

Woodpecker's server and agents communicate over a gRPC protocol whose
version is tied to the release. Mismatches are fatal — the agent logs
`server version X reports grpc version N but we only understand M` and
enters a crash loop. This setup has **three independent version
anchors** that must be upgraded together.

## Where Woodpecker Versions Live

| Anchor | File | What it pins |
|---|---|---|
| Server image | `apps/fetcher/containers.toml` → `woodpeckerci/woodpecker-server` | Runs on orgrimmar as `podman-woodpecker-server.service` |
| Linux agent image | `apps/fetcher/containers.toml` → `woodpeckerci/woodpecker-agent` | Runs on orgrimmar as `podman-woodpecker-agent.service`, docker backend |
| macOS agent binary | `inputs.nixpkgs-woodpecker-agent` in `flake.nix` | Built by nix, runs on mac-studio as a user launchd agent, local backend |

The server image and Linux agent image are pinned to an **exact tag**
(e.g. `v3.13.0`, not `v3.13` — the floating tag is unreliable, see
Gotchas). The macOS agent is pinned via a **dedicated nixpkgs input**
separate from the main `nixpkgs` input, so `nix flake update` cannot
bump it accidentally.

## Network Topology Reminder

- Server HTTP (webhooks + UI): `https://woodpecker.internal.freddrake.com/api/hook` → nginx → container port 8000
- Server gRPC (agents): `10.1.1.4:9010` (tailnet-facing) → container port 9000
  - Host port is **9010**, not 9000, because prometheus node_exporter owns `10.1.1.4:9000`
- Local agent on orgrimmar: connects via the internal podman network
- Mac agent: connects to `10.1.1.4:9010` over the tailnet, plain gRPC (no TLS)

## Upgrade Procedure

### Step 1: Pick the target version

Always upgrade to an **exact release** (e.g. `v3.13.1`, `v3.14.0`),
never a rolling tag. Check:
- Current nixpkgs `woodpecker-agent` version (see below)
- Available tags at https://hub.docker.com/r/woodpeckerci/woodpecker-server/tags
- Release notes for breaking changes

To find a nixpkgs rev that has a specific Woodpecker version:
```bash
# Check what the main nixpkgs currently has
nix eval --impure --raw --expr 'with import <nixpkgs> {}; woodpecker-agent.version'

# Or check a specific rev
nix eval --impure --raw --expr '(import (builtins.fetchTarball "https://github.com/nixos/nixpkgs/archive/<REV>.tar.gz") {}).woodpecker-agent.version'
```

When nixpkgs master has the target version, grab its rev from
https://github.com/nixos/nixpkgs/commits/nixos-unstable or via the
package's PR.

### Step 2: Update the three anchors

All three files must change in the same commit. Leaving any anchor
behind will kill one of the agents.

**2a. Server + Linux agent images (`apps/fetcher/containers.toml`):**

```toml
[[containers]]
repository = "docker.io"
name = "woodpeckerci/woodpecker-server"
tag = "v3.13.0"         # ← bump this
architectures = ["linux/amd64"]
[[containers]]
repository = "docker.io"
name = "woodpeckerci/woodpecker-agent"
tag = "v3.13.0"         # ← bump this to same version
architectures = ["linux/amd64"]
```

Then regenerate digests:
```bash
just update-container-digests
```

**2b. Key references in `modules/services/woodpecker-ci.nix`:**

```nix
image = containers-sha."docker.io"."woodpeckerci/woodpecker-server"."v3.13.0"."linux/amd64";
image = containers-sha."docker.io"."woodpeckerci/woodpecker-agent"."v3.13.0"."linux/amd64";
```

The attr key must match the tag from `containers.toml` exactly.

**2c. macOS agent rev (`flake.nix`):**

```nix
nixpkgs-woodpecker-agent.url = "github:nixos/nixpkgs/<NEW_REV>";
```

Then refresh the lock:
```bash
nix flake lock --update-input nixpkgs-woodpecker-agent
```

### Step 3: Verify versions align before deploying

```bash
# Confirm mac agent binary version in the evaluated darwin config
nix eval --no-warn-dirty --impure --raw --expr \
  'let f = builtins.getFlake (toString ./.); args = f.darwinConfigurations.mac-studio.config.home-manager.users.fdrake.launchd.agents.woodpecker-agent.config.ProgramArguments; in builtins.elemAt args 2' \
  | grep -oE 'woodpecker-agent-[0-9.]+'
```

Confirm this matches the image tag in `containers.toml`.

### Step 4: Deploy orgrimmar first

The mac agent is already in a retry loop. Bringing the server up first
means the agent reconnects immediately; bringing the agent up first
causes extra error logs until the server follows.

```bash
just colmena orgrimmar
```

Watch the woodpecker-server container come up:
```bash
ssh -p 2222 root@10.1.1.4 'systemctl status podman-woodpecker-server --no-pager -n 5'
ssh -p 2222 root@10.1.1.4 'curl -s localhost:8000/version'
```

### Step 5: Deploy mac-studio

```bash
just switch
```

Then verify the agent connected:
```bash
launchctl list | grep woodpecker-agent
tail -20 ~/.local/state/woodpecker-agent/agent.err
```

A healthy agent shows `starting Woodpecker agent with version 'X.Y.Z'
and backend 'local' using platform 'darwin/arm64'` and **no** gRPC
mismatch errors. Then check the Woodpecker UI — the `mac-studio` agent
row should flip to online with a recent "Last Contact".

## Rollback

If a new version breaks something:

1. `git revert` the upgrade commit (all three anchors revert together)
2. `just colmena orgrimmar` (server rolls back; old digest is still in nix store)
3. `just switch` on mac-studio

No special rollback procedure for the agents — they just reconnect to
whatever version the server is running, and a version match is a
version match.

## Gotchas

### Floating tags lie

The `v3` and `v3.13` tags on Docker Hub are **not reliable** as version
pins:
- `v3` has drifted onto RC builds (`3.14.0-rc.0`) while we expected stable
- `v3.13` has a stable server image but a dev-build agent image (`next-*`)

Always use the exact patch tag (`v3.13.0`, not `v3.13`).

### Port 9000 on orgrimmar is taken

Do **not** try to publish the gRPC container port to host port 9000 —
prometheus node_exporter already owns `10.1.1.4:9000`. We use 9010
instead. If you see `bind: address already in use` on deploy, this is
why.

### The nix-secrets flake is separate

Woodpecker auth uses two different tokens:
- `WOODPECKER_AGENT_SECRET` — global server secret, in nix-secrets
  `secrets/host/woodpecker/woodpecker-agent-env`
- Per-agent tokens — minted by the server UI, stored in the server's
  postgres DB. The mac-studio token is additionally mirrored into
  nix-secrets `secrets/host/mac-studio/woodpecker.sops.yaml` key
  `agent-token`.

Upgrading the server does **not** invalidate either. If you rebuild
the postgres volume, all per-agent tokens are lost and must be
re-minted.

### Do not accept rolling nixpkgs for the agent

The mac agent must use the dedicated `nixpkgs-woodpecker-agent` input,
**not** the main `nixpkgs` input, so `just update` (which runs
`nix flake update` and bumps all inputs) can't silently skew it away
from the server version. The overlay in `overlays/default.nix`
enforces this by redefining `pkgs.woodpecker-agent` from the pinned
input — feature modules can continue to reference `pkgs.woodpecker-agent`
as usual.

## References

- Agent config: `modules/home-manager/features/woodpecker-agent.nix`
- Server config: `modules/services/woodpecker-ci.nix`
- Pinning overlay: `overlays/default.nix` (the `woodpecker-agent` line)
- Capability flag: `my.hasWoodpeckerAgent` in `lib/my-options-module.nix`
