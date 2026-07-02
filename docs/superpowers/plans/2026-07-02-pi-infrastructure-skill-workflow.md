# Pi Infrastructure Skill + Workflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expose the local `infrastructure` Claude skill and `colmena-deploy` workflow to pi using the pi dynamic workflows plugin.

**Architecture:** Use `apps/agent-common/` as the shared source for cross-agent workflow assets. Pi's existing Home Manager activation already transcodes `apps/agent-common/workflows/*.js` into `~/.pi/workflows/saved/*.json`; add the Colmena deploy workflow there and install the infrastructure skill into pi from a shared skill directory.

**Tech Stack:** Nix Home Manager, pi skills, pi dynamic workflows, JavaScript workflow files, git-tracked flake inputs.

## Global Constraints

- New files referenced by the Nix flake must be staged with `git add` before Nix can see them.
- Full-fleet deployments must continue to use the `colmena-deploy` workflow, not ad-hoc parallel `colmena apply`.
- Keep the existing Claude skill content and references intact unless updating Claude-specific invocation text to pi equivalents.
- Run `graphify update .` after modifying code/content in this repository.

---

## File Structure

- `apps/agent-common/skills/infrastructure/`: shared canonical infrastructure skill directory, copied from `.claude/skills/infrastructure/` and edited to mention pi workflow invocation.
- `apps/agent-common/workflows/colmena-deploy.js`: shared workflow source copied from `.claude/workflows/colmena-deploy.js`; Home Manager already converts this to a pi saved workflow.
- `modules/home-manager/features/pi.nix`: install/symlink the shared infrastructure skill into `~/.pi/agent/skills/infrastructure`.
- `.claude/skills/infrastructure/` and `.claude/workflows/colmena-deploy.js`: left in place for current Claude compatibility in this task.

### Task 1: Add shared infrastructure assets

**Files:**
- Create: `apps/agent-common/skills/infrastructure/SKILL.md`
- Create: `apps/agent-common/skills/infrastructure/references/gnomeregan.md`
- Create: `apps/agent-common/skills/infrastructure/references/hearthstone-dns.md`
- Create: `apps/agent-common/skills/infrastructure/references/host-mapping.md`
- Create: `apps/agent-common/workflows/colmena-deploy.js`

**Interfaces:**
- Consumes: existing Claude skill and workflow files.
- Produces: shared skill directory and workflow file consumed by Home Manager pi feature.

- [ ] Copy `.claude/skills/infrastructure/` to `apps/agent-common/skills/infrastructure/`.
- [ ] Copy `.claude/workflows/colmena-deploy.js` to `apps/agent-common/workflows/colmena-deploy.js`.
- [ ] Edit the copied `SKILL.md` so full-fleet deployment says pi invokes `/colmena-deploy` via the pi workflows plugin, with source at `apps/agent-common/workflows/colmena-deploy.js`.
- [ ] Verify the workflow still starts with `export const meta = { ... }` and includes `agent()` calls.

### Task 2: Wire shared skill into pi

**Files:**
- Modify: `modules/home-manager/features/pi.nix`

**Interfaces:**
- Consumes: `apps/agent-common/skills/infrastructure`.
- Produces: `~/.pi/agent/skills/infrastructure` managed by Home Manager.

- [ ] Add a `home.file` entry for `.pi/agent/skills/infrastructure` pointing at `../../../apps/agent-common/skills/infrastructure` with `recursive = true`.
- [ ] Keep existing skill settings unchanged; user-level `~/.pi/agent/skills` discovery handles this skill.

### Task 3: Validate and stage

**Files:**
- Modify: git index for new shared files.

**Interfaces:**
- Consumes: tasks 1 and 2 outputs.
- Produces: git-tracked files visible to the flake.

- [ ] Run `nix eval .#homeConfigurations.fdrake.activationPackage.drvPath` or a narrower parse/eval check if available.
- [ ] Run `git add apps/agent-common/skills/infrastructure apps/agent-common/workflows/colmena-deploy.js modules/home-manager/features/pi.nix docs/superpowers/plans/2026-07-02-pi-infrastructure-skill-workflow.md`.
- [ ] Run `graphify update .`.
- [ ] Report changed paths and any validation caveats.
