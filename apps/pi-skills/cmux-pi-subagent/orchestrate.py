#!/usr/bin/env python3
"""
orchestrate.py -- deploy / execute / remove a pi subagent in a cmux pane.

Lifecycle:
  1. DEPLOY  : create a new cmux split surface (a visible pane), no focus steal
  2. READY   : wait until the pane's shell actually executes commands
               (robust against fish + direnv + dropped first keystrokes)
  3. EXECUTE : launch runner.py in the pane; it drives `pi --mode rpc`,
               streams the work live in the pane, writes the answer to a file
  4. COLLECT : poll for the done-marker, read the answer
  5. REMOVE  : close the pane (unless --keep-open)

Requires: run from inside a cmux surface (CMUX_SOCKET_PATH + CMUX_SURFACE_ID set).
Prints the final answer to stdout (after a clear delimiter).
"""
import argparse
import os
import re
import subprocess
import sys
import time
import uuid

HERE = os.path.dirname(os.path.abspath(__file__))
RUNNER = os.path.join(HERE, "runner.py")


def log(msg):
    sys.stderr.write(msg + "\n")
    sys.stderr.flush()


def cmux(*cmuxargs, check=True):
    r = subprocess.run(["cmux", *cmuxargs], capture_output=True, text=True)
    if check and r.returncode != 0:
        raise RuntimeError("cmux %s failed: %s" % (" ".join(cmuxargs), r.stderr.strip() or r.stdout.strip()))
    return r.stdout.strip()


def parse_surface(output):
    # e.g. "OK surface:58 workspace:7"
    m = re.search(r"(surface:\d+)", output)
    if not m:
        raise RuntimeError("could not parse surface id from: %r" % output)
    return m.group(1)


def pane_send(surface, text):
    cmux("send", "--surface", surface, text)
    cmux("send-key", "--surface", surface, "Enter")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("task", nargs="?", help="task text (or use --task-file)")
    ap.add_argument("--task-file", default=None)
    ap.add_argument("--name", default="pi-subagent")
    ap.add_argument("--model", default=None)
    ap.add_argument("--cwd", default=os.getcwd())
    ap.add_argument("--direction", default="right", choices=["left", "right", "up", "down"])
    ap.add_argument("--timeout", type=float, default=600.0, help="overall execute timeout (s)")
    ap.add_argument("--ready-timeout", type=float, default=25.0)
    ap.add_argument("--keep-open", action="store_true", help="do not close the pane (debug)")
    args = ap.parse_args()

    parent = os.environ.get("CMUX_SURFACE_ID")
    if not os.environ.get("CMUX_SOCKET_PATH") or not parent:
        log("ERROR: not inside a cmux surface (CMUX_SOCKET_PATH / CMUX_SURFACE_ID unset).")
        sys.exit(2)

    if args.task_file:
        with open(args.task_file) as f:
            task = f.read()
    elif args.task:
        task = args.task
    else:
        log("ERROR: provide a task argument or --task-file.")
        sys.exit(2)

    run_id = time.strftime("%Y%m%d-%H%M%S") + "-" + uuid.uuid4().hex[:6]
    workdir = os.path.join("/tmp", "cmux-pi-subagent", run_id)
    os.makedirs(workdir, exist_ok=True)
    task_file = os.path.join(workdir, "task.txt")
    result_file = os.path.join(workdir, "result.txt")
    done_file = os.path.join(workdir, "done")
    ready_file = os.path.join(workdir, "ready")
    with open(task_file, "w") as f:
        f.write(task)

    # 1. DEPLOY
    out = cmux("new-split", args.direction, "--surface", parent, "--focus", "false")
    surface = parse_surface(out)
    log("● DEPLOY  pane %s (workspace from %s)" % (surface, parent))
    try:
        cmux("rename-tab", "--surface", surface, args.name, check=False)

        # 2. READY -- keep poking until the shell runs a command (creates ready_file).
        log("● READY   waiting for pane shell to accept commands…")
        deadline = time.time() + args.ready_timeout
        ready = False
        while time.time() < deadline:
            pane_send(surface, "touch %s" % ready_file)
            time.sleep(1.0)
            if os.path.exists(ready_file):
                ready = True
                break
        if not ready:
            raise RuntimeError("pane shell never became ready within %ss" % args.ready_timeout)
        log("● READY   pane shell is live")

        # 3. EXECUTE -- launch the in-pane RPC runner.
        cmd_parts = [
            "python3", RUNNER,
            "--task-file", task_file,
            "--result-file", result_file,
            "--done-file", done_file,
            "--cwd", args.cwd,
            "--timeout", str(args.timeout),
        ]
        if args.model:
            cmd_parts += ["--model", args.model]
        pane_send(surface, " ".join(cmd_parts))
        log("● EXECUTE runner launched in pane; streaming live there…")

        # 4. COLLECT
        deadline = time.time() + args.timeout + 30.0
        while time.time() < deadline:
            if os.path.exists(done_file):
                break
            time.sleep(1.0)
        if not os.path.exists(done_file):
            raise RuntimeError("subagent did not finish within timeout")

        with open(result_file) as f:
            answer = f.read()
        log("● COLLECT answer captured (%d chars)" % len(answer))

    finally:
        # 5. REMOVE
        if args.keep_open:
            log("● REMOVE  skipped (--keep-open); pane %s left open" % surface)
        else:
            cmux("close-surface", "--surface", surface, check=False)
            log("● REMOVE  pane %s closed" % surface)

    print("\n===== SUBAGENT ANSWER =====")
    print(answer)
    print("===== END =====")


if __name__ == "__main__":
    main()
