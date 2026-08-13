# Hermes 0.20 validation runbook correction report

## Status

Task 2's validation contract was corrected without SSH access, deployment, service mutation, or production-state access. The retry is explicitly fresh-only from the current guarded Hermes 0.17/schema-30 state.

## Corrections

- Replaced backup mtime selection with strict parsing of `config.yaml.bak-YYYYMMDDTHHMMSSZ[.N]` and `.env.bak-YYYYMMDDTHHMMSSZ[.N]`. A backup qualifies only when its canonical encoded UTC epoch and ctime are both greater than the quiesce epoch. Fresh malformed candidates fail closed, at least one file of each type is required, and only filenames are emitted.
- Added a portable Step 6 `EXIT` cleanup/failure trap and 16 static assertion-group labels. A failure now emits exactly `validation_failed_step=<static> rc=<n>` without commands, values, environment, or secret material.
- Added a mode-0600 journal cursor artifact immediately before forward 0.20 activation. Step 6 transports it with the existing base64 boundary, inspects the complete `journalctl --after-cursor` slice for forbidden errors, and retains at most 150 diagnostic lines. It no longer reads latest/history lines.
- Aligned controlled stop with the exact image's mature direct-SIGTERM contract: ordered current-only SIGTERM/s6 context and `Gateway stopped`; ordered `asyncio.run.returned success=false` then `gateway.exit_nonzero`; lifecycle `phase=exited`, `exit_reason=graceful_shutdown`, and intentional `exit_code=1`; complete static s6 stops; and no SIGKILL, 137, or OOM. Code 1 is accepted only with every graceful marker, never by itself or from container exit status.
- Added a pre-stop gate that waits until the exact image's short-lived startup planned-stop marker no longer targets the gateway PID. This prevents a newly started disposable/runtime gateway from taking the planned-stop code-0 path when Task 2 intends to test direct SIGTERM.
- Forced the documented retry entry to `PRIOR_EVIDENCE_DIR=''`, added an immediate active Hermes 0.17/schema-30 proof, and prohibited reuse of prior evidence, rollback copies, Borg archives, or quarantined schema-33 trees.

## Verification

- Extracted all 16 Task 2 Bash fences and parsed each with `bash -n`: passed.
- Backup fixtures: copied-preserved old mtimes with fresh strict names passed for both config and environment backups; `.N` suffix passed. Fresh malformed names, encoded timestamps before quiesce, and ctimes before quiesce were rejected.
- Portable static-label fixture: `/bin/sh` emitted one exact `validation_failed_step=backup_config_freshness rc=1` line and no command/value output.
- Cursor-scope fixtures: the journal stub required the exact `--after-cursor` argument, accepted 200 clean attempt lines while retaining 150, and rejected a forbidden line outside the retained tail but inside the attempt slice.
- Controlled-stop synthetic fixtures: the exact code-1/nonzero graceful marker set passed; code 0, clean-exit diagnostics, OOM, and incomplete static teardown were rejected.
- Exact image digest `sha256:c0cab4e3711bcb27a312be1b3776254fc06fd50d5f7a6b8017915fc7171cb39e` was tested only with disposable Podman names/volumes, dummy non-production values, and `--network=none`. An immediate fresh stop reproduced the short-lived planned-marker code-0 path. After the marker ceased targeting the gateway, the exact image reproduced `success=false`, `gateway.exit_nonzero`, lifecycle code 1/graceful shutdown, no OOM/SIGKILL/137, and every required static s6 stop. The minimal no-channel fixture did not write the three gateway text markers to its persistent `current` log, so the full production-shaped current-log assertion remains covered by the diagnosed retained attempt and the synthetic ordering fixture rather than a passing no-channel disposable check.
- `alejandra --check modules/services/hermes.nix`: passed.
- `statix check modules/services/hermes.nix`: passed.
- `git diff --check`: passed before final graph/report refresh.

## Remaining concern

No live retry was run. The no-channel exact-image fixture cannot stand in for the production-shaped gateway log path, although it independently confirmed the intentional direct-signal exit diagnostics, lifecycle code, OOM state, and static teardown. A reviewed retry must still begin from a new evidence directory and fresh schema-30 quiesce boundary and must fail closed if any required current gateway marker is absent.

## Review fix round 1 — auto-removal and indivisible backup names

Addressed both findings in `validation-contract-review.md` without SSH access, deployment, or live-state mutation.

- Removed the post-stop `podman inspect hermes .State.OOMKilled` assertion, which cannot work after the production `--rm` container is auto-removed.
- Before stopping, the controlled-stop gate now records the exact 64-hex container ID, service journal cursor, and a nanosecond Podman-event lower timestamp. After stop and before restart, it queries only events for that ID through an immediate upper timestamp. It requires one `died` event with outer code 0, rejects every OOM/kill event and code 137, requires the old name absent, and retains the cursor-scoped journal rejection of SIGKILL, kill escalation, 137, and OOM. Restart then creates a new container and reaches the existing gateway/runtime/lifecycle readiness proof.
- Backup validation now byte-counts each whole basename and rejects every C0 control byte and DEL before the anchored C-locale regex, timestamp extraction, or output. Therefore a qualifying name is one indivisible, printable, single-line basename and emitted evidence cannot become multiline.

Round-1 verification covered all 16 Task 2 Bash fences, representative copied-preserved mtimes, malformed timestamps/suffixes, newline/tab/carriage-return/escape/DEL names, and one-line filename-only output. A disposable `--rm` Podman fixture proved that ID-scoped events survive removal, the clean event set passes, an injected current-ID OOM/137 event fails, the old name is absent, and a new container with that name reaches running readiness. Alejandra, Statix, `git diff --check`, and `graphify update .` were rerun.

## Review fix round 2 — controlled-stop evidence source and observability

Applied `controlled-stop-diagnosis.md` without SSH access, deployment, or live-state mutation.

- Changed only the load-bearing gateway marker source from stdout-only `logs/gateways/default/current` to central Python logger output `logs/gateway.log`. Inode, size, no-rotation/no-truncation, appended-byte slicing, and ordered current-slice marker assertions remain intact.
- Added the specified 28 static controlled-stop/restart labels and a portable `EXIT` trap. It preserves the original status, removes only its disposable `/run/hermes-v020-stop.*` directory, never restarts a service or changes the migration marker, and emits only `controlled_stop_failed_step=<static> rc=<n>`.
- Tightened auto-removal proof to the captured old container ID rather than the reusable `hermes` name.

Verification included all Task 2 Bash fences; failure-label fixtures at stop, event, and restart groups; central-log versus stdout-current sink fixtures; inode/growth/current-slice ordering and rotation failure; and a disposable auto-remove success path proving old-ID absence, new-ID creation, and restart readiness. Exact-image/source diagnosis establishes that central `gateway.log` is the Python INFO/WARNING marker sink while dynamic s6 `current` receives stdout only. Alejandra, Statix, `git diff --check`, and `graphify update .` were rerun.

## Review fix round 3 — exit diagnostic JSON parsing

Changed only the controlled-stop `asyncio.run.returned` pattern to require the actual JSON boolean syntax: `"success"[[:space:]]*:[[:space:]]*false`. The separate `gateway.exit_nonzero` match, appended-byte current slice, presence checks, ordered line comparison, and `stop_exit_marker_order` failure label are unchanged.

The exact retained two-line appended slice now passes with returned/nonzero lines 1 and 2. Fixtures reject `true`, a missing returned marker, reversed markers, and a valid stale prefix excluded by the recorded byte offset. All 16 Task 2 Bash fences, `git diff --check`, and `graphify update .` were rerun without live mutation.

## Review fix round 4 — coherent gateway exit variants

Replaced the serialization-dependent exit greps and hard-coded lifecycle code 1 with one `jq` contract over the current NDJSON slice and lifecycle JSON. It requires exactly one boolean `asyncio.run.returned`, exactly one clean or nonzero exit record, returned-before-exit ordering, one PID shared by both records and lifecycle, and an exited/graceful lifecycle. It accepts only `true + gateway.exit_clean + code 0` or `false + gateway.exit_nonzero + code 1`.

The later lifecycle group now reasserts only the already-coherent allowed phase/reason/code range instead of contradicting the tuple check. Gateway SIGTERM/context/teardown ordering, event and no-kill/OOM gates, complete static s6 teardown, failure labels, and restart readiness remain unchanged.

Fixtures passed against the exact latest retained true/clean/code-0 slice and earlier false/nonzero/code-1 slice. Negative fixtures reject duplicate or missing records, non-boolean success, reversed or mixed markers, record/lifecycle PID mismatch, and lifecycle code/reason/phase mismatch. All Task 2 Bash fences, `git diff --check`, and `graphify update .` were rerun without live mutation.

## Review fix round 5 — strict exit-record schemas and neutral evidence

The jq contract now collects every `asyncio.run.returned` tag before enforcing exactly one record, then validates that record's present boolean `success` and positive integer PID. It independently requires exactly one clean/nonzero exit tag with a positive integer PID and a present positive integer lifecycle PID before applying same-PID, ordering, lifecycle, and coherent-tuple checks. A valid record can no longer hide a malformed duplicate, and missing/null/string/zero/fractional/negative PIDs fail closed.

Successful summaries are now neutral static evidence: one coherent ordered exit variant and a running-to-exited graceful lifecycle with the corresponding coherent code. They no longer contradict the accepted clean/code-0 variant.

Fixtures accept both positive variants and reject malformed duplicate valid+nonboolean records, duplicate/missing records, missing/null/string success, every missing/null/string/zero/fractional/negative PID position, reversed or mixed markers, and lifecycle code/reason mismatch. All Task 2 Bash fences, `git diff --check`, and `graphify update .` were rerun without live mutation.
