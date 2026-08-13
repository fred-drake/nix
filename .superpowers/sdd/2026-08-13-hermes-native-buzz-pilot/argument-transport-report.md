# Task 2 Argument Transport Hardening Report

## Status

Runbook defects corrected without deployment or live-state mutation. The production migration marker was not touched.

## Root cause

OpenSSH reconstructs the remote command as shell text. Passing baseline identifiers directly through `ssh ... /bin/sh -s -- "$value"` therefore did not preserve controller-side quoting; the remote login shell split provider/model/path values containing spaces and shifted positional arguments.

The guarded 0.17 rollback-health boundary also performed immediate health comparisons after activation. Dashboard startup could legitimately lag activation, causing a fail-closed rollback validation even when Hermes became ready shortly afterward.

## Changes

Changed `docs/superpowers/plans/2026-08-13-hermes-native-buzz-pilot.md` only:

- Base64-encodes every positional value in forward Step 6 and guarded 0.17 rollback health, then decodes each exact position remotely without `eval`; heredoc script delivery is unchanged.
- Rejects tab and newline bytes in every field before writing the mode-0600 baseline TSV.
- Captures baseline counts once so validation and emitted TSV values cannot diverge.
- Base64-hardens the Borg fallback archive-name boundary found by the Task 2 SSH argument audit; other Task 2 positional boundaries are constrained to numeric, digest, fixed-condition, or regex-validated no-space values.
- Adds a 120-attempt rollback readiness poll after exact activation/gate proof. It requires the Hermes service active, nonempty container version/schema responses, `gateway-default` supervised and up, and dashboard HTTP 302.
- On readiness timeout, asserts the marker still exists and exits before exact state/provider comparisons or Step 7 gate removal. Final exact service/version/schema/gateway/dashboard checks remain in place.

No credential values, status bodies, key material, or container environments are emitted by the changed boundaries.

## Verification performed

- All 15 Task 2 Bash fences parsed with `bash -n`.
- A synthetic `/bin/sh -s --` remote-command reconstruction fixture preserved exact forward (14), rollback (15), and Borg fallback (3) positional mappings with provider/model/path/archive names containing spaces.
- The TSV fixture accepted spaces and rejected tab/newline fields.
- Synthetic readiness fixtures covered success before the bound and timeout with the marker retained.
- `git diff --check` passed before report creation.
- `graphify update .` exited 0 and rebuilt the code graph (with its existing zero-node JSON warnings).

## Remaining concerns

- No SSH connection, deployment, service action, marker change, or live health probe was performed.
- The protected retry still requires independent clean review and must begin from the runbook's fresh preflight/evidence boundary. Step 7 must not run until the corrected rollback-health proof passes.

## Review fix round 1 — monotonic rollback readiness

Addressed the one Important finding in `argument-transport-review.md` without SSH access, deployment, service action, marker change, or other live mutation.

The guarded 0.17 rollback-health boundary now:

- derives a real 120-second deadline from Linux `/proc/uptime` rather than counting iterations;
- recalculates remaining time before every service, version, schema, gateway, dashboard, and sleep command;
- wraps external probes with GNU `timeout --signal=KILL` so a command cannot outlive its remaining allowance, while also applying curl connect and total timeouts;
- accepts readiness only for exact service `active`, Hermes `v0.17.0 (2026.6.19)` prefix, schema `(30, 30)`, gateway status beginning `up `, and dashboard HTTP 302;
- reasserts the exact marker inode on timeout before failing closed;
- after readiness, re-proves the exact current closure, marker inode, both effective unit conditions, `ConditionResult=no`, both vault units inactive, and the unchanged vault-writer timestamp before final health/state comparisons.

Verification for this round:

- all 15 Task 2 Bash fences parsed with `bash -n`;
- synthetic monotonic-deadline fixtures passed for readiness success and deadline failure;
- exact-value negative fixtures rejected Hermes 0.20, schema 33, gateway down, service activating, and dashboard HTTP 200;
- synthetic probe allowances remained positive and no larger than the configured deadline;
- `git diff --check` passed;
- `graphify update .` completed with the existing zero-node JSON warnings.

The production marker remains present and untouched by this documentation-only change. A protected retry still requires independent clean review before any gate removal.

## Guarded stale-marker continuation branch

Added an executable, two-mode Task 2 entry path without SSH access or live mutation.

- `PRIOR_EVIDENCE_DIR=''` selects fresh mode. It requires the marker absent, runs the current-key Git read/dry-run checks plus one successful vault-sync oneshot, rebuilds/activates the guarded 0.17 closure, then creates the marker exclusively at quiesce.
- An absolute `PRIOR_EVIDENCE_DIR` selects continuation mode. The documented current invocation names `/var/folders/f3/q3jm4tkn503425prctrd8pkw0000gn/T/hermes-v020-evidence.nuyljV`.
- Continuation parses only constrained prior closure, inode, writer timestamp, and quarantined-state evidence. It rejects missing, relative, malformed, or unexplained evidence.
- Before current-key Git `ls-remote` and push dry-run, continuation proves the exact guarded closure active; Hermes 0.17/schema 30; active service, running gateway, and dashboard 302; root-owned mode-0600 marker with the prior inode; both exact unit conditions with `ConditionResult=no` and inactive units; unchanged writer timestamp; and the exact quarantined failed-state directory.
- Continuation never removes, replaces, or overwrites the marker and never starts a vault unit or oneshot. It emits the freshly observed marker inode/writer timestamp, checks them against prior evidence, and records them in the new evidence directory.
- The guarded 0.17 build is repeated. Continuation requires its new closure path to equal the active prior guarded closure and re-proves the no-writer gate rather than reactivating it.
- The baseline is captured again, then the quiesce boundary branches: fresh creates the marker; continuation preserves the exact re-baselined marker. Both stop Hermes, adversarially prove both vault starts remain condition-skipped/no-exec, and create a new uniquely named schema-30 copy and fresh Borg archive while gated.

Synthetic fixtures cover fresh/continuation mode selection, relative/unknown/malformed prior-evidence rejection, exact marker/timestamp re-baselining, and fresh refusal of a pre-existing marker. All 15 Task 2 Bash fences parse with `bash -n`; `git diff --check` and `graphify update .` pass. The existing graphify zero-node JSON warnings remain.

The production marker and services were not touched. Independent review remains required before executing the continuation runbook or removing the gate.

## Continuation evidence authentication review fix

Addressed the continuation review Important without SSH access or live mutation.

- Continuation now accepts only the exact retained path `/var/folders/f3/q3jm4tkn503425prctrd8pkw0000gn/T/hermes-v020-evidence.nuyljV`; control bytes, arbitrary paths, and merely equivalent aliases are rejected.
- The path must canonicalize to that exact value and be a non-symlink directory owned by the current controller UID with mode 0700.
- Each consumed prior artifact (`guarded-017-closure`, `vault-gate-marker-inode`, and `vault-exec-timestamp`) must be a non-symlink regular file owned by the controller UID with mode 0600. Each is copied exactly once before SSH/live checks, source directory/file inodes and metadata are rechecked for substitution, and only the new copies are parsed afterward.
- Imported closure, inode, timestamp, pinned source path, and exact known quarantined path are validated as one newline-terminated value with fully anchored patterns. Imported evidence is made mode 0400; current re-baselined evidence remains mode 0600.
- Step 2 no longer rereads `PRIOR_EVIDENCE_DIR`; it consumes only `$EVIDENCE_DIR/prior-guarded-017-closure`.

Synthetic fixtures reject arbitrary and control-character paths, symlink directories/artifacts, wrong owner-mode contracts, missing/extra newlines, malformed values, and a source inode swap during copy. The valid import/re-baseline fixture passes. All 15 Task 2 Bash fences, `git diff --check`, and `graphify update .` pass; graphify retains its existing zero-node JSON warnings.

No production marker, service, evidence, or remote state was changed. Independent review is still required before continuation execution or gate removal.

## Fresh preflight isolation review fix

Moved `realpath -e` of the pinned retained evidence directory inside the exact continuation case. Fresh mode now classifies `PRIOR_EVIDENCE_DIR=''` and completes its local mode setup without checking whether the old attempt directory exists. All continuation path, canonicalization, ownership, mode, non-symlink, artifact, hash, newline, and imported-copy checks remain unchanged.

Synthetic verification covers fresh mode with the pinned prior directory absent, a valid authenticated continuation import, and continuation rejection for arbitrary paths, symlinks, wrong modes, malformed newline/value contracts, and source mutation. All 15 Task 2 Bash fences, `git diff --check`, and `graphify update .` pass; graphify retains its existing zero-node JSON warnings.

No live or prior evidence mutation was performed.
