# Remove cmux Agent Integrations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove cmux-specific Pi and Claude Code integrations while retaining standalone cmux workstation configuration.

**Architecture:** Delete the Pi and Claude Code wiring that exposes cmux behavior, remove its declarative fetcher entry, and delete local sources that become unreferenced. The Home Manager cmux feature and shell configuration are out of scope.

**Tech Stack:** Nix flakes, Home Manager, TOML.

## Global Constraints

- Do not modify standalone cmux application, feature, or shell configuration.
- Keep changes limited to agent integrations and their orphaned local sources.

---

### Task 1: Remove declarative agent integration wiring

**Files:**
- Modify: `modules/home-manager/features/pi.nix`
- Modify: `modules/home-manager/features/claude-code.nix`
- Modify: `apps/fetcher/claude-plugins.toml`

- [ ] Remove Pi’s cmux skill path, extension symlink, and cmux subagent skill symlink.
- [ ] Remove Claude Code’s cmux wrapper/filter definitions and select the direct Claude binary.
- [ ] Remove the opt-in Claude cmux plugin declarations and the `cmux-src` fetcher entry.
- [ ] Evaluate the affected Home Manager configuration.

### Task 2: Delete orphaned Pi cmux sources

**Files:**
- Delete: `apps/pi-extensions/cmux-session.ts`
- Delete: `apps/pi-skills/cmux-pi-subagent/`

- [ ] Delete the sources no longer referenced by the configuration.
- [ ] Search the configuration for residual Pi/Claude references to these removed paths.

### Task 3: Verify and commit

**Files:**
- Modify: `docs/superpowers/specs/2026-03-30-remove-cmux-agent-integrations-design.md`
- Create: `docs/superpowers/plans/2026-03-30-remove-cmux-agent-integrations.md`

- [ ] Format modified Nix files with `alejandra`.
- [ ] Run a targeted Nix evaluation/build check and inspect the final diff.
- [ ] Commit all changes with a Conventional Commit message.
