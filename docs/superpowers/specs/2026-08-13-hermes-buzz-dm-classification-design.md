# Hermes Buzz DM classification design

## Status

Draft for review. This document proposes a downstream interoperability patch only. It does not authorize deployment.

## Goal

Make a valid, mention-free, one-to-one Buzz DM from an allowlisted owner reach Hermes while preserving both existing security boundaries:

- an ordinary channel still requires an explicit Hermes mention; and
- a non-allowlisted author is rejected in the adapter before model or tool execution.

The change must remain compatible with the digest-pinned Hermes container and the existing read-only Nix-managed mounts. It must not modify a running container image or persistent `/var/hermes` state in place.

## Confirmed gap

The deployed image is `nousresearch/hermes-agent:v2026.8.3` at digest `sha256:c0cab4e3711bcb27a312be1b3776254fc06fd50d5f7a6b8017915fc7171cb39e`. Its OCI revision label is Hermes source commit `3c27eb6234bf91b8ceee9e9071591b31e9b148cb`, the commit behind tag `v2026.8.3`. The deployed `/opt/hermes/plugins/platforms/buzz/adapter.py` has SHA-256 `8bd1a75cb0f1ad0555d2cf635853ae3804bfd67cf02333825874c6b4fee1736b`, matching that revision's source.

The adapter currently:

- treats `require_mention` as a channel-only gate (`adapter.py:384-393`);
- watches `channels list` entries named `DM` with an empty description as `group` when `dms list` is empty (`adapter.py:948-987`);
- reclassifies such an entry only when a kind-9 event has a `p` tag for Hermes and no visible mention (`adapter.py:1028-1037`, `1102-1137`); and
- applies its author allowlist before `_dispatch_message`, but only after the classification and mention checks (`adapter.py:1039-1059`).

The pinned Buzz revision is `4749bc7be3cdb78c2db4ce4864775ba7ab60b4cc`. At that revision:

- `dms open` sends participant `p` tags on a kind-41010 command (`crates/buzz-cli/src/commands/dms.rs:50-93`);
- the relay turns that command into a database channel with `channel_type='dm'`, `visibility='private'`, and an immutable participant set (`crates/buzz-relay/src/handlers/command_executor.rs:318-379`, `crates/buzz-db/src/dm.rs:130-215`);
- relay-signed kind-39000 metadata includes `t=dm`, `private`, `hidden`, and DM participant `p` tags (`crates/buzz-relay/src/handlers/side_effects.rs:1050-1085`); and
- a kind-9 chat message receives an `h` tag but receives `p` tags only for explicit or derived mentions (`crates/buzz-sdk/src/builders.rs:216-245`, `crates/buzz-cli/src/commands/messages.rs`).

The pinned CLI's `channels list` projection discards channel type and participant tags. Its `channels search` projection preserves `channel_type` and `visibility`, and `channels members` returns the current participant pubkeys and roles. On the deployed relay, the affected owner DM is reported as `channel_type: "dm"`, `visibility: "private"`, with exactly the owner and Hermes as `member`; its mention-free kind-9 messages contain an `h` tag and no `p` tag.

This is an adapter/CLI shape mismatch, not an invalid Buzz event.

## Options

### A. Patch and package the Hermes Buzz adapter — recommended

Patch the adapter to use authoritative relay metadata plus membership and the existing owner allowlist. Package the patched file from the exact Hermes source revision and bind-mount it read-only over the adapter in the unchanged digest-pinned image.

Advantages:

- fixes all inbound clients, including Desktop, mobile, and the pinned CLI;
- retains channel mention gating and adapter-level pre-model author denial;
- uses relay-authored `channel_type`, not a user-chosen channel name, as the DM boundary;
- leaves the image digest, persistent state, secrets, and managed configuration unchanged; and
- is small and independently removable when Hermes ships an equivalent fix.

Costs:

- carries one narrowly scoped downstream patch;
- depends on the pinned CLI's current `channels search` and `channels members` JSON contracts; and
- adds bounded metadata/member lookups during DM discovery.

### B. Patch or wrap Buzz sends to add recipient `p` tags — reject

A CLI wrapper could detect a DM channel, resolve the other participant, and add `--mention <pubkey>` to `messages send`. A direct Buzz source patch could do the same before `build_message`.

This repairs only messages sent through that exact wrapped CLI. Hermes receives events from other clients, and the valid protocol shape permits kind-9 DM messages with only the channel `h` tag. Desktop, mobile, or another client could reproduce the failure. It also makes send behavior perform extra metadata/member inference and risks turning structural delivery tags into visible-mention semantics. It is not an interoperability fix.

### C. Managed configuration workaround — unavailable

The deployed adapter supports relay URL, CLI path, channels, home channel, poll interval, transport, allowed users, `allow_all_users`, and `require_mention`. It has no supported DM-channel override, participant policy field, or per-channel mention setting.

Setting `require_mention=false` would violate the required channel policy. Adding the DM UUID to `BUZZ_CHANNELS` still seeds it as `group`. A second profile would duplicate discovery and conflict on the same Buzz identity lock. No managed-only workaround satisfies the requirements.

## Recommended classification invariant

A conversation may enter the mention-free DM path only when all of the following are true:

1. **Authoritative type:** relay-derived metadata for this exact channel ID reports `channel_type == "dm"` and `visibility == "private"`.
2. **One-to-one membership:** a successful `channels members --channel <id>` result contains exactly two distinct normalized pubkeys: Hermes's own pubkey and one other pubkey. Both entries have the relay's DM role `member`.
3. **Allowed owner:** the non-Hermes participant is in the adapter's non-empty normalized `_allowed_pubkeys` set.
4. **Event author:** the kind-9 event author equals that allowed participant and is not Hermes.
5. **Channel binding:** the event has an `h` tag equal to the channel ID through which it was received.
6. **Fail-closed evidence:** missing, malformed, conflicting, stale, or unsuccessful metadata/member results do not classify the conversation as a DM. It remains `group`, so `require_mention` still applies.

The `name == "DM"` and empty-description shape remains only a discovery hint for relays where `dms list` is empty. It is never authorization or classification evidence.

This invariant cannot misclassify an ordinary private channel merely because it is named `DM`: ordinary channels are relay-authored as `stream` or `forum`, while only the DM command path creates `channel_type='dm'`. The relay emits the type from database state in signed kind-39000 metadata. The exact two-member/role and allowed-author checks are independent defense-in-depth and limit this patch to the required owner-to-Hermes one-to-one DM. Group DMs are intentionally out of scope.

Move the existing adapter allowlist rejection to immediately after basic event validation and self-echo suppression, before DM classification and mention gating. This preserves authorized behavior while ensuring an unauthorized event cannot latch or otherwise influence DM state. `_dispatch_message` remains the sole boundary into gateway/model processing.

## Adapter changes

Patch Hermes source file `plugins/platforms/buzz/adapter.py` at source revision `3c27eb6234bf91b8ceee9e9071591b31e9b148cb`.

Keep the change local to DM discovery/classification:

- Extend `_channel_meta` entries with authoritative fields from one bounded `buzz channels search --query DM --exact --include-archived` call per discovery cycle. Index results by `channel_id`; do not trust the query text as proof.
- For entries whose authoritative type is `dm` and visibility is `private`, call `buzz channels members --channel <id>` and normalize its pubkeys/roles into a cached participant record.
- Add a small pure predicate for the invariant above. Use it in `_maybe_latch_dm` so a valid owner event can latch without a `p` tag. The event's `p` tags become irrelevant to classification.
- Preserve fallback entries as `group` until the full predicate succeeds. Existing mentioned channel/DM traffic therefore continues through the channel mention path if metadata lookup is temporarily unavailable.
- Move the existing `_allowed_pubkeys` rejection ahead of `_maybe_latch_dm`.
- Retain the existing discovery cadence, de-duplication, high-water marks, transport handling, and dispatch API. Do not add a new config field, database access, generic Nostr client, or background cache subsystem.

The implementation should update the inaccurate p-tag comments and log a non-sensitive reason such as `verified relay DM metadata and owner participant`; it must not log full membership data or secrets.

## Packaging

Use a single-consumer Nix package, not a global overlay and not a derived mutable container:

1. Add a `hermes-agent-v2026.8.3-src` entry to `apps/fetcher/repos.toml`, pinned to commit `3c27eb6234bf91b8ceee9e9071591b31e9b148cb`, and regenerate only its entry in `apps/fetcher/repos-src.nix`.
2. Add a focused unified patch, for example `apps/hermes-buzz-owner-dm.patch`, covering `plugins/platforms/buzz/adapter.py` and its narrow fixture tests in `tests/gateway/test_buzz_adapter.py`.
3. Add `apps/hermes-buzz-adapter.nix`. Its derivation must:
   - assert the unpatched adapter SHA-256 is `8bd1a75cb0f1ad0555d2cf635853ae3804bfd67cf02333825874c6b4fee1736b` before applying the patch;
   - apply the patch to the pinned source;
   - run `python -m py_compile` on the patched adapter; and
   - install only the resulting `adapter.py` as `$out/adapter.py`.

   Run the focused upstream Buzz adapter tests against that same patched source as a separate check or implementation verification. Do not pull the full Hermes test/runtime dependency graph into the production file artifact merely to execute one test module.
4. In `modules/services/hermes.nix`, instantiate that package and add exactly one read-only file mount:

   ```nix
   "${hermesBuzzAdapter}/adapter.py:/opt/hermes/plugins/platforms/buzz/adapter.py:ro"
   ```

The existing digest-pinned image remains the executable/runtime base, and the existing `/etc/hermes` and Buzz CLI mounts remain read-only. The source revision and pre-patch checksum make image/source drift a build failure. Do not copy into a running container, use `podman cp`, edit `/opt/hermes`, or expose the host Nix store wholesale.

## Test fixtures

Extend `tests/gateway/test_buzz_adapter.py` using the existing scripted CLI and captured `_dispatch_message` pattern.

### Required regression fixtures

1. **RED, then GREEN: valid owner DM without `p` tag**
   - `dms list` returns `[]`.
   - `channels list` returns name `DM`, empty description.
   - `channels search` returns the same ID with `channel_type: dm`, `visibility: private`.
   - `channels members` returns exactly Hermes/member and owner/member.
   - The event is kind 9, authored by the allowlisted owner, and has only `['h', DM_CHANNEL]`; content has no Hermes mention.
   - Before the patch it produces no dispatch. After the patch it produces exactly one `chat_type='dm'` dispatch.

2. **Ordinary private channel named `DM` remains mention-gated**
   - Give it the same name and empty description and, if useful, the same two pubkeys.
   - Authoritative metadata reports `channel_type: stream` (or `forum`), `visibility: private`; normal roles may be owner/bot.
   - An owner event without a mention produces no dispatch and the state remains `group`.
   - This is the load-bearing anti-misclassification test.

3. **Non-owner DM is denied before dispatch**
   - Use valid `dm/private` metadata but a participant/author not in `_allowed_pubkeys`, or inject a non-owner-authored event into the owner fixture.
   - No call to `_dispatch_message` occurs and the unauthorized event cannot latch the conversation to the owner DM path.

4. **Mentioned paths are unchanged**
   - An allowlisted owner mention in an ordinary channel dispatches exactly once as `group`.
   - An allowlisted owner mention in the verified DM still dispatches exactly once; its corrected classification is `dm` rather than the fallback `group` classification.
   - A non-owner mention still produces no dispatch.

### Fail-closed fixtures

- `channels search` failure, malformed type/visibility, `channels members` failure, extra participant, duplicate/conflicting member, wrong role, missing/mismatched `h`, and group DM each remain `group` and require a mention.
- Existing `dms list` success, startup seeding, WebSocket discovery, polling discovery, de-duplication, and restart/no-replay tests remain unchanged or receive only the minimum fixture data required by the stronger classifier.

The production derivation should also prove the patched module compiles. Before deployment, run an exact-image import preflight with the packaged read-only file mounted over the adapter path.

## Deployment and validation

Deployment is a separate, explicitly authorized implementation task.

1. Format the Nix files with `alejandra` and stage new files before flake evaluation.
2. Run the focused adapter tests, build the adapter derivation, and run `colmena build --on orgrimmar --impure`.
3. Evaluate the Hermes volume list and verify it contains the one read-only adapter file mount plus the unchanged CLI and managed-config mounts.
4. Run a disposable exact-image preflight using the current image digest and the candidate file mount. Import `plugins.platforms.buzz.adapter`, confirm `__file__` is the mounted target, and perform no relay writes.
5. Deploy only Orgrimmar with the repository's approved Colmena workflow. Do not run `just switch`.
6. Verify service readiness and that the mounted adapter checksum matches the built artifact. Then run bounded live checks:
   - allowlisted owner, mention-free DM without `p` tag: one final response;
   - ordinary channel named `DM`, no mention: no response/session/tool invocation;
   - non-owner DM: no response/reaction/session/tool invocation;
   - owner channel mention and owner DM mention: behavior unchanged;
   - restart: no historical replay.

Evidence must record event IDs, public identities, metadata type, participant-count assertions, response/session deltas, and adapter checksum without recording private keys, full environments, or message bodies.

## Rollback

This patch changes no Hermes schema, secret, relay state, or `/var/hermes` data.

Rollback by activating the exact previously recorded NixOS closure, or by reverting the adapter package/mount change, rebuilding, and deploying only Orgrimmar. The prior closure returns to the unchanged digest-pinned image's built-in adapter. Verify:

- the adapter file mount is absent;
- `/opt/hermes/plugins/platforms/buzz/adapter.py` has the original checksum `8bd1a75cb0f1ad0555d2cf635853ae3804bfd67cf02333825874c6b4fee1736b`;
- `podman-hermes.service` and gateway readiness are healthy; and
- owner channel mentions still work while mention-free DMs return to the known blocked behavior.

No state restore or image mutation is required. Keep the downstream patch until a newly digest-pinned Hermes image contains equivalent authoritative classification and passes these same fixtures; then remove the source pin, package, patch, and file mount together.

## Risks and limits

- **CLI projection dependency:** classification relies on the pinned CLI's `channels search` and `channels members` outputs. The CLI and Hermes source are both pinned, and malformed output fails closed.
- **Discovery latency:** a transient metadata/member lookup failure leaves the conversation mention-gated until the next existing discovery cycle. It must not optimistically classify.
- **Metadata freshness:** membership is sampled during discovery. Exact event-author and allowlist checks prevent a cached non-owner author from dispatching; discovery should refresh the candidate record on the existing cadence and on membership events.
- **One-to-one scope:** group DMs intentionally remain mention-gated. Supporting them would require a separate access-policy decision.
- **Downstream maintenance:** the file-level patch must be revalidated for every Hermes image update. The source checksum guard prevents silently applying it to a different adapter.
- **Relay trust:** `channel_type` and membership come from the authenticated private relay's state. Compromise of that relay is outside this patch's threat boundary and already compromises channel ACLs and event delivery.

## Recommendation

Implement option A as the smallest complete interoperability fix. The decisive boundary is relay-authored `channel_type=dm`, reinforced by exact one-to-one membership and the existing owner allowlist. Do not patch only the sending CLI, do not disable channel mention gating, and do not modify the container image in place.
