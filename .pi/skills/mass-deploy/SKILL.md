---
name: mass-deploy
description: Use when a user requests a mass deploy, deploy everything or all remote hosts, a full fleet rollout, or a fleet-wide Colmena deployment of this NixOS repository.
---

# Mass Deploy

## Overview

Coordinate a health-gated NixOS fleet rollout with normal Pi subagents. The
coordinator delegates every operational action; fresh workers deploy exactly one
host at a time and a repaired problem always forces a clean pass from Stormwind.

**Core principle:** speed, maintenance-window pressure, and accepted risk never
weaken sequential applies, activation verification, whole-fleet health checks,
or truthful reporting.

## Coordinator and worker contract

The active parent agent is the coordinator. It MUST use the installed `subagent`
tool as follows:

- Launch `agent: "generalist"`, one fresh worker at a time. Never set model or
  thinking overrides, and never run two host workers concurrently.
- Give each worker a self-contained brief containing the absolute repository
  path, role, phase or host, `/tmp/pi-mass-deploy-state.json`, applicable
  references, constraints, and required report and terminal status.
- Wait for the automatic later message after each launch. Never poll, sleep,
  inspect session files, resume a completed child, or duplicate delegated work.
- Never run Colmena, SSH, health probes, repairs, or repository edits in the
  coordinator context. Workers keep that operational output isolated. The
  coordinator may read state and reports, validate a transition, launch the
  next worker, and issue the final summary.
- Treat a missing response, child loss, ambiguous status, malformed final line,
  or report/state disagreement as `ABORTED`. Do not infer success.

Every worker returns a concise evidence report and ends its final line with
exactly one status token from the status contract below.

## Shared state

Every invocation is a fresh run. The pre-flight worker MUST overwrite any stale
`/tmp/pi-mass-deploy-state.json` with at least:

```json
{
  "skippedHosts": [],
  "events": [],
  "restartCount": 0,
  "completedHostsThisPass": [],
  "containerPreview": [],
  "workaroundAudit": [],
  "finalHealth": null
}
```

Workers preserve all fields, update the file atomically (write valid JSON to a
temporary file in `/tmp`, then rename it), and append timestamped, auditable
events with phase, host when applicable, action, outcome, and evidence. Store
full preview, audit, repair, skip, restart, and endpoint results rather than only
summaries.

There is no mid-fleet resume. An interruption or lost child fails closed; a
later invocation starts over and pre-flight replaces stale `/tmp` state. Never
claim a successful resume from that file.

## Fixed order and targeting

Canonical order is:

`stormwind → ironforge → orgrimmar → anton → gnomeregan → headscale`

`headscale` is the gateway. For SSH reachability and deployment work, use these
`~/.ssh/config` aliases exactly. Never substitute raw IPs, FQDNs, `user@host`,
or explicit ports.

## Workflow

### 1. Pre-flight worker

The worker reads `.pi/skills/infrastructure/SKILL.md` and
`.pi/skills/infrastructure/references/host-mapping.md`, overwrites the state,
and does not deploy or repair anything.

1. Run `git status --porcelain` in the repository. Any untracked `*.nix` file is
   a blocker because a git+file flake cannot see it.
2. Confirm Colmena is available.
3. Probe every canonical SSH alias with BatchMode and a short timeout, for
   example `ssh -o BatchMode=yes -o ConnectTimeout=10 <alias> true`.
4. Record unreachable hosts in `skippedHosts` and events. They are skips, not
   blockers; Anton may be asleep.
5. Return `PREFLIGHT_BLOCKED` if every host is unreachable or any blocker
   remains. Otherwise return `PREFLIGHT_READY`.

On `PREFLIGHT_BLOCKED`, the coordinator stops and reports the blockers.

### 2. Container-upgrade preview worker

This phase is advisory: do not deploy or modify files.

- Inspect the old/new diffs for `apps/fetcher/containers.toml` and
  `apps/fetcher/containers-sha.nix` and account for every changed image.
- Classify each change as `major`, `ordinary`, or `unknown-version`. Obtain old
  and new release versions from OCI metadata when possible. A digest alone
  never proves a release version; `UNKNOWN VERSION` is not a major upgrade.
- For each known major change, name owning hosts and report the required
  migration, configuration, and secrets review. Preserve known metadata even
  when only one side's version is available.
- Store every result, including uncertainty or an empty preview, in
  `containerPreview`, append an event, and return `PREVIEW_COMPLETE`.
  Uncertainty is not a blocker.

### 3. Workaround-audit worker

Read and follow the infrastructure skill's **Workaround Hygiene** procedure.
This phase is advisory and performs no host apply.

- Only `WORKAROUND(` markers under `overlays/` are candidates for stock-package
  testing or removal. Mark entries elsewhere `manual` and leave them untouched.
- Prefer reachable Gnomeregan as the unstable builder, then Anton; honor
  `skippedHosts`. If neither is available, record the audit as skipped.
- Remove only overrides proven stale at the pinned revision. Update wiring,
  `git rm` deleted files, stage new files, and verify the consuming
  configuration. Keep uncertain or failed candidates.
- Store every `removed`, `kept`, `manual`, and `skipped` result in
  `workaroundAudit`, append an event, and return `AUDIT_COMPLETE`.

### 4. Sequential host loop

For every canonical slot, launch one fresh host worker, including hosts already
marked unreachable. Every host worker reads the infrastructure skill and host
mapping; the Gnomeregan worker also reads
`.pi/skills/infrastructure/references/gnomeregan.md`.

The worker follows this exact sequence:

1. Read state. If its host is already in `skippedHosts`, record the skip and
   return `SKIPPED_UNREACHABLE` without an apply.
2. Recheck its exact SSH alias. If newly unreachable, atomically add it to
   `skippedHosts`, record evidence, and return `SKIPPED_UNREACHABLE`.
3. Run exactly one `colmena apply --on <host> --impure` from the repository.
   Never use a comma-separated or all-host target.
4. Independently compare the active `readlink /run/current-system` with the
   built/pushed system path. Anton exit 4 may be a spurious dbus-broker timeout;
   generation equality, not the exit code alone, decides activation.
5. Diagnose and minimally repair a real eval, build, push, activation, or remote
   failure. Stage new repository files and never mask a failure. If another
   deployment is needed, verify the fix with
   `colmena build --on <owning-host> --impure`; do not perform a second or
   out-of-order apply. The restarted canonical pass performs it.
6. After a clean switch, first ensure local Tailscale is up, then verify every
   documented endpoint for every non-skipped host using the expected statuses
   in host mapping—not only this host's endpoints. Store complete results in
   `finalHealth`.
7. Diagnose root causes and re-probe for at most three heal rounds. A config fix
   needing deployment gets only a targeted build; the restarted pass applies
   it in order. Never fake a status, remove a check, or disable a service just
   to pass.
8. Atomically record the result and end with exactly one host status token.

Any repaired failure, any repository or remote-state change during the host
visit, any local probe-path recovery, or any endpoint heal MUST return
`FIXED_AFTER_FAILURE`, even when everything is healthy at the end.
`CLEAN_DEPLOYED` is reserved for a clean activation and healthy whole fleet
with no repair or state change. Unresolved failures, required manual action, or
heal exhaustion return `ABORTED`.

## Status and transition contract

A host worker commits the state mutation below before its final token. The
coordinator validates it and chooses the next action without applying it twice.

| Terminal status | Valid source | Required state and coordinator transition |
|---|---|---|
| `PREFLIGHT_READY` | Pre-flight | State initialized; launch preview. |
| `PREFLIGHT_BLOCKED` | Pre-flight | Stop as aborted; report blockers and manual action. |
| `PREVIEW_COMPLETE` | Preview | Preview persisted; launch workaround audit. |
| `AUDIT_COMPLETE` | Audit | Audit persisted; start the canonical host loop. |
| `CLEAN_DEPLOYED` | Host | Append the host to `completedHostsThisPass`; advance one slot. |
| `SKIPPED_UNREACHABLE` | Host | Ensure the host is in `skippedHosts`; exclude its endpoints and advance one slot. |
| `FIXED_AFTER_FAILURE` | Host | Increment `restartCount`, append repair/restart evidence, clear `completedHostsThisPass`; launch a fresh Stormwind worker. |
| `ABORTED` | Any worker | Stop immediately and preserve the exact stop point and next action. |

Only restart counts 1 through 3 may launch Stormwind. If a fourth restart is
required, record that fact and abort before launching another worker. A repaired
host never advances directly to the next host, and current health never waives
the restart.

## Final report

Before reporting success, validate state rather than relying on prose:

- `completedHostsThisPass` equals canonical order with `skippedHosts` removed;
- that pass occurred after the latest repair; and
- `finalHealth` covers every documented non-skipped endpoint and all expected
  statuses pass.

If any invariant fails, report `aborted`. Otherwise report `success` when no
host was skipped or `partial` when at least one host was unreachable. Include:

- overall status and canonical deployed order for the final clean pass;
- skipped hosts;
- container preview, including every unknown version;
- workaround audit results;
- failures, fixes, and the complete event timeline;
- exact `restartCount`;
- final per-endpoint health for every non-skipped host; and
- on abort, the exact stop point and next manual action.

## Quick reference

| Rule | Required behavior |
|---|---|
| Worker choice | Fresh `generalist`; one at a time; no model/thinking override |
| Applies | One host and one apply per worker, canonical order only |
| Health gate | Every documented endpoint for every non-skipped host after each clean switch |
| Any repair/change/heal | `FIXED_AFTER_FAILURE`; clear pass and restart at Stormwind |
| Restart limit | Three; a fourth required restart aborts |
| Unreachable host | Record, skip its endpoints, continue, final status `partial` |
| Child/status ambiguity | Fail closed as `ABORTED` |
| Resume | Never from stale `/tmp` state |

## Example

Orgrimmar's apply fails on a Nix error after Stormwind and Ironforge completed.
Its worker fixes the repository, stages a new file, and verifies
`colmena build --on orgrimmar --impure`; it does **not** apply again. It clears
`completedHostsThisPass`, changes `restartCount` from 0 to 1, appends the failure
and fix evidence, and ends:

`FIXED_AFTER_FAILURE`

The coordinator waits for that automatic response, validates state, and launches
a fresh Stormwind worker. It must not continue to Anton even if Orgrimmar and
all endpoints are now healthy.

## Red flags and common mistakes

| Pressure or shortcut | Required response |
|---|---|
| "Parallel is faster" or a short window | Never parallelize or use a comma-separated apply. |
| "The operator accepts the risk" | Keep every activation and fleet-health gate. |
| "The repair worked; continue" | Return `FIXED_AFTER_FAILURE` and restart at Stormwind. |
| "Check only the host just deployed" | Probe the whole non-skipped fleet. |
| "The digest changed, so this is vNext" | Report `UNKNOWN VERSION` without OCI release evidence. |
| "The old child probably succeeded" | Missing or malformed status is `ABORTED`; never resume or duplicate it. |
| "Make the check green" | Never fabricate 200s, remove checks, hide failures, or disable services. |

Also stop if the coordinator is about to run an operational command itself,
launch concurrent workers, poll a child, use a raw SSH target, continue after a
repair, perform a second apply in one host visit, or claim success from stale or
incomplete state.
