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
import json
import os
import re
import shlex
import subprocess
import sys
import time
import uuid

HERE = os.path.dirname(os.path.abspath(__file__))
RUNNER = os.path.join(HERE, "runner.py")
LAUNCHER = os.path.join(HERE, "launch.sh")


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


def build_launch_command(config_file):
    return "bash %s %s" % (shlex.quote(LAUNCHER), shlex.quote(config_file))


def write_run_config(workdir, task_file, result_file, done_file, heartbeat_file, error_file, cwd, timeout, model):
    config_file = os.path.join(workdir, "config.json")
    data = {
        "runner": RUNNER,
        "task_file": task_file,
        "result_file": result_file,
        "done_file": done_file,
        "heartbeat_file": heartbeat_file,
        "error_file": error_file,
        "cwd": cwd,
        "timeout": timeout,
        "model": model,
        "env": {
            "PATH": os.environ.get("PATH", ""),
        },
    }
    tmp = config_file + ".tmp"
    with open(tmp, "w") as f:
        json.dump(data, f, indent=2)
    os.replace(tmp, config_file)
    return config_file


def launch_runner(workspace, surface, config_file, cmux_fn=cmux):
    cmux_fn(
        "respawn-pane",
        "--workspace", workspace,
        "--surface", surface,
        "--command", build_launch_command(config_file),
    )


def surface_exists(workspace, surface):
    r = subprocess.run(
        ["cmux", "list-pane-surfaces", "--workspace", workspace, "--json"],
        capture_output=True,
        text=True,
    )
    return r.returncode == 0 and ('"ref" : "' + surface + '"') in r.stdout


def close_surface_if_present(workspace, surface):
    for _ in range(5):
        if not surface_exists(workspace, surface):
            return True
        cmux("close-surface", "--workspace", workspace, "--surface", surface, check=False)
        time.sleep(0.2)
    return not surface_exists(workspace, surface)


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
    workspace = os.environ.get("CMUX_WORKSPACE_ID")
    if not os.environ.get("CMUX_SOCKET_PATH") or not parent or not workspace:
        log("ERROR: not inside a cmux surface (CMUX_SOCKET_PATH / CMUX_SURFACE_ID / CMUX_WORKSPACE_ID unset).")
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
    heartbeat_file = os.path.join(workdir, "heartbeat")
    error_file = os.path.join(workdir, "error.txt")
    started_file = os.path.join(workdir, "runner-started")
    with open(task_file, "w") as f:
        f.write(task)
    config_file = write_run_config(
        workdir=workdir,
        task_file=task_file,
        result_file=result_file,
        done_file=done_file,
        heartbeat_file=heartbeat_file,
        error_file=error_file,
        cwd=args.cwd,
        timeout=args.timeout,
        model=args.model,
    )
    answer = ""

    # 1. DEPLOY
    out = cmux("new-split", args.direction, "--surface", parent, "--focus", "false")
    surface = parse_surface(out)
    log("● DEPLOY  pane %s (workspace from %s)" % (surface, parent))
    try:
        cmux("rename-tab", "--surface", surface, args.name, check=False)

        # 2. READY/EXECUTE -- respawn the pane with the checked-in launcher.
        log("● EXECUTE launching runner via cmux respawn-pane…")
        launch_runner(workspace, surface, config_file)
        deadline = time.time() + args.ready_timeout
        while time.time() < deadline:
            if os.path.exists(started_file):
                break
            time.sleep(0.2)
        if not os.path.exists(started_file):
            raise RuntimeError("runner never started within %ss" % args.ready_timeout)
        log("● READY   runner started in pane; streaming live there…")

        # 3. COLLECT
        deadline = time.time() + args.timeout + 30.0
        while time.time() < deadline:
            if os.path.exists(done_file):
                break
            if os.path.exists(error_file):
                break
            time.sleep(1.0)
        if os.path.exists(error_file) and not os.path.exists(done_file):
            with open(error_file) as f:
                raise RuntimeError(f.read().strip() or "subagent failed")
        if not os.path.exists(done_file):
            raise RuntimeError("subagent did not finish within timeout")

        with open(result_file) as f:
            answer = f.read()
        log("● COLLECT answer captured (%d chars)" % len(answer))

    finally:
        # 4. REMOVE
        if args.keep_open:
            log("● REMOVE  skipped (--keep-open); pane %s left open" % surface)
        else:
            if close_surface_if_present(workspace, surface):
                log("● REMOVE  pane %s closed" % surface)
            else:
                log("● REMOVE  WARNING pane %s still appears to be open" % surface)

    print("\n===== SUBAGENT ANSWER =====")
    print(answer)
    print("===== END =====")


if __name__ == "__main__":
    main()
