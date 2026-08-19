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

## Workflow

### 1. Update

Launch a fresh **update executor** to run `just update-all` once. It may inspect state but cannot edit, remediate, or retry. Require exit status, changed files, and relevant output.

On failure, launch a fresh **update remediator** to diagnose, minimally fix, and run targeted checks—never either deployment command. Stop for credentials, destructive actions, or user decisions; otherwise use a fresh update executor. Repeat until success. Never switch after a failed update.

### 2. Switch

After update success, launch a fresh **switch executor** to run `just switch` once. It cannot edit, remediate, or retry and returns the same report.

On failure, use a fresh **switch remediator**, then a fresh switch executor. Apply the same constraints and repeat until success or a user blocker.

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
