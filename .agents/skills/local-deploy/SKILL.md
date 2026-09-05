---
name: local-deploy
description: Use when updating this repository's Nix inputs, pins, GitHub revisions, or dependencies and deploying them locally, especially for local deploy, update-all, or switch requests.
---

# Local Deploy

## Overview

Run update, switch, then commit through fresh `generalist` subagents. The parent only coordinates. Do not use Anvil. Work in `/Users/fdrake/nix`; never prefix `just` with `sudo`.

## Contract

- Call `subagent` with `agent: "generalist"` and no model/thinking overrides. Launch one child at a time and await its later message without polling, resuming, or duplicating work.
- Give each child a self-contained brief with repository, role, latest failure, constraints, and report format.
- The parent never runs commands, investigates, edits, or repairs.
- Never reset, clean, restore, checkout, stash, or create another worktree. Only the commit executor may stage or commit. Never push.

## Async Result Recovery

Subagent delivery state and command state are separate.

- A missing later message does not prove whether the child is running or exited. The parent must not claim a status, poll, resume, kill, overlap another child, or retry. State that the result is pending and wait.
- If the harness explicitly reports a delivery or surface failure after launch, treat the command outcome as unknown—not failed. Only then, launch a fresh **result remediator** for that phase. This read-only diagnostic is the sole exception to the one-child rule after the harness has declared the tracked child failed. It may inspect the prior transcript, process tree, repository, and system state, but cannot run deployment commands or edit.
- If the command is still active, the result remediator reports and exits; the parent stops for user intervention rather than launching repeated diagnostics. If it finished with a recoverable exit status, continue from that result.
- An absent process does not prove success or failure. If the exit status cannot be recovered, stop with the outcome unknown. Never retry because of a callback failure alone.

## Workflow

### 1. Update

Launch a fresh **update executor** to run `just update-all` once. It may inspect state but cannot edit, remediate, or retry. Require exit status, changed files, and relevant output.

On failure, launch a fresh **update remediator** to diagnose, minimally fix, and run targeted checks—never either deployment command. Stop for credentials, destructive actions, or user decisions; otherwise use a fresh update executor. Repeat until success. Never switch after a failed update.

### 2. Switch

After update success, launch a fresh **switch executor** to run `just switch` once. It cannot edit, remediate, or retry and returns the same report.

On failure, use a fresh **switch remediator**, then a fresh switch executor. Apply the same constraints and repeat until success or a user blocker. The remediator must identify partial activation and confirm no switch, package-manager process, or active lock remains before authorizing a retry. For transient downloads or locks, prefer a safe retry after the blocker clears. The remediator never deletes package-manager locks or manually upgrades packages; if either appears necessary, stop for a user decision.

### 3. Commit everything

After switch success, launch a fresh **commit executor** to run exactly:

```bash
git add -A
git commit -m "chore: update local configuration"
```

This intentionally commits every outstanding staged, unstaged, and untracked change, including pre-existing changes. It cannot edit, push, or retry. Nothing to commit is a successful no-op.

On failure, use a fresh **commit remediator** for the smallest fix; it cannot commit or deploy. Then use a fresh commit executor. Repeat until success or a user blocker.

### 4. Complete

Claim success only after both deployment commands and the commit phase succeed. Report attempts, remediations, commit SHA, and concerns.

## Quick Reference

| Phase | Fresh executor action |
|---|---|
| Update | `just update-all` |
| Switch | `just switch` |
| Commit | `git add -A` then one Conventional Commit |
| Failure | Fresh remediator, then fresh executor |

## Example

`update executor A` succeeds → `switch executor B` succeeds → `commit executor C` commits everything outstanding.

## Common Mistakes

| Temptation | Required response |
|---|---|
| Reuse an executor for a fix/retry | Launch fresh remediator and executor. |
| Switch after a partial update | Wait for all of `just update-all`. |
| Preserve changes that predate deployment | Commit them; commit means everything outstanding. |
| Push the commit | Do not push unless separately requested. |
| Treat a callback error as command failure | Recover the actual command outcome first. |
| Infer running or exited from silence | Report the status as unknown and wait. |
| Delete a package lock after switch failure | Never delete it; check for a holder and stop for the user if it does not clear. |
