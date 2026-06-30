---
name: cmux-pi-subagent
description: Spawn a pi subagent in a visible cmux pane, run a task in it, collect the answer, and close the pane. Use when you want to delegate a self-contained task to a separate pi process running in its own cmux split (deploy → execute → collect → remove), instead of doing the work inline. Requires running inside a cmux surface.
compatibility: Requires cmux (CMUX_SOCKET_PATH + CMUX_SURFACE_ID set), the `pi` CLI on PATH, and python3.
metadata:
  author: built for fdrake
  replaces: pi-interactive-subagents
---

# cmux pi subagent

Delegate a task to a **separate pi process** that runs in its own **visible cmux
pane**, driven over pi's RPC (JSONL) protocol. The lifecycle is fully managed:

1. **DEPLOY**  — create a new cmux split surface (a visible pane), without stealing focus
2. **READY**   — wait until the pane's shell actually executes commands (robust against fish + direnv + dropped keystrokes)
3. **EXECUTE** — run `pi --mode rpc` in the pane, send the task, stream the work live in the pane
4. **COLLECT** — read the subagent's final answer from a result file
5. **REMOVE**  — close the pane (no leftover panes)

This replaces the `pi-interactive-subagents` package for the deploy/execute/remove
use case. Results are captured via files (not screen-scraping), so they are reliable.

## Install location

Move this whole directory to pi's user-level skills folder so pi auto-discovers it
on every launch (no settings.json change needed):

```
~/.pi/agent/skills/cmux-pi-subagent/
├── SKILL.md
├── orchestrate.py
└── runner.py
```

(Per pi docs/skills.md, any directory containing a SKILL.md under
`~/.pi/agent/skills/` is discovered recursively at startup.)

## Preconditions

This skill only works when the current pi session is running **inside a cmux surface**.
Verify before use:

```bash
echo "socket=$CMUX_SOCKET_PATH surface=$CMUX_SURFACE_ID"
```

Both must be non-empty. If they are empty, you are not in cmux and this skill cannot run.

## Usage

Run the orchestrator with the task as a single argument. It blocks until the
subagent finishes, then prints the answer between `===== SUBAGENT ANSWER =====`
markers and closes the pane automatically.

```bash
python3 ~/.pi/agent/skills/cmux-pi-subagent/orchestrate.py \
  --name "scout" \
  --model claude-haiku-4-5 \
  "Use your tools to inspect this repo and report the project name and Swift file count."
```

For a long task prompt, write it to a file and pass `--task-file` instead of an
inline argument:

```bash
python3 ~/.pi/agent/skills/cmux-pi-subagent/orchestrate.py \
  --name "implementer" --task-file /tmp/my-task.md
```

## Options

| Flag | Default | Meaning |
|------|---------|---------|
| `task` (positional) | — | The task text. Omit if using `--task-file`. |
| `--task-file PATH` | — | Read the task from a file (use for long/multiline prompts). |
| `--name NAME` | `pi-subagent` | Tab title for the spawned pane. |
| `--model MODEL` | pi default | Model for the subagent, e.g. `claude-haiku-4-5`, `claude-sonnet-4-6`. |
| `--cwd PATH` | current dir | Working directory the subagent runs in. |
| `--direction DIR` | `right` | Split direction: `left` / `right` / `up` / `down`. |
| `--timeout SECS` | `600` | Max seconds to wait for the subagent. |
| `--keep-open` | off | Leave the pane open after finishing (for debugging). |

## How it works (internals)

- `orchestrate.py` is the controller (runs in the current session). It creates the
  split with `cmux new-split <dir> --surface $CMUX_SURFACE_ID --focus false`,
  proves the shell is alive by polling for a touch-file (this is why it survives
  fish + direnv startup), launches `runner.py` in the pane, polls for a `done`
  marker, reads the `result.txt`, then runs `cmux close-surface`.
- `runner.py` runs **inside** the pane. It spawns `pi --mode rpc --no-session`,
  sends the task as one `prompt`, streams assistant text + tool activity to the
  pane so the work is visible, and on `agent_end` writes the final assistant text
  to the result file (atomic write) followed by the done marker.
- Per-run scratch files live in `/tmp/cmux-pi-subagent/<run-id>/`.

## Notes & limits

- The subagent is **ephemeral** (`--no-session`); it does one task and exits.
- One subagent at a time per `orchestrate.py` invocation (it blocks). For parallel
  fan-out, launch multiple panes (ask to extend the orchestrator for concurrency).
- The pane is created **without** stealing focus, so you can keep working.
- If something goes wrong mid-run, rerun with `--keep-open` to inspect the pane.
