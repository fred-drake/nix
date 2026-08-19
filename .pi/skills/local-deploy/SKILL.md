---
name: local-deploy
description: Use when updating this repository's Nix inputs, pins, GitHub revisions, or dependencies and deploying them locally, especially for local deploy, update-all, or switch requests.
---

# Local Deploy

## Overview

Use two serial gates. The parent coordinates; each attempt and remediation gets a fresh `generalist` subagent. Do not use Anvil. Work in `/Users/fdrake/nix`; never prefix `just` with `sudo`.

## Worker Contract

- Call `subagent` with `agent: "generalist"` and no model/thinking overrides. Launch one at a time; await its later message without polling, resuming, or duplicating work.
- Brief each child with the repository, role, latest failure, constraints, and report format.
- The parent never runs commands, investigates, edits, or repairs.
- Preserve the active worktree and partial updates. Never reset, clean, restore, checkout, stash, create a replacement worktree, or commit without user approval.

## Workflow

### 1. Update phase

Launch a fresh **update executor** to run `just update-all` to completion. It may inspect state but cannot edit, remediate, or retry. Require exit status, changed files, and relevant output.

On failure:

1. Launch a fresh **update remediator** with that report. It diagnoses, minimally fixes, and runs targeted checks, but never `just update-all` or `just switch`.
2. Stop if it reports missing credentials, a destructive action, or a user decision.
3. Otherwise launch a fresh update executor. Repeat until success.

Never switch after a failed update attempt.

### 2. Switch phase

After update success, launch a fresh **switch executor** to run `just switch`. It cannot edit, remediate, or retry and returns the same report.

On failure, launch a fresh **switch remediator** to diagnose, minimally edit, and run targeted checks—never either deployment command. Then use a fresh switch executor. Repeat until success or a user-blocking condition.

### 3. Completion

Claim success only after fresh executors report successful exits for both commands. Summarize attempts, remediations, changed files, and concerns.

## Roles

| Role | May do | Must not do |
|---|---|---|
| Executor | Run one `just` command; report | Edit, remediate, retry |
| Remediator | Diagnose, minimally fix, targeted checks | Run deployment commands |
| Parent | Launch, await, relay, summarize | Run commands, investigate, edit |

## Example

`update executor A` fails → `update remediator B` fixes → `update executor C` succeeds → `switch executor D` fails → `switch remediator E` fixes → `switch executor F` succeeds.

## Red Flags and Common Mistakes

| Temptation | Required response |
|---|---|
| “The executor already knows the fix.” | End its role; launch a fresh remediator, then a fresh executor. |
| “The remediator can save time by retrying.” | It cannot; launch a new executor for every attempt. |
| “Most updates worked, so switch now.” | Keep the phase gate closed until all of `just update-all` succeeds. |
| “Reset partial output and start clean.” | Preserve the active worktree and repair in place. |
| “Retry the identical blocker again.” | Stop for credentials, safety approval, or the missing user decision. |
