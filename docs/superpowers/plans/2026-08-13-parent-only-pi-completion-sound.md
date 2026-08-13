# Parent-only Pi Completion Sound Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Play Herdr’s existing completion sound only when the parent Pi session finishes, not when a Pi subagent finishes.

**Architecture:** Herdr’s automatic sound for the `pi` agent type is muted because it cannot distinguish parent and child Pi sessions. A local Pi extension handles `agent_end`, ignores child sessions marked by `PI_SUBAGENT_NAME`, and asks Herdr to show a `done` notification for the parent session.

**Tech Stack:** Nix Home Manager, Pi TypeScript extensions, Herdr CLI.

## Global Constraints

- Keep the main session’s existing Herdr `done` sound.
- Do not emit a sound from sessions with `PI_SUBAGENT_NAME` set.
- Keep the change declarative through Home Manager.
- Do not run `just switch` without explicit authorization.

---

### Task 1: Add the parent-only notification extension

**Files:**
- Create: `apps/pi-extensions/parent-completion-notify.ts`
- Test: manual TypeScript syntax validation with Pi’s installed extension loader

**Interfaces:**
- Consumes: Pi’s `agent_end` extension event and `process.env.PI_SUBAGENT_NAME`.
- Produces: `herdr notification show "Pi ready" --sound done` only from the parent Pi session.

- [ ] **Step 1: Write the failing behavioral check**

Run the notifier condition under a child environment. The expected result is that the extension’s condition prevents invoking Herdr:

```sh
PI_SUBAGENT_NAME=worker node -e 'if (!process.env.PI_SUBAGENT_NAME) process.exit(1)'
```

- [ ] **Step 2: Verify the child condition is recognized**

Run the command above. Expected: exit 0 because a child session is detected.

- [ ] **Step 3: Write the minimal extension**

```ts
import { execFile } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("agent_end", () => {
    if (process.env.PI_SUBAGENT_NAME) return;
    execFile("herdr", ["notification", "show", "Pi ready", "--sound", "done"]);
  });
}
```

- [ ] **Step 4: Validate the extension loads**

Run:

```sh
pi --help
```

Expected: exit 0 with no extension-load error.

- [ ] **Step 5: Commit**

```sh
git add apps/pi-extensions/parent-completion-notify.ts
git commit -m "feat(pi): notify only when parent session completes"
```

### Task 2: Mute Herdr’s automatic Pi sounds

**Files:**
- Modify: `modules/home-manager/features/ai-tools.nix`
- Test: `nix eval` of the Home Manager configuration

**Interfaces:**
- Consumes: Herdr’s `[ui.sound.agents]` per-agent sound configuration.
- Produces: automatic sounds disabled for every Pi session, leaving Task 1 as the sole source of the parent completion sound.

- [ ] **Step 1: Write the failing configuration check**

Confirm the generated Herdr configuration does not yet include the Pi mute rule:

```sh
rg -n '^pi = "off"$' modules/home-manager/features/ai-tools.nix
```

Expected: exit 1.

- [ ] **Step 2: Add the minimal Herdr rule**

Append to the existing Home Manager-generated Herdr configuration:

```toml
[ui.sound.agents]
pi = "off"
```

- [ ] **Step 3: Verify the rule is present**

Run:

```sh
rg -n -A1 '^\[ui\.sound\.agents\]$' modules/home-manager/features/ai-tools.nix
```

Expected: the following line is `pi = "off"`.

- [ ] **Step 4: Evaluate the Home Manager configuration**

Run:

```sh
nix eval .#homeConfigurations.macbook-pro.activationPackage.drvPath
```

Expected: exit 0.

- [ ] **Step 5: Commit**

```sh
git add modules/home-manager/features/ai-tools.nix
git commit -m "fix(herdr): mute automatic Pi completion sounds"
```
