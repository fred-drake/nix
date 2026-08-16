# Buzz1 remote Codex harness design

## Goal

Run Buzz agents continuously on gnomeregan rather than on a workstation. The initial deployment uses an unprivileged `buzz1` Unix account and accepts work only from the owner's Buzz identity. Multiple independently configured Buzz agents may share this one Unix account, its `/home/buzz1` workspace, and its Codex login.

A later `buzz2` account is a separate deployment boundary, with its own home, Codex credentials, and explicitly chosen filesystem access.

## Architecture

Buzz Desktop discovers a local `buzz-backend-gnomeregan` provider. For each Desktop agent deployed through that provider, it sends the agent's Buzz identity, owner authorization, effective instructions, Codex ACP configuration, and model configuration over authenticated SSH to gnomeregan.

The provider reconciles exactly one supervised `buzz-acp` harness instance for that agent identity. The harness runs Codex through the Codex ACP adapter. It connects directly to the private Buzz relay, so the MacBook/Desktop does not need to remain on after deployment.

Every deployed Desktop agent has a distinct Buzz/Nostr identity and its own harness systemd instance. Agents are not multiplexed within a single `buzz-acp` process. Several instances may nevertheless run as `buzz1` and deliberately share that account's authority and Codex authentication.

## Gnomeregan components

Nix declares:

- system account `buzz1`, with home `/home/buzz1`, no sudo access, and no access to `fdrake`'s home;
- Codex, `buzz-acp`, and the Codex ACP adapter in the service execution path;
- a privileged, narrowly scoped deploy helper used by the SSH provider to create, replace, start, stop, and remove agent units and their protected runtime files;
- a runtime directory for per-agent files, owned by root and inaccessible to `buzz1` outside the file descriptors/environment passed to its own service; and
- a systemd unit template that starts each harness as `buzz1` with `/home/buzz1` as its working directory.

The provider stores per-agent identity and relay authorization only in protected runtime environment files on gnomeregan. It must not put them in the Nix store, Git, Buzz provider configuration, command lines, or logs.

`buzz1` requires a one-time interactive Codex authentication, performed as that user. Codex then reuses its normal credential state from `/home/buzz1`; no Codex credential is declared by Nix.

## Agent behavior and access control

Each harness has these initial policies:

- direct messages plus channel messages that explicitly mention the agent;
- Buzz `owner-only` author gating, using the owner's agent registration/authorization;
- no heartbeat behavior;
- Codex workspace rooted at `/home/buzz1`; and
- one ACP worker per Desktop agent unless later capacity measurements justify changing it.

The pinned harness's exact routing mode is `BUZZ_ACP_SUBSCRIBE=mentions`. In that mode the relay filter requires the agent's `p` tag: Buzz clients add that tag to direct messages automatically, while ordinary channel messages must explicitly mention the agent. The provider, root helper, and static launcher all force `mentions`, force `BUZZ_ACP_HEARTBEAT_INTERVAL=0`, and strip caller-controlled subscription filters, configuration paths, heartbeat prompts, and heartbeat prompt files.

The owner-only gate drops other relay members' events before the Codex subprocess receives them. This is application-layer authorization; Unix isolation is provided by the `buzz1` account. All agents under `buzz1` share filesystem, network, process-inspection, and Codex-account authority by explicit design. They are not security-isolated from one another; deploy only mutually trusted agents under this account.

## Lifecycle

Deploying an agent creates or reconciles a deterministic systemd unit identified by its Buzz public key or stable agent identifier. A running unit publishes Buzz presence directly through the relay.

All ordinary harness exits, including unexpected status 0 and crashes, restart under `Restart=always`. A cryptographically verified owner `!shutdown` uniquely exits 42; `RestartPreventExitStatus=42` records a disabled marker and leaves the instance stopped. A manual `systemctl stop` also remains stopped for the current boot because systemd does not apply restart policy to explicit stops.

The normal persistent recovery for any stopped harness, including a signed `!shutdown`, is `sudo buzz-agentctl start AGENT_ID`. This module-owned command accepts only `start` and one canonical 64-lowercase-hex public agent ID, then sends a fixed start request to the existing root helper. The helper holds the operation and lifecycle locks, atomically removes only that instance's disabled marker, and starts the actual static template instance directly. Helper deploy/start/rollback and boot restore are the supported persistent activation paths because they preserve marker and lock semantics. NixOS configuration activation may also stop and directly start active template instances when their declarative unit or runtime package changes; the template permits this so every active agent moves to the current generation and the switch can report success.

A raw root `systemctl start` or `restart` of `buzz-agent@$AGENT_ID.service` is unsupported by contract: it bypasses the helper's persistent marker and lifecycle-lock protocol. It is not mechanically rejected. Root is trusted and can already modify the unit and marker state. The remote deploy principal cannot obtain a shell or arbitrary `systemctl` through its forced-command key and narrow sudo rule, while the unprivileged `buzz1` service account has no systemd management privilege.

The marker stays cleared across reboot, where boot restoration starts the managed instance directly. Restoration skips marked agents without submitting a start job and rechecks markers after each unmarked start so a shutdown racing with restoration wins. A helper, agentctl, or successful deploy start is an explicit persistent recovery request: it consumes the deliberate marker before process launch even if a later service start or stability check fails. The marker remains cleared and the unit then follows its normal restart policy; depending on where startup failed, it may remain down or enter a restart loop. By contrast, a failed deploy reconciliation rolls back the prior environment and prior marker state; rollback does not erase a marker that existed before the deploy. A redeploy stops an active old generation before activating the newly installed environment. Removing an agent stops its process before deleting its environment and marker. Removal does not remove `/home/buzz1` or its Codex login.

## Provider contract

`buzz-backend-gnomeregan` implements Buzz's remote provider `info` and `deploy` contract. Its non-secret configuration is limited to host/SSH connection and optional deployment naming details. It obtains the private key, NIP-OA authorization, relay URL, and effective harness configuration from the one-time deploy payload and transmits them only via SSH standard input or a protected remote installation path.

The provider validates inputs, avoids shell interpolation, uses deterministic unit naming, and makes deployment idempotent. It must never report a unit running merely because deployment files were written: it verifies systemd start success and surfaces redacted diagnostics on failure.

The provider is trusted local code because it receives the deployed agent private key. Its deployment key is an OpenSSH forced-command key with shell, PTY, agent/X11 forwarding, TCP/streamlocal forwarding, user rc, and arbitrary original commands disabled. The module-owned forced command accepts only the literal `buzz-agent-deploy` operation, bounds stdin before invoking sudo, and passes that bounded stream to the no-argument root helper. Sudo authorization permits only that helper, so the remote deploy principal cannot obtain a shell or invoke arbitrary `systemctl`. The harness runs as `buzz1`, which has neither sudo nor systemd management privilege. Administrators using sudo are trusted root and must follow the supported helper contract.

## Error handling and recovery

- Invalid or missing agent identity, authorization, relay URL, or Codex ACP executable: fail closed; do not create a runnable service.
- SSH/deploy failure: leave any known-good existing unit unchanged where possible and return redacted failure detail.
- Harness crash or unexpected clean exit: systemd restarts it and logs are available to the administrator through `journalctl`.
- Relay outage: `buzz-acp` reconnects; no Desktop process is required.
- Codex login expiry: the harness cannot complete turns until an administrator logs in again interactively as `buzz1`; service configuration and Buzz identity remain intact.
- Intentional `!shutdown`: administrator runs `sudo buzz-agentctl start AGENT_ID` to clear the persistent marker and restart, or deploys/reconciles from Buzz Desktop. If that explicit start fails, the marker remains cleared and normal restart policy applies; inspect whether the unit is down or restarting before the next reboot, when restoration will retry an inactive unit.

## Operator runbook

All host deployment and lifecycle commands require normal administrative authorization. Never paste an nsec, auth tag, relay token, or Codex credential into a command line, ticket, or journal.

### Install the host configuration and enroll Codex

From this repository, after explicit deployment approval:

```bash
just colmena gnomeregan
ssh gnomeregan.internal.freddrake.com
sudo -iu buzz1
codex login
codex --version
codex-acp --version
exit
```

Complete `codex login` using its browser/device flow. Credentials remain only under `/home/buzz1/.codex`; do not enable SSH keys for `buzz1`.

### Confirm Desktop provider discovery and deploy an agent

On the Desktop host:

```bash
command -v buzz-backend-gnomeregan
printf '%s\n' '{"op":"info","request_id":"operator-check"}' \
  | buzz-backend-gnomeregan | jq -e '.ok and .name == "Gnomeregan"'
```

Restart Buzz Desktop after installing or changing the provider. In the agent's deployment UI, select **Gnomeregan** and deploy. The provider response identifies the 64-hex `agent_id`; if it is not visible, list managed IDs on the host without reading their secret-bearing contents:

```bash
sudo find /var/lib/buzz-agents/env -mindepth 1 -maxdepth 1 -type f -printf '%f\n'
```

Set `AGENT_ID` to that exact 64-hex value. Inspect the instance with:

```bash
sudo systemctl status "buzz-agent@$AGENT_ID.service"
sudo journalctl -u "buzz-agent@$AGENT_ID.service" -n 100 --no-pager
```

A provider redeploy reconciles configuration, clears a disabled marker, and starts the instance. The normal persistent recovery without redeploying is exactly:

```bash
sudo buzz-agentctl start "$AGENT_ID"
```

`buzz-agentctl` validates the public ID and forwards only a fixed start request to the existing root helper. Under the operation and lifecycle locks, the helper atomically clears `/var/lib/buzz-agents/disabled/$AGENT_ID` before launch. On success the agent is running now and is eligible for automatic restoration after every later reboot. On failure the marker is still cleared because recovery was explicitly requested; the command prints the helper's redacted `{ok:false}` response and exits nonzero. The unit follows `Restart=always`, so inspect `systemctl status`/`journalctl` to determine whether it is down or in a restart loop, correct the cause, and retry. Neither the command line nor its fixed/redacted output contains runtime secrets, and the command never reads or prints the secret-bearing environment file.

### Intentional shutdown, restart, and removal

From the registered owner identity, send `!shutdown` in a DM to the agent or in a channel message that explicitly mentions it. Buzz signs the event; the harness accepts shutdown only when the event signature, event ID, owner, target mention, kind, and content verify. Confirm status 42 and the marker:

```bash
sudo systemctl status "buzz-agent@$AGENT_ID.service"
sudo test -f "/var/lib/buzz-agents/disabled/$AGENT_ID"
```

Restart persistently with the exact `buzz-agentctl start` command above; confirm the marker was removed with `sudo test ! -e "/var/lib/buzz-agents/disabled/$AGENT_ID"`. For a boot-persistent administrative stop without a signed relay event, use the constrained helper:

```bash
printf '{"operation":"stop","agent_id":"%s"}\n' "$AGENT_ID" \
  | sudo /run/current-system/sw/bin/buzz-agent-deploy
sudo test -f "/var/lib/buzz-agents/disabled/$AGENT_ID"
```

Recover from that stop persistently with the same `buzz-agentctl start` command. To remove one deployment while preserving the shared account and Codex login:

```bash
printf '{"operation":"remove","agent_id":"%s"}\n' "$AGENT_ID" \
  | sudo /run/current-system/sw/bin/buzz-agent-deploy
sudo test ! -e "/var/lib/buzz-agents/env/$AGENT_ID"
sudo test ! -e "/var/lib/buzz-agents/disabled/$AGENT_ID"
sudo test -d /home/buzz1/.codex
```

Removal stops the static template instance and deletes only its environment and disabled marker. It does not delete `/home/buzz1`, Codex credentials, or another agent's files.

### Recovery

- For an ordinary clean exit or crash, check `NRestarts` and the journal; systemd should restart automatically.
- For a verified status-42 shutdown, run exactly `sudo buzz-agentctl start "$AGENT_ID"` or redeploy from Desktop. Either explicit path clears the marker persistently.
- Raw root `sudo systemctl start` or `restart` of `buzz-agent@$AGENT_ID.service` is unsupported because it bypasses persistent marker and lifecycle-lock handling; use `buzz-agentctl` or Desktop reconciliation. Root is trusted, so this contract is not mechanically enforced.
- A raw root `sudo systemctl stop "buzz-agent@$AGENT_ID.service"` stops only for the current boot and creates no marker. Use the exact helper `stop` request above or signed `!shutdown` for a boot-persistent stop; recover either with `buzz-agentctl start`.
- For relay/auth/config errors, inspect the redacted journal, correct the provider settings, and redeploy.
- For expired Codex authentication, rerun `sudo -iu buzz1 codex login`, then start/redeploy the instance.
- Treat every agent under `buzz1` as mutually trusted. If an agent requires a different trust boundary, deploy it under a separate Unix account such as the future `buzz2` design.

## Non-secret acceptance record

Recorded live acceptance completed on Gnomey before final review:

- the Desktop provider deployed the remote harness and the agent connected without the Desktop remaining online;
- an owner-authored channel message that explicitly mentioned the agent reached Codex, completed a turn, and published one reply; and
- no heartbeat was intentionally configured or observed in that acceptance.

Live checks still deferred: a separately recorded owner-DM turn, two simultaneous agents sharing `buzz1`, non-owner DM and channel-mention rejection, and live remove/cleanup. Automated evidence covers those boundaries as follows: pinned-source tests prove `mentions` filtering and DM owner gating; provider/helper/launcher conformance proves authoritative `owner-only`, `mentions`, and heartbeat interval 0; SSH VM/static assertions cover the restricted transport; helper tests cover non-owner policy inputs and rollback; supported-operation race tests cover deploy/restore/remove/shutdown serialization; and the real systemd VM covers boot restore without marked-unit start calls, NixOS-style changed-unit stop/start of an active template instance, ordinary status-0 restart, crash restart, manual stop, persistent status-42 shutdown, strict `buzz-agentctl` success/failure behavior, deploy/redeploy environment replacement, remove final state, and restoration after a post-recovery reboot. Deferred live checks must not be represented as completed.

## Validation

1. Evaluate/build the gnomeregan configuration without exposing runtime secrets in the store.
2. Confirm `buzz1` has no sudo access and cannot read `fdrake`'s home or another privileged agent's protected files.
3. Authenticate Codex once as `buzz1`, then prove a non-interactive Codex ACP invocation can use that authentication.
4. Verify the restricted SSH key permits only the bounded helper request and denies shell, PTY, forwarding, user rc, and arbitrary commands.
5. Verify owner DMs and owner-mentioned channel messages each produce exactly one intended turn, while unmentioned channel messages do not.
6. From a non-owner relay identity, send a DM and an explicit mention and verify neither reaches Codex or publishes a reply.
7. Stop Desktop/the MacBook connection and verify the deployed agent remains online and responds.
8. Prove ordinary status 0 and crashes restart; prove manual stop and verified status 42 remain stopped.
9. Reboot and prove unmarked agents restore while marked agents remain stopped without receiving a start call; prove a NixOS-style changed-unit stop/start can reactivate an active template instance on the current generation, then run `sudo buzz-agentctl start AGENT_ID` after status 42, prove its marker is cleared, reboot again, and prove restoration starts it. Prove deploy/redeploy runs the installed environment generation and remove leaves the process absent and down. Exercise supported helper/restore/remove/shutdown races under the operation/lifecycle locks; do not treat raw root systemctl lifecycle commands as supported application operations.
10. Deploy two distinct Buzz Desktop agents and verify two identities share `/home/buzz1` only by explicit trust decision.
11. Remove an agent and verify its protected per-agent runtime data is gone while `buzz1` and its Codex login remain.
