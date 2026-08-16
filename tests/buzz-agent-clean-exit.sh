#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
recorder="$root/apps/scripts/buzz-agent-record-clean-exit"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"
cat >"$tmp/bin/flock" <<'PY'
#!/usr/bin/env python3
import fcntl
import sys

fcntl.flock(int(sys.argv[1]), fcntl.LOCK_EX)
PY
chmod +x "$tmp/bin/flock"
export PATH="$tmp/bin:$PATH"
agent_id=79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798
disabled_dir="$tmp/disabled"
lock_file="$tmp/lifecycle.lock"
marker="$disabled_dir/$agent_id"

# Generic clean exit is not an authenticated owner shutdown identity.
SERVICE_RESULT=success EXIT_CODE=exited EXIT_STATUS=0 \
  "$recorder" "$disabled_dir" "$lock_file" "$agent_id"
[[ ! -e $marker ]]

# Only the pinned harness's dedicated verified-owner status is durable.
SERVICE_RESULT=exit-code EXIT_CODE=exited EXIT_STATUS=42 \
  "$recorder" "$disabled_dir" "$lock_file" "$agent_id"
[[ -f $marker && ! -L $marker ]]
[[ $(stat -c %a "$disabled_dir") == 700 ]]
[[ $(stat -c %a "$marker") == 600 ]]
rm "$marker"

# EnvironmentFile values cannot redirect the fixed module-owned arguments.
malicious_dir="$tmp/malicious"
BUZZ_AGENT_DISABLED_DIR="$malicious_dir" BUZZ_AGENT_LOCK_FILE="$tmp/malicious.lock" \
  SERVICE_RESULT=exit-code EXIT_CODE=exited EXIT_STATUS=42 \
  "$recorder" "$disabled_dir" "$lock_file" "$agent_id"
[[ -f $marker ]]
[[ ! -e $malicious_dir ]]
rm "$marker"

# Marker mutation participates in the global lifecycle lock.
exec 9>"$lock_file"
flock 9
SERVICE_RESULT=exit-code EXIT_CODE=exited EXIT_STATUS=42 \
  "$recorder" "$disabled_dir" "$lock_file" "$agent_id" &
recorder_pid=$!
sleep 0.1
kill -0 "$recorder_pid"
[[ ! -e $marker ]]
exec 9>&-
wait "$recorder_pid"
[[ -f $marker ]]
rm "$marker"

# A dedicated shutdown that cannot be made durable fails visibly.
set +e
SERVICE_RESULT=exit-code EXIT_CODE=exited EXIT_STATUS=42 \
  "$recorder" /dev/null/disabled "$lock_file" "$agent_id" \
  >"$tmp/failure.out" 2>"$tmp/failure.err"
failure_rc=$?
set -e
[[ $failure_rc != 0 ]]
[[ ! -s $tmp/failure.out ]]
grep -Fx 'buzz-agent clean-exit recorder: marker write failed' "$tmp/failure.err" >/dev/null

for metadata in 'success exited 0' 'signal killed 15' 'exit-code exited 1'; do
  read -r result code status <<<"$metadata"
  SERVICE_RESULT="$result" EXIT_CODE="$code" EXIT_STATUS="$status" \
    "$recorder" "$disabled_dir" "$lock_file" "$agent_id"
  [[ ! -e $marker ]]
done

SERVICE_RESULT=exit-code EXIT_CODE=exited EXIT_STATUS=42 \
  "$recorder" "$disabled_dir" "$lock_file" "${agent_id}x"
[[ $(find "$disabled_dir" -type f | wc -l | tr -d ' ') == 0 ]]

printf '%s\n' 'dedicated owner-shutdown persistence tests passed'
