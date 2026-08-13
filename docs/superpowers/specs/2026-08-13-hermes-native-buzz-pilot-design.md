# Hermes native Buzz pilot design

## Goal

Upgrade the existing always-on Hermes service on orgrimmar from Hermes 0.17 to 0.20, then make it a native participant in the private Buzz relay. It remains one isolated Hermes instance, retaining its current `/var/hermes` state and vault access, and continues working while the desktop/laptop is off.

Future personas, such as a Hermes instance used exclusively with Laisa, will be separate containers and native Buzz identities with distinct hostnames, state directories, vaults, secrets, and channel memberships.

## Chosen approach

Use Hermes 0.20's native `buzz` gateway platform. Do not use a Buzz Desktop-managed runtime, `buzz-acp`, Hermes multiplexed profiles, or a custom Hermes fork.

The existing `/var/hermes` directory is the pilot's state boundary. Each future persona will be another complete Hermes service rather than another profile inside this container.

## Hermes 0.20 prerequisite

The deployed `nousresearch/hermes-agent:v2026.6.19` image is Hermes 0.17 and does not contain the Buzz adapter. Upgrade first to the digest-pinned `v2026.8.3` image (Hermes 0.20).

Hermes 0.20's container initialization must start as root so its s6 entrypoint can reconcile the configured UID/GID and persistent volume. Remove the OCI container's explicit `user` setting, retain `HERMES_UID=10000` and `HERMES_GID=10000`, and let the image drop the gateway process to its `hermes` user.

Before deployment, stop Hermes and the vault-sync timer/service so `/var/hermes` is quiescent, then trigger and verify a fresh Borg snapshot. Keep writes stopped until the 0.20 deployment. The new image migrates the persistent config from schema 30 to 33, creating timestamped config and env backups. Validate the migrated configuration, dashboard, memory/state paths, vault, and existing provider before adding Buzz.

## Buzz CLI

Hermes 0.20 includes the Buzz adapter but not the `buzz` executable it uses for REST operations and outbound messages.

Build a static `buzz` CLI from the exact source revision recorded by the deployed Buzz relay image (`4749bc7be3cdb78c2db4ce4864775ba7ab60b4cc`). Use `nixpkgs-unstable` for this package because the stable Orgrimmar package set provides Rust 1.86, below Buzz's minimum Rust 1.88. Mount the resulting static executable read-only into the Hermes container and verify it inside the exact Hermes 0.20 image before enabling the integration.

## Declarative configuration

Use Hermes 0.20's managed-scope configuration instead of modifying `/var/hermes/config.yaml` on every restart. Generate a non-secret JSON-as-YAML file in the Nix store and mount it read-only at `/etc/hermes/config.yaml`.

The managed configuration enables the Buzz platform and sets:

- WebSocket with polling fallback (`transport: auto`),
- mention gating in channels,
- private allowlist mode,
- the mounted Buzz CLI path,
- final responses only (`interim_assistant_messages: false`), and
- no tool-progress messages (`tool_progress: off`).

The existing SOPS-managed `hermes-env` file also carries the dedicated private key, relay URL, pilot channel UUID, home channel UUID, and the owner's Buzz public key allowlist. Keeping all credentials for this one Hermes instance in its existing environment secret avoids unnecessary secret/module plumbing. Direct relay membership is used, so no API token or NIP-OA auth tag is required. REST calls authenticate with NIP-98 and WebSocket calls with NIP-42.

## Identity, channel, and access

Create a dedicated Nostr keypair for Hermes and enroll its public key directly with the relay's `buzz-admin`. Use the matching Buzz CLI to publish a `Hermes` profile.

Create a dedicated private Buzz channel owned by the human owner, and add Hermes as a bot. Configure Hermes to watch only this channel and use it as the home channel for cron and notifications.

Only the owner's allowlisted Buzz identity may invoke Hermes. Channel messages require an explicit mention. Hermes 0.20 always discovers and dispatches direct messages regardless of mention settings; this is accepted for the pilot because the same owner allowlist applies. Non-owner channel messages and DMs must be rejected before model/tool execution.

## Isolation and future instances

The pilot retains only its current `/var/hermes` state and existing vault access. No second profile or shared gateway is introduced.

A future Laisa instance will use, at minimum:

- a separate container/service and hostname such as `hermes-laisa.internal.freddrake.com`,
- a distinct `/var/hermes-laisa` state directory,
- its own vault repository and mount,
- its own provider and service secrets,
- a distinct Buzz keypair/profile and SOPS environment file,
- its own private channel memberships and user allowlist, and
- a distinct dashboard port.

No two containers may mount the same Hermes state directory or vault.

## Failure handling and rollback

- If the 0.20 migration or gateway fails, stop and mask Hermes before rollback. Restore the complete quiesced schema-30 `/var/hermes` snapshot (or, for a config-only migration failure with otherwise untouched state, the matching pre-upgrade `config.yaml` and `.env` backups) before starting the 0.17 closure. Never start Hermes 0.17 against schema-33 state.
- If the static Buzz CLI does not build or execute inside the 0.20 image, do not substitute an unpinned binary or expose the host Nix store; fix the package in isolation.
- If direct relay membership, profile publication, or private-channel access fails, keep the Buzz environment file disabled and gather relay/CLI evidence.
- The adapter uses WebSocket first and polling fallback in `auto` mode. A WebSocket-only failure must not be described as fallback success.
- SOPS secret changes restart `podman-hermes.service` so credentials are reloaded.

## Validation

1. Build the Hermes 0.20 upgrade, quiesce Hermes/vault sync, create and verify a fresh `/var/hermes` Borg snapshot, then deploy only orgrimmar.
2. Verify Hermes reports version 0.20, runs as UID/GID 10000 after root initialization, migrates config schema 30→33, and retains its dashboard, provider, memory, sessions, and vault.
3. Verify the static Buzz CLI has no dynamic interpreter and runs inside the exact 0.20 image as the Hermes service user.
4. Verify direct relay membership, the published Hermes profile, the private channel roster, and that unrelated relay members cannot list or read the channel.
5. Verify the native adapter authenticates by NIP-42 WebSocket and that its REST CLI operations authenticate by NIP-98.
6. From the owner identity, verify a channel mention and an owner DM each yield one final response with no progress chatter.
7. From a non-allowlisted identity, verify both a channel mention and a DM cause no model/tool invocation and no response.
8. Restart Hermes and confirm no historical messages replay.
9. Confirm Hermes remains reachable after Buzz Desktop on the laptop is closed or suspended.
