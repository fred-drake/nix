#!/usr/bin/env python3
"""
runner.py -- runs INSIDE a cmux pane.

Drives a `pi --mode rpc` subagent over JSONL:
  * sends the task as a single prompt
  * streams assistant text + tool activity to this pane (so you can watch it)
  * on agent_end, writes the final assistant text to --result-file (atomic)
    and then writes --done-file as the completion marker
  * shuts the pi RPC subprocess down cleanly and exits

The orchestrator (orchestrate.py) watches for --done-file, reads --result-file,
then closes this pane.
"""
import argparse
import json
import os
import subprocess
import sys
import threading
import time


def log(msg):
    sys.stdout.write(msg + "\n")
    sys.stdout.flush()


def extract_assistant_text(message):
    """Pull text from an AgentMessage whose content may be str or list of blocks."""
    content = message.get("content")
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = []
        for c in content:
            if isinstance(c, dict) and c.get("type") == "text":
                parts.append(c.get("text", ""))
        return "".join(parts)
    return ""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--task-file", required=True)
    ap.add_argument("--result-file", required=True)
    ap.add_argument("--done-file", required=True)
    ap.add_argument("--model", default=None)
    ap.add_argument("--cwd", default=None)
    ap.add_argument("--timeout", type=float, default=600.0)
    args = ap.parse_args()

    with open(args.task_file, "r") as f:
        task = f.read().strip()

    cmd = ["pi", "--mode", "rpc", "--no-session"]
    if args.model:
        cmd += ["--model", args.model]

    log("\033[1;36m┌─ cmux pi subagent ─────────────────────────────────\033[0m")
    log("\033[1;36m│\033[0m model : " + (args.model or "(default)"))
    log("\033[1;36m│\033[0m cwd   : " + (args.cwd or os.getcwd()))
    log("\033[1;36m│\033[0m task  : " + (task[:200] + ("…" if len(task) > 200 else "")))
    log("\033[1;36m└────────────────────────────────────────────────────\033[0m")
    log("")

    proc = subprocess.Popen(
        cmd,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        bufsize=1,
        cwd=args.cwd or None,
    )

    final_text = {"value": None}
    error_text = {"value": None}
    done = threading.Event()
    streaming_any = {"value": False}

    def reader():
        for line in proc.stdout:
            line = line.rstrip("\n")
            if not line:
                continue
            try:
                ev = json.loads(line)
            except Exception:
                continue
            t = ev.get("type")
            if t == "message_update":
                ame = ev.get("assistantMessageEvent", {})
                if ame.get("type") == "text_delta":
                    sys.stdout.write(ame.get("delta", ""))
                    sys.stdout.flush()
                    streaming_any["value"] = True
                elif ame.get("type") == "thinking_start":
                    sys.stdout.write("\033[2m[thinking…]\033[0m ")
                    sys.stdout.flush()
            elif t == "tool_execution_start":
                name = ev.get("toolName", "?")
                a = ev.get("args", {})
                brief = json.dumps(a)[:120]
                log("\n\033[33m▸ tool:\033[0m %s %s" % (name, brief))
            elif t == "tool_execution_end":
                is_err = ev.get("isError")
                log("\033[33m◂ tool done%s\033[0m" % (" (error)" if is_err else ""))
            elif t == "agent_end":
                for m in ev.get("messages", []):
                    if m.get("role") == "assistant":
                        txt = extract_assistant_text(m)
                        if txt:
                            final_text["value"] = txt
                done.set()
            elif t == "extension_error":
                error_text["value"] = ev.get("error")

    th = threading.Thread(target=reader, daemon=True)
    th.start()

    # Send the task as a single prompt.
    proc.stdin.write(json.dumps({"id": "task-1", "type": "prompt", "message": task}) + "\n")
    proc.stdin.flush()

    ok = done.wait(timeout=args.timeout)

    result = final_text["value"]
    if result is None:
        if error_text["value"]:
            result = "[subagent error] " + str(error_text["value"])
        elif not ok:
            result = "[subagent timed out after %ss]" % args.timeout
        else:
            result = "[subagent produced no assistant text]"

    # Atomic write of the result, then the done marker.
    tmp = args.result_file + ".tmp"
    with open(tmp, "w") as f:
        f.write(result)
    os.replace(tmp, args.result_file)
    with open(args.done_file, "w") as f:
        f.write("ok\n" if ok else "timeout\n")

    log("")
    log("\033[1;32m✅ SUBAGENT COMPLETE\033[0m  (result captured, %d chars)" % len(result))

    # Clean shutdown of the RPC process.
    try:
        proc.stdin.close()
    except Exception:
        pass
    try:
        proc.wait(timeout=5)
    except Exception:
        proc.kill()


if __name__ == "__main__":
    main()
