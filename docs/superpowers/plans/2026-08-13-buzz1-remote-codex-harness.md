# Buzz1 Remote Codex Harness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow Buzz Desktop agents to run continuously on gnomeregan as owner-only, Codex-backed `buzz-acp` systemd services under the unprivileged `buzz1` account.

**Architecture:** A NixOS module owns the `buzz1` account, immutable binaries, protected runtime layout, unit template, and a root-owned constrained deploy helper. A locally installed `buzz-backend-gnomeregan` provider implements Buzz’s `info`/`deploy` protocol and uses SSH to invoke that helper, creating one systemd instance per Buzz identity. Each agent has a distinct harness and Nostr key, while all instances intentionally share `/home/buzz1` and its Codex login.

**Tech Stack:** NixOS, systemd, Bash, SSH, Buzz `buzz-acp`, `@agentclientprotocol/codex-acp`, OpenAI Codex CLI, Buzz remote-provider JSON protocol.

## Global Constraints

- `buzz1` is a non-sudo system account with home `/home/buzz1`; it must not access `/home/fdrake`.
- Each Buzz Desktop agent has one supervised `buzz-acp` service and its own Buzz/Nostr identity; do not multiplex UI agents in one harness.
- Services run as `buzz1`, work only in `/home/buzz1`, and share that account’s Codex authentication by design.
- Initial routing is direct messages only and `BUZZ_ACP_RESPOND_TO=owner-only`; all other authors are dropped before Codex execution.
- Runtime identity/auth values must never enter Git, the Nix store, process arguments, provider configuration, or logs.
- The deployment helper must be the only sudo-allowed route from the SSH deploy principal to root agent management.
- An unexpected harness failure restarts; an owner `!shutdown` clean exit must remain stopped until `systemctl start buzz-agent-AGENT_ID` or a provider reconcile starts it again.
- Format Nix with `alejandra`; add new repository files to Git before evaluating the flake.

---

## File structure

| File | Responsibility |
| --- | --- |
| `apps/buzz-acp.nix` | Build/package a pinned Buzz ACP harness from the pinned Buzz source. |
| `apps/codex-acp.nix` | Package the pinned Codex ACP adapter with a reproducible npm dependency lock. |
| `apps/buzz-backend-gnomeregan.nix` | Install the local Buzz remote-provider executable and its input validation/SSH deploy logic. |
| `apps/scripts/buzz-backend-gnomeregan` | Provider implementation: `info` and `deploy` JSON protocol, redacted diagnostics, SSH transport. |
| `apps/scripts/buzz-agent-deploy` | Root-side restricted operation parser and atomic unit/runtime reconciliation. |
| `modules/services/buzz-agent-host.nix` | Gnomeregan account, runtime directory, unit template, sudo policy, and deploy helper wiring. |
| `modules/nixos/host/gnomeregan/configuration.nix` | Enables the Buzz agent host and exposes its packages locally. |
| `modules/home-manager/features/ai-tools.nix` | Installs the local Buzz provider on the Desktop host(s). |
| `tests/buzz-agent-host.sh` | Static unit/helper contract tests runnable without a deployment. |

## Task 1: Pin and package Buzz ACP and Codex ACP

**Files:**
- Create: `apps/buzz-acp.nix`
- Create: `apps/codex-acp.nix`
- Modify: `apps/fetcher/repos-src.nix`
- Modify: `apps/fetcher/npm-packages.nix`
- Test: `tests/buzz-agent-host.sh`

**Interfaces:**
- Consumes: existing `buzz-src` source pin and repository npm package-pinning conventions.
- Produces: `buzz-acp` executable and `codex-acp` executable usable by systemd through absolute store paths.

- [ ] **Step 1: Add failing packaging assertions**

Create `tests/buzz-agent-host.sh` with these initial checks:

```bash
#!/usr/bin/env bash
set -euo pipefail
nix build --no-link .#buzz-acp .#codex-acp
nix run .#buzz-acp -- --help >/dev/null
nix run .#codex-acp -- --version >/dev/null
```

- [ ] **Step 2: Run the assertions and verify they fail**

Run: `bash tests/buzz-agent-host.sh`

Expected: FAIL because neither flake package exists.

- [ ] **Step 3: Package the harnesses**

Add `apps/buzz-acp.nix` using `buildRustPackage`, the same `buzz-src` input and lock data convention as `apps/buzz-cli.nix`, with cargo flags:

```nix
cargoBuildFlags = ["-p" "buzz-acp" "--bin" "buzz-acp"];
```

Add `apps/codex-acp.nix` using `buildNpmPackage`; pin `@agentclientprotocol/codex-acp` and its transitive dependencies in the existing npm package lock input. Its install phase must expose:

```sh
$out/bin/codex-acp
```

Wire both as flake packages using the repository’s existing package-export module, without changing global user packages.

- [ ] **Step 4: Run packaging assertions**

Run: `bash tests/buzz-agent-host.sh`

Expected: PASS; both commands resolve from Nix store paths and print help/version without requiring a Codex login.

- [ ] **Step 5: Commit the package layer**

```bash
git add apps/buzz-acp.nix apps/codex-acp.nix apps/fetcher/repos-src.nix apps/fetcher/npm-packages.nix tests/buzz-agent-host.sh
git commit -m "feat: package Buzz ACP Codex harness"
```

## Task 2: Add gnomeregan’s isolated agent-host module

**Files:**
- Create: `modules/services/buzz-agent-host.nix`
- Modify: `modules/nixos/host/gnomeregan/configuration.nix`
- Modify: `colmena/hosts/gnomeregan.nix`
- Modify: `tests/buzz-agent-host.sh`

**Interfaces:**
- Consumes: `pkgs.callPackage ../../apps/buzz-acp.nix {}`, `pkgs.callPackage ../../apps/codex-acp.nix {}`, and the root-side helper added in Task 3.
- Produces: `users.users.buzz1`, `/var/lib/buzz-agents`, `buzz-agent@.service`, and a constrained deploy principal policy.

- [ ] **Step 1: Extend the test with static NixOS contracts**

Append checks that evaluate the gnomeregan configuration and assert the generated unit/account fields:

```bash
nix eval --raw .#colmenaHive.gnomeregan.config.users.users.buzz1.home | grep -Fx /home/buzz1
nix eval --json .#colmenaHive.gnomeregan.config.users.users.buzz1.extraGroups | jq -e 'index("wheel") | not'
nix eval --raw .#colmenaHive.gnomeregan.config.systemd.services."buzz-agent@".serviceConfig.User | grep -Fx buzz1
```

- [ ] **Step 2: Run the test and verify it fails**

Run: `bash tests/buzz-agent-host.sh`

Expected: FAIL because `buzz1` and `buzz-agent@` do not exist.

- [ ] **Step 3: Implement the isolated service boundary**

Create `modules/services/buzz-agent-host.nix` that defines:

```nix
users.users.buzz1 = {
  isSystemUser = true;
  group = "buzz1";
  home = "/home/buzz1";
  createHome = true;
  shell = pkgs.bashInteractive;
};
users.groups.buzz1 = {};
```

Define `/var/lib/buzz-agents/{env,units}` with root ownership and modes `0700`. Define `systemd.services."buzz-agent@"` with `User = "buzz1"`, `WorkingDirectory = "/home/buzz1"`, `EnvironmentFile = "/var/lib/buzz-agents/env/%i"`, `ExecStart` that runs the pinned `buzz-acp` with `BUZZ_ACP_AGENT_COMMAND` set to the pinned `codex-acp`, and hardening appropriate to an agent that must write only in its home: `ProtectSystem = "strict"`, `ReadWritePaths = ["/home/buzz1"]`, `ProtectHome = "tmpfs"` plus an explicit bind/read-write path for `/home/buzz1`, `NoNewPrivileges = true`, and `PrivateTmp = true`.

Use `Restart = "on-failure"`; document and test the pinned Buzz version’s exit-code behavior before relying on clean `!shutdown` exit for non-restart semantics. If upstream does not distinguish intentional clean exit from failure, make the deploy helper stop/mask the unit explicitly on shutdown rather than claiming systemd alone solves it.

Import the module from `colmena/hosts/gnomeregan.nix`, not a Hetzner common module. Add only the needed runtime packages to the NixOS module, not to `fdrake`’s Home Manager packages.

- [ ] **Step 4: Run static contracts and a build**

Run: `bash tests/buzz-agent-host.sh && nix build --no-link .#colmenaHive.gnomeregan.config.system.build.toplevel`

Expected: PASS. The evaluated account has no wheel membership; the unit runs as `buzz1` with its declared working directory.

- [ ] **Step 5: Commit the host boundary**

```bash
git add modules/services/buzz-agent-host.nix modules/nixos/host/gnomeregan/configuration.nix colmena/hosts/gnomeregan.nix tests/buzz-agent-host.sh
git commit -m "feat: add Buzz agent host account"
```

## Task 3: Implement the constrained gnomeregan deployment helper

**Files:**
- Create: `apps/scripts/buzz-agent-deploy`
- Modify: `modules/services/buzz-agent-host.nix`
- Modify: `tests/buzz-agent-host.sh`

**Interfaces:**
- Consumes: one JSON document on standard input with `operation`, `agent_id`, `environment`, and `unit_settings` fields.
- Produces: JSON `{ "ok": true, "unit": "buzz-agent@AGENT_ID.service" }` on success; JSON `{ "ok": false, "error": "redacted message" }` on failure.

- [ ] **Step 1: Add failing helper tests**

Add tests that execute the helper in a temporary state root (inject `BUZZ_AGENT_STATE_ROOT`) and assert:

```bash
printf '%s\n' '{"operation":"deploy","agent_id":"bad/id"}' | buzz-agent-deploy
# must fail: agent_id has invalid characters

printf '%s\n' '{"operation":"deploy","agent_id":"aabbccddeeff0011","environment":{"BUZZ_PRIVATE_KEY":"nsec-secret"}}' \
  | BUZZ_AGENT_STATE_ROOT="$tmp" buzz-agent-deploy
# must create $tmp/env/aabbccddeeff0011 mode 0600 and no secret in stdout/stderr
```

- [ ] **Step 2: Run tests and verify they fail**

Run: `bash tests/buzz-agent-host.sh`

Expected: FAIL because `buzz-agent-deploy` does not exist.

- [ ] **Step 3: Implement the helper**

Write `apps/scripts/buzz-agent-deploy` in Bash with `set -euo pipefail` and `jq`. It must:

1. read exactly one JSON object from stdin;
2. accept only `deploy`, `start`, `stop`, and `remove` operations;
3. require `agent_id` matching `^[a-f0-9]{16,64}$` and derive only `buzz-agent@${agent_id}.service` from it;
4. allow only the environment keys `BUZZ_PRIVATE_KEY`, `BUZZ_AUTH_TAG`, `BUZZ_RELAY_URL`, `BUZZ_ACP_RESPOND_TO`, `BUZZ_ACP_SUBSCRIBE`, `BUZZ_ACP_AGENT_COMMAND`, `BUZZ_ACP_AGENT_ARGS`, `BUZZ_ACP_MODEL`, and Codex adapter configuration keys explicitly approved by the module;
5. require `BUZZ_ACP_RESPOND_TO=owner-only` and `BUZZ_ACP_SUBSCRIBE=direct-messages` (or the exact verified Buzz ACP DM-only equivalent); reject caller overrides;
6. atomically write the environment file via `install -m 0600` and a same-directory `mv`, then `systemctl daemon-reload` and `systemctl enable --now` the derived unit;
7. remove the environment file and disable/stop the unit for `remove`; and
8. emit only an allowlisted JSON response that never contains received environment values.

Wire it into `modules/services/buzz-agent-host.nix` as a root-owned executable. Add a sudo rule for a dedicated SSH deploy user permitting exactly this absolute executable with no arbitrary arguments; make the helper consume stdin instead of arguments to keep secrets out of the process list.

- [ ] **Step 4: Run helper tests**

Run: `bash tests/buzz-agent-host.sh`

Expected: PASS. Invalid IDs are rejected, valid data yields mode `0600`, and a sentinel nsec never appears in output.

- [ ] **Step 5: Commit helper and policy**

```bash
git add apps/scripts/buzz-agent-deploy modules/services/buzz-agent-host.nix tests/buzz-agent-host.sh
git commit -m "feat: add constrained Buzz agent deploy helper"
```

## Task 4: Implement the Buzz Desktop SSH provider

**Files:**
- Create: `apps/scripts/buzz-backend-gnomeregan`
- Create: `apps/buzz-backend-gnomeregan.nix`
- Modify: `modules/home-manager/features/ai-tools.nix`
- Modify: `tests/buzz-agent-host.sh`

**Interfaces:**
- Consumes: Buzz provider request JSON: `{"op":"info","request_id":...}` or `{"op":"deploy","request_id":...,"agent":{...},"provider_config":{...}}`.
- Produces: `info` response with protocol version/schema; `deploy` response `{ "ok": true, "agent_id": "<agent public key>" }` only after gnomeregan reports the systemd unit active.

- [ ] **Step 1: Add failing provider protocol tests**

Add test cases using a fake `ssh` placed first in `PATH`:

```bash
printf '%s\n' '{"op":"info","request_id":"test"}' | buzz-backend-gnomeregan \
  | jq -e '.ok == true and .protocol_version == 1'

printf '%s\n' '{"op":"deploy","request_id":"test","agent":{"private_key_nsec":"nsec-sentinel","relay_url":"wss://buzz.internal.freddrake.com","respond_to":"owner-only"}}' \
  | PATH="$fake_path:$PATH" buzz-backend-gnomeregan >"$out" 2>"$err"
! grep -R --fixed-strings nsec-sentinel "$out" "$err"
```

- [ ] **Step 2: Run tests and verify they fail**

Run: `bash tests/buzz-agent-host.sh`

Expected: FAIL because the provider executable does not exist.

- [ ] **Step 3: Implement the provider**

Implement `apps/scripts/buzz-backend-gnomeregan` with no shell interpolation of JSON fields. `info` returns:

```json
{
  "ok": true,
  "name": "Gnomeregan",
  "version": "1.0.0",
  "protocol_version": 1,
  "description": "Deploys owner-only Codex ACP agents to gnomeregan",
  "config_schema": {
    "type": "object",
    "properties": {
      "host": {"type":"string","default":"gnomeregan.freddrake.com"},
      "ssh_user": {"type":"string","default":"buzz-deploy"}
    },
    "required": []
  }
}
```

For `deploy`, validate required non-empty identity, relay URL, and owner-only policy. Derive the stable ID from the agent public key—not the display name. Construct a compact JSON payload, pass it only through `ssh ... sudo /run/current-system/sw/bin/buzz-agent-deploy` standard input, and inspect the helper JSON response. Then use a second restricted SSH request to check `systemctl is-active buzz-agent@AGENT_ID.service`; return success only for `active`. Redact `nsec1...`, `BUZZ_AUTH_TAG`, and values from all caught diagnostic output.

Package it with `writeShellApplication`/`makeWrapper`, putting `jq`, `openssh`, and the script in `PATH`. Install the package on Desktop through `modules/home-manager/features/ai-tools.nix`, ensuring its binary name is exactly `buzz-backend-gnomeregan` so Desktop discovers it.

- [ ] **Step 4: Run provider tests and package build**

Run: `bash tests/buzz-agent-host.sh && nix build --no-link .#buzz-backend-gnomeregan`

Expected: PASS. The `info` schema parses; fake-SSH tests show provider requests contain no unsafe shell fragments and output/errors redact the sentinel secret.

- [ ] **Step 5: Commit provider**

```bash
git add apps/scripts/buzz-backend-gnomeregan apps/buzz-backend-gnomeregan.nix modules/home-manager/features/ai-tools.nix tests/buzz-agent-host.sh
git commit -m "feat: add gnomeregan Buzz backend provider"
```

## Task 5: Evaluate, deploy the host, and perform controlled manual enrollment

**Files:**
- Modify: `docs/superpowers/specs/2026-08-13-buzz1-remote-codex-harness-design.md`
- Test: `tests/buzz-agent-host.sh`

**Interfaces:**
- Consumes: built gnomeregan system closure and a Buzz Desktop agent configured with provider `gnomeregan`.
- Produces: an operational `buzz1` Codex login and a first owner-only agent service, with no credentials committed.

- [ ] **Step 1: Run all non-deployment verification**

Run:

```bash
alejandra apps/buzz-acp.nix apps/codex-acp.nix apps/buzz-backend-gnomeregan.nix modules/services/buzz-agent-host.nix modules/nixos/host/gnomeregan/configuration.nix
bash tests/buzz-agent-host.sh
nix build --no-link .#colmenaHive.gnomeregan.config.system.build.toplevel
```

Expected: all pass. Do not claim readiness if any assertion or build fails.

- [ ] **Step 2: Commit verification/documentation changes**

Document exact operator-only enrollment steps in the design spec: connect as the administrator, switch to `buzz1`, execute the installed Codex command once, finish browser/code login, and confirm a non-interactive `codex-acp --version` plus a minimal ACP initialization. Explicitly state that Codex credentials remain only under `/home/buzz1`.

```bash
git add docs/superpowers/specs/2026-08-13-buzz1-remote-codex-harness-design.md
git commit -m "docs: add Buzz1 enrollment runbook"
```

- [ ] **Step 3: Request explicit deployment authorization**

Ask the user to authorize the gnomeregan-only deployment. Do not run `just switch` or deploy automatically.

- [ ] **Step 4: Deploy gnomeregan through the required single-host deploy workflow**

After authorization, use the infrastructure-prescribed one-host Colmena deploy subagent for gnomeregan. Do not invoke Colmena directly in the main session.

Expected: service account, helper, and systemd template activate successfully.

- [ ] **Step 5: Perform the manual operational acceptance checks**

On gnomeregan, verify:

```bash
id buzz1
sudo -l -U buzz1
sudo -u buzz1 -H sh -lc 'test "$HOME" = /home/buzz1'
systemctl cat 'buzz-agent@.service'
```

Log in to Codex once as `buzz1`. In Buzz Desktop, create one agent using the `gnomeregan` provider and send an owner DM. Verify all of:

```bash
systemctl status buzz-agent@AGENT_ID.service
journalctl -u buzz-agent@AGENT_ID.service -n 100 --no-pager
sudo -u buzz1 -H test -w /home/buzz1
sudo -u buzz1 -H test ! -r /home/fdrake/.ssh/id_ed25519
```

Then test: owner DM gives one reply; a non-owner DM yields no reply/no new Codex turn; disconnect the MacBook/Desktop and repeat owner DM; kill the harness to check restart; issue `!shutdown`, confirm it stays down, and restart with `systemctl start buzz-agent-AGENT_ID`.

- [ ] **Step 6: Commit final validation record**

Add only non-secret validation outcomes to the design spec. Do not commit agent IDs, private keys, auth tags, Codex credentials, relay tokens, or raw journal output.

```bash
git add docs/superpowers/specs/2026-08-13-buzz1-remote-codex-harness-design.md
git commit -m "docs: record Buzz1 harness validation"
```
