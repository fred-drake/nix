# Buzz pairing relay implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Route Buzz mobile pairing requests at `/pair` to a dedicated pairing-relay sidecar on orgrimmar.

**Architecture:** Retain the primary Buzz relay at loopback port 3003. Start `buzz-pair-relay` from the same pinned image on a second loopback port and route only the nginx exact `/pair` WebSocket location to it. The primary relay advertises the externally reachable `wss://buzz.internal.freddrake.com/pair` endpoint.

**Tech Stack:** NixOS, `virtualisation.oci-containers` with Podman, systemd, nginx.

## Global constraints

- Change only Buzz service configuration in `modules/services/buzz.nix`.
- Reuse the existing pinned `ghcr.io/block/buzz:main` image.
- Pairing is private-network-only and must retain the existing nginx ACL.
- Deploy only `orgrimmar`; do not run `just switch`.

---

### Task 1: Add the pairing relay and exact proxy route

**Files:**
- Modify: `modules/services/buzz.nix`

**Interfaces:**
- Consumes: `relayImage`, `buzzEnv`, and `mkNginxProxy` already defined by the Buzz module.
- Produces: `podman-buzz-pair-relay.service`, loopback pairing listener, and nginx `location = /pair` route.

- [ ] **Step 1: Add a structural evaluation check before the implementation**

Run:
```bash
nix eval --raw .#colmenaHive.nodes.orgrimmar.config.virtualisation.oci-containers.containers.buzz-pair-relay.image
```
Expected: failure because `buzz-pair-relay` is not yet defined.

- [ ] **Step 2: Add the pair relay port and nginx exact route**

In the `let` bindings, add a separate loopback port:
```nix
pairRelayPort = "3004";
```

Extend the `mkNginxProxy` call with a `location = /pair` block that proxies to `http://127.0.0.1:${pairRelayPort}`, uses HTTP/1.1, and forwards the existing upgrade/connection headers. Include the same `allow 10.1.0.0/16`, `allow 100.64.0.0/10`, and `deny all` policy in this exact location.

- [ ] **Step 3: Add the `buzz-pair-relay` container**

Add this sibling container under `virtualisation.oci-containers.containers`:
```nix
buzz-pair-relay = {
  image = relayImage;
  autoStart = true;
  extraOptions = ["--network=buzz-net" "--entrypoint=/bin/sh"];
  cmd = ["-ec" "exec /usr/local/bin/buzz-pair-relay"];
  ports = ["127.0.0.1:${pairRelayPort}:5000"];
  environment = {
    BUZZ_PAIR_RELAY_BIND_ADDR = "0.0.0.0:5000";
    RELAY_URL = "wss://buzz.internal.freddrake.com";
  };
  environmentFiles = [buzzEnv];
};
```

Add `BUZZ_PAIRING_RELAY_URL = "wss://buzz.internal.freddrake.com/pair";` to the main relay’s existing `environment` block.

Add `podman-buzz-pair-relay.service` to the `mkPodmanNetwork "buzz"` dependency list.

- [ ] **Step 4: Verify the Nix configuration evaluates**

Run:
```bash
nix eval --raw .#colmenaHive.nodes.orgrimmar.config.virtualisation.oci-containers.containers.buzz-pair-relay.image
nix eval --json .#colmenaHive.nodes.orgrimmar.config.services.nginx.virtualHosts.buzz.internal.freddrake.com.locations
```
Expected: the pair image equals the existing Buzz relay image; nginx output has exact `/pair` forwarding to port 3004.

- [ ] **Step 5: Format and commit the focused configuration change**

Run:
```bash
alejandra modules/services/buzz.nix
git add modules/services/buzz.nix
git commit -m "feat(buzz): add pairing relay"
```
Expected: one focused commit changing only the Buzz service module.

### Task 2: Deploy and verify the pairing route

**Files:**
- Modify: none

**Interfaces:**
- Consumes: the committed Buzz pairing relay configuration from Task 1.
- Produces: a running pair relay and a reachable private `/pair` WebSocket endpoint on orgrimmar.

- [ ] **Step 1: Deploy only orgrimmar**

Use the single-host Colmena deployment process:
```bash
colmena apply --on orgrimmar --impure
```
Expected: activation completes for orgrimmar only.

- [ ] **Step 2: Verify both container services**

Run:
```bash
ssh root@orgrimmar 'systemctl is-active podman-buzz-relay.service podman-buzz-pair-relay.service'
```
Expected: both lines are `active`.

- [ ] **Step 3: Verify `/pair` reaches the pairing endpoint**

Run a WebSocket upgrade probe from a private-network client:
```bash
curl -sk --http1.1 --max-time 5 -o /dev/null -w '%{http_code}\n' \
  -H 'Connection: Upgrade' -H 'Upgrade: websocket' \
  -H 'Sec-WebSocket-Version: 13' -H 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==' \
  https://buzz.internal.freddrake.com/pair
```
Expected: successful WebSocket upgrade is `101`, not the previous `404`; curl may exit `28` after deliberately timing out the open connection.

- [ ] **Step 4: Verify no orgrimmar endpoint regressed**

Probe every orgrimmar URL listed in `.claude/skills/infrastructure/references/host-mapping.md`; each must return its documented 2xx status after redirects.

- [ ] **Step 5: Request end-to-end confirmation**

Ask the user to retry mobile pairing. Treat their successful pairing as the final end-to-end validation; do not make additional changes if it fails—collect fresh client/server evidence first.
