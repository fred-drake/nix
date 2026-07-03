#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: launch.sh CONFIG_JSON" >&2
  exit 64
fi

config_json="$1"
run_dir="$(dirname "$config_json")"
started_file="$run_dir/runner-started"
exit_file="$run_dir/runner-exit-code"

printf '%s\n' "$$" > "$run_dir/launcher-pid"
touch "$started_file"

eval "$(python3 - "$config_json" <<'PY'
import json
import shlex
import sys
from pathlib import Path
config = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
print("runner=" + shlex.quote(config["runner"]))
path = config.get("env", {}).get("PATH")
if path:
    print("export PATH=" + shlex.quote(path))
PY
)"

set +e
python3 "$runner" --config-file "$config_json"
code=$?
set -e
printf '%s\n' "$code" > "$exit_file"
exit "$code"
