# Hermes-to-Buzz Container Access Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Permit Hermes's rootful Podman bridge traffic to reach the main private Buzz endpoint without opening the pairing endpoint or weakening relay authentication.

**Architecture:** Add the Orgrimmar rootful Podman subnet to the main Buzz nginx vhost only. Deploy only Orgrimmar, then test positive main-endpoint access and negative pairing/protected-endpoint behavior from Hermes.

**Tech Stack:** NixOS, nginx, Podman, Colmena, Buzz relay

## Global Constraints

- Allow `10.88.0.0/16` only on the main Buzz vhost.
- Do not add `10.88.0.0/16` to the exact `/pair` location.
- Preserve `deny all`, relay membership enforcement, and NIP authentication.
- Do not introduce API tokens, NIP-OA fallback, NAT rules, or public exposure.
- Deploy only Orgrimmar and never run `just switch`.
- Never print secrets, tokens, private identities, or full environments.

---

### Task 1: Authorize and validate the Hermes Podman subnet

**Files:**
- Modify: `modules/services/buzz.nix`

**Interfaces:**
- Consumes: Hermes source address within rootful Podman subnet `10.88.0.0/16`.
- Produces: main Buzz HTTPS/WebSocket access for that subnet while `/pair` remains denied.

- [ ] **Step 1: Record the failing access-control behavior**

From the running Hermes container, record HTTP 403 from the main health endpoint and nginx's `access forbidden by rule` evidence without printing credentials.

- [ ] **Step 2: Add the minimal nginx allow rule**

Add this line to the main `extraConfig`, before `deny all`:

```nix
allow 10.88.0.0/16;
```

Do not change `extraLocations."= /pair"`.

- [ ] **Step 3: Verify evaluation and formatting**

Run:

```bash
alejandra modules/services/buzz.nix
git diff --check
colmena eval --impure -E '{nodes, ...}: nodes.orgrimmar.config.services.nginx.virtualHosts."buzz.internal.freddrake.com"'
```

Expected: the main location contains all three allowed ranges and `/pair` contains only the original two.

- [ ] **Step 4: Commit**

```bash
git add modules/services/buzz.nix
git commit -m "fix(buzz): allow Hermes container traffic"
```

- [ ] **Step 5: Deploy only Orgrimmar**

Use a separate bounded `generalist` child to run exactly one:

```bash
timeout 900 colmena apply --on orgrimmar --impure
```

Require at least 3 GB root free space and 3 million free inodes first.

- [ ] **Step 6: Validate positive and negative boundaries**

From Hermes, verify:

- main `/health` no longer returns nginx 403;
- exact `/pair` still returns nginx 403;
- an unauthenticated protected relay request remains rejected by the relay;
- nginx, Buzz relay, Hermes 0.20/schema 33, dashboard, migration-marker absence, and vault timer remain healthy;
- focused Orgrimmar endpoints remain healthy.

- [ ] **Step 7: Update graph**

```bash
graphify update .
```
