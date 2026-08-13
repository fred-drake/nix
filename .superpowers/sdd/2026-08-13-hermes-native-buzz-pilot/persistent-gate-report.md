# Persistent Hermes vault-writer gate report

Date: 2026-08-13

## Status

Implemented and locally/target-build verified. No deployment, activation, service operation, inhibit-marker creation, state move, backup, or other live-state mutation was performed.

## Decision implemented

`modules/services/hermes.nix` now permanently adds this inert-by-default condition to both generated units:

```ini
ConditionPathExists=!/var/lib/hermes-migration/vault-sync.inhibit
```

The marker is outside `/var/hermes`, so a migration restore or rename cannot remove it. With the marker absent, normal synchronization is unchanged. With a persistent root-owned marker present, both the timer and direct oneshot start are condition-skipped.

This implements the safer independent-review design rather than the temporary `system.control` drop-in design. No runtime mask or mutable systemd override remains in the Task 2 retry runbook.

## Files changed

- `modules/services/hermes.nix`
  - Added one permanent marker path constant.
  - Added the same `unitConfig.ConditionPathExists` to `hermes-vault-sync.timer` and `hermes-vault-sync.service`.
- `docs/superpowers/plans/2026-08-13-hermes-native-buzz-pilot.md`
  - Replaced Task 2's runtime-mask workflow with the persistent declarative gate workflow.
  - Preserved Gitea authorization, state/provider baselines, local and Borg backups, dogfood relocation, 0.20 migration validation, controlled-stop validation, and rollback state/health checks.
- `.superpowers/sdd/2026-08-13-hermes-native-buzz-pilot/persistent-gate-report.md`
  - This implementation and verification report.

## Task 2 runbook changes

### Guarded rollback closure before quiesce

The runbook now captures the running 0.17 image digest, creates a detached temporary Git worktree at the reviewed 0.20 branch commit, and changes only the temporary worktree's image and OCI user setting. This preserves the 0.20 working state.

It then:

1. evaluates the service and timer condition values;
2. builds a guarded 0.17 Orgrimmar closure;
3. extracts and records exactly one non-derivation system closure path;
4. inspects both generated unit fragments for the exact condition;
5. activates that exact guarded 0.17 closure while the marker is absent;
6. proves 0.17/schema 30 health and one successful normal vault-sync oneshot;
7. starts the normal timer; and
8. removes the temporary worktree without changing branches.

The recorded closure path is the only permitted rollback activation target. Historical unguarded generations and inferred generation numbers are explicitly rejected.

### Guarded 0.20 target before quiesce

The runbook evaluates both Nix option values, builds only Orgrimmar, records exactly one target closure, and inspects both generated unit fragments for the exact condition before downtime.

### Persistent protected boundary

The runbook now:

1. aborts on a stale marker;
2. creates `/var/lib/hermes-migration/vault-sync.inhibit` before stopping, root-owned and mode 0600 under a root-only directory;
3. stops Hermes and both vault units;
4. records `ExecMainStartTimestampMonotonic`;
5. runs `systemctl daemon-reload`;
6. adversarially starts both timer and service;
7. requires each effective unit to contain the exact condition;
8. requires `ConditionResult=no` and inactive state for both units;
9. requires the writer execution timestamp to remain unchanged; and
10. requires the marker inode to persist before state copying begins.

There is no failure or `EXIT` path that removes the marker. A stale marker fails safe.

### Forward activation

The marker stays present through activation. Before migration, provider, state, dashboard, or controlled-stop validation, the runbook requires:

- `/run/current-system` equals the exact inspected 0.20 target closure;
- the marker inode, ownership, and mode are unchanged;
- both effective units contain the exact condition;
- adversarial starts produce `ConditionResult=no` and inactivity; and
- the writer execution timestamp remains equal to its pre-activation value.

### Rollback

Both local-copy and Borg recovery paths keep the marker present and all writers stopped while restoring and proving the captured config digest and schema 30 with the captured 0.17 image.

Only after that proof does the runbook activate the exact recorded guarded 0.17 closure. Its first post-activation boundary proves the marker, both effective conditions, `ConditionResult=no`, unit inactivity, and unchanged writer execution timestamp before checking 0.17 version/schema, dashboard, provider/model health, and all recorded state counts.

### Deliberate completion

After successful 0.20 validation or healthy guarded 0.17 rollback, the runbook deliberately removes only the marker, runs and verifies one vault-sync oneshot, and then starts the timer. The permanent declarative conditions remain.

The completion trap never removes the marker. It only recreates the marker and stops both vault units if the controlled oneshot/timer reopening sequence is interrupted or fails.

## Contract and build evidence

### Red/green option contract

Before implementation, targeted evaluation failed because `ConditionPathExists` was absent from `hermes-vault-sync.service`.

After implementation, targeted evaluation returned:

```json
{"service":"!/var/lib/hermes-migration/vault-sync.inhibit","timer":"!/var/lib/hermes-migration/vault-sync.inhibit"}
```

### Targeted Orgrimmar build

`colmena build --on orgrimmar --impure` exited 0 and built:

```text
/nix/store/qcvgz6hgpmv0psfxjqsifscnjvipvqjy-nixos-system-orgrimmar-25.05pre-git
```

Read-only inspection of that built closure on Orgrimmar resolved both generated fragments and found exactly:

```text
hermes-vault-sync.timer:   ConditionPathExists=!/var/lib/hermes-migration/vault-sync.inhibit
hermes-vault-sync.service: ConditionPathExists=!/var/lib/hermes-migration/vault-sync.inhibit
```

The system was not activated.

## Verification performed

- `alejandra modules/services/hermes.nix`: passed.
- `statix check modules/services/hermes.nix`: passed.
- Targeted `colmena eval --impure` for both condition values: passed.
- `colmena build --on orgrimmar --impure`: passed.
- Read-only generated-unit inspection in the built Orgrimmar closure: passed for both units.
- All 15 Task 2 `bash` fences extracted and parsed with `bash -n`: passed.
- Task 2 static assertions reject runtime masks, `system.control`, unmask cleanup, and old `/run/systemd/system` vault-mask checks: passed.
- `git diff --check`: passed.
- `graphify update .`: exited 0 and rebuilt the code graph (1829 nodes, 1692 edges, 154 communities); it warned that six source files produced zero nodes.

## Remaining concerns

1. The guarded 0.17 closure procedure is intentionally operational and cannot be fully exercised without building and activating against the live 0.17 state. The runbook requires exact generated-unit inspection and health proof before quiesce.
2. Condition-skipped starts can return success; the runbook therefore relies on `ConditionResult=no`, inactivity, exact effective conditions, and unchanged execution evidence rather than command status.
3. A stale marker intentionally disables vault synchronization. Operators must inspect it as unresolved migration state rather than deleting it automatically.
4. The gate covers the systemd-managed timer and oneshot, not a manual root process writing directly into `/var/hermes/vault`. The existing explicit writer inventory and stop boundary remain required.
5. The targeted build copied build artifacts to Orgrimmar's Nix store but did not activate them or mutate service/state configuration.
