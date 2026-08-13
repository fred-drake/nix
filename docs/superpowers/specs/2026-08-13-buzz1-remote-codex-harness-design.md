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

- direct messages only;
- Buzz `owner-only` author gating, using the owner's agent registration/authorization;
- no channel subscriptions or heartbeat behavior;
- Codex workspace rooted at `/home/buzz1`; and
- one ACP worker per Desktop agent unless later capacity measurements justify changing it.

The owner-only gate drops other relay members' events before the Codex subprocess receives them. This is application-layer authorization; Unix isolation is provided by the `buzz1` account. All agents under `buzz1` share filesystem, network, and Codex-account authority by explicit design. They are not security-isolated from one another.

## Lifecycle

Deploying an agent creates or reconciles a deterministic systemd unit identified by its Buzz public key or stable agent identifier. A running unit publishes Buzz presence directly through the relay.

Unexpected harness failures restart under systemd policy. An owner-issued Buzz `!shutdown` is an intentional clean stop and remains stopped; it must not enter a restart loop.

The administrator may restart a stopped harness on gnomeregan with `systemctl start buzz-agent-AGENT_ID`. The provider's subsequent deploy/reconcile operation must also start it. Removing an agent stops and removes its unit plus its per-agent runtime identity/configuration, but does not remove `/home/buzz1` or its Codex login.

## Provider contract

`buzz-backend-gnomeregan` implements Buzz's remote provider `info` and `deploy` contract. Its non-secret configuration is limited to host/SSH connection and optional deployment naming details. It obtains the private key, NIP-OA authorization, relay URL, and effective harness configuration from the one-time deploy payload and transmits them only via SSH standard input or a protected remote installation path.

The provider validates inputs, avoids shell interpolation, uses deterministic unit naming, and makes deployment idempotent. It must never report a unit running merely because deployment files were written: it verifies systemd start success and surfaces redacted diagnostics on failure.

The provider is trusted local code because it receives the deployed agent private key. SSH authentication and sudo authorization on gnomeregan are restricted so the provider can perform only the agent-management operations required by this design.

## Error handling and recovery

- Invalid or missing agent identity, authorization, relay URL, or Codex ACP executable: fail closed; do not create a runnable service.
- SSH/deploy failure: leave any known-good existing unit unchanged where possible and return redacted failure detail.
- Harness crash: systemd restarts it and logs are available to the administrator through `journalctl`.
- Relay outage: `buzz-acp` reconnects; no Desktop process is required.
- Codex login expiry: the harness cannot complete turns until an administrator logs in again interactively as `buzz1`; service configuration and Buzz identity remain intact.
- Intentional `!shutdown`: administrator uses `systemctl start buzz-agent-AGENT_ID` to restart, or deploys/reconciles from Buzz Desktop.

## Validation

1. Evaluate/build the gnomeregan configuration without exposing runtime secrets in the store.
2. Confirm `buzz1` has no sudo access and cannot read `fdrake`'s home or another privileged agent's protected files.
3. Authenticate Codex once as `buzz1`, then prove a non-interactive Codex ACP invocation can use that authentication.
4. Deploy two distinct Buzz Desktop agents through the provider; verify two systemd units and identities run as `buzz1` while sharing `/home/buzz1`.
5. From the owner identity, send each agent a DM and verify exactly one response from the intended agent.
6. From a non-owner relay identity, send DMs and verify no Codex process or reply is triggered.
7. Stop Desktop/the MacBook connection and verify the deployed agent remains online and responds.
8. Kill a harness unexpectedly and verify systemd restarts it.
9. Issue `!shutdown`, verify it remains stopped, then restart it using `systemctl start buzz-agent-AGENT_ID` and verify it reconnects.
10. Remove an agent and verify its unit and protected per-agent runtime data are gone while `buzz1` and its Codex login remain.
