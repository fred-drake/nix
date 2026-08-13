# Pi Input-needed Chime Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Play Herdr’s request sound when the main Pi session shows an `ask_user_question` questionnaire.

**Architecture:** The existing parent-only notifier subscribes to the question extension’s `rpiv:ask-user:prompt` event. It sends a Herdr `request` notification for the parent session only; child sessions remain entirely inert. Existing completion behavior remains unchanged.

**Tech Stack:** Pi TypeScript extensions, Herdr CLI.

## Global Constraints

- Only the parent Pi session may play sounds.
- Questions play Herdr’s `request` sound; completed parent turns play `done`.
- Preserve the existing subagent-spawn suppression.
- Do not modify Herdr configuration or run `just switch`.

---

### Task 1: Add the questionnaire attention handler

**Files:**
- Modify: `apps/pi-extensions/parent-completion-notify.ts`

**Interfaces:**
- Consumes: the question package event `rpiv:ask-user:prompt`.
- Produces: `herdr notification show "Pi needs input" --sound request` in parent sessions only.

- [ ] **Step 1: Write a failing source assertion**

Verify the notifier does not yet subscribe to the question event:

```sh
rg 'rpiv:ask-user:prompt' apps/pi-extensions/parent-completion-notify.ts
```

Expected: exit 1.

- [ ] **Step 2: Add the minimal event handler**

Add this parent-session event listener beside the existing Pi listeners:

```ts
pi.events.on("rpiv:ask-user:prompt", () => {
  execFile("herdr", ["notification", "show", "Pi needs input", "--sound", "request"]);
});
```

- [ ] **Step 3: Verify source behavior and extension loading**

Run:

```sh
rg -F 'pi.events.on("rpiv:ask-user:prompt"' apps/pi-extensions/parent-completion-notify.ts
rg -F 'execFile("herdr", ["notification", "show", "Pi needs input", "--sound", "request"])' apps/pi-extensions/parent-completion-notify.ts
pi --help
```

Expected: every command exits 0.

- [ ] **Step 4: Commit**

```sh
git add apps/pi-extensions/parent-completion-notify.ts
git commit -m "feat(pi): chime when input is needed"
```
