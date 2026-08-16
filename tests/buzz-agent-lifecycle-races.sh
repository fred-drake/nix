#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
helper="$root/apps/scripts/buzz-agent-deploy"
restore="$root/apps/scripts/buzz-agent-restore"
recorder="$root/apps/scripts/buzz-agent-record-clean-exit"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"

cat >"$tmp/bin/flock" <<'PY'
#!/usr/bin/env python3
import fcntl
import os
import sys

fd = int(sys.argv[1])
attempt = os.environ.get("FAKE_FLOCK_ATTEMPT")
if attempt:
    open(attempt, "w").close()
fcntl.flock(fd, fcntl.LOCK_EX)
PY
cat >"$tmp/bin/nak" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ $* == "key public" ]]
IFS= read -r key
[[ $key == nsec1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqsmhltgl ]]
printf '%s\n' 79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798
EOF
cat >"$tmp/bin/systemctl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s:%s\n' "${FAKE_ACTOR:-unknown}" "$*" >>"$FAKE_SYSTEMCTL_LOG"
if [[ ${FAKE_RECORD_COMMAND:-} == "$1" ]]; then
  SERVICE_RESULT=exit-code EXIT_CODE=exited EXIT_STATUS=42 \
    "$FAKE_RECORDER" "$FAKE_DISABLED_DIR" "$FAKE_LIFECYCLE_LOCK" "$FAKE_AGENT_ID"
fi
if [[ ${FAKE_BLOCK_COMMAND:-} == "$1" ]]; then
  : >"$FAKE_BLOCK_READY"
  while [[ ! -e $FAKE_BLOCK_RELEASE ]]; do sleep 0.01; done
fi
case $1 in
  is-active) exit 1 ;;
  show) printf '%s\n' active running success 0 0 ;;
  start|restart|stop) ;;
  *) exit 2 ;;
esac
EOF
chmod +x "$tmp/bin/flock" "$tmp/bin/nak" "$tmp/bin/systemctl"

agent_id=79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798
request='{"operation":"deploy","agent_id":"79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798","environment":{"BUZZ_PRIVATE_KEY":"nsec1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqsmhltgl","NOSTR_PRIVATE_KEY":"nsec1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqsmhltgl","BUZZ_RELAY_URL":"wss://relay.example","BUZZ_AUTH_TAG":"auth-secret-sentinel","BUZZ_ACP_AGENT_COMMAND":"codex-acp","BUZZ_ACP_RESPOND_TO":"owner-only","BUZZ_ACP_MCP_COMMAND":"buzz-dev-mcp","BUZZ_ACP_EXIT_AFTER_INACTIVITY":"7200","BUZZ_MANAGED_AGENT_START_NONCE":"0123456789abcdef0123456789abcdef"}}'
export FAKE_SYSTEMCTL_LOG="$tmp/systemctl.log"
lock="$tmp/lifecycle.lock"
operation_lock="$tmp/operation.lock"

wait_ready() {
  local path=$1
  for _ in $(seq 1 500); do
    [[ -e $path ]] && return 0
    sleep 0.01
  done
  echo "timed out waiting for deterministic race barrier" >&2
  return 1
}

# A deploy holds the lifecycle lock across state inspection, environment
# replacement, and start. Restore must not scan or start until deploy completes.
deploy_state="$tmp/deploy-state"
mkdir -p "$deploy_state"
: >"$FAKE_SYSTEMCTL_LOG"
deploy_ready="$tmp/deploy-ready"
deploy_release="$tmp/deploy-release"
(
  printf '%s\n' "$request" | PATH="$tmp/bin:$PATH" \
    BUZZ_AGENT_STABILITY_CHECKS=1 BUZZ_AGENT_STABILITY_INTERVAL=0 \
    FAKE_ACTOR=deploy FAKE_BLOCK_COMMAND=is-active \
    FAKE_BLOCK_READY="$deploy_ready" FAKE_BLOCK_RELEASE="$deploy_release" \
    "$helper" "$deploy_state" "$lock" "$operation_lock" \
    >"$tmp/deploy.out" 2>"$tmp/deploy.err"
) &
deploy_pid=$!
wait_ready "$deploy_ready"
deploy_restore_attempt="$tmp/deploy-restore-attempt"
PATH="$tmp/bin:$PATH" FAKE_ACTOR=restore FAKE_FLOCK_ATTEMPT="$deploy_restore_attempt" \
  "$restore" "$deploy_state/env" "$deploy_state/disabled" "$lock" "$operation_lock" \
  >"$tmp/deploy-restore.out" 2>"$tmp/deploy-restore.err" &
restore_pid=$!
wait_ready "$deploy_restore_attempt"
kill -0 "$restore_pid"
! grep -q '^restore:' "$FAKE_SYSTEMCTL_LOG"
: >"$deploy_release"
wait "$deploy_pid"
wait "$restore_pid"
jq -e '.ok == true' "$tmp/deploy.out" >/dev/null
[[ ! -s $tmp/deploy.err && ! -s $tmp/deploy-restore.out && ! -s $tmp/deploy-restore.err ]]
deploy_start_line=$(grep -n "^deploy:start buzz-agent@$agent_id.service$" "$FAKE_SYSTEMCTL_LOG" | cut -d: -f1)
restore_start_line=$(grep -n "^restore:start buzz-agent@$agent_id.service$" "$FAKE_SYSTEMCTL_LOG" | cut -d: -f1)
(( deploy_start_line < restore_start_line ))

# Restore holds the same lock from filename validation through start. Remove
# waits, then stops the exact unit and deletes the marker as its final state.
remove_state="$tmp/remove-state"
mkdir -p "$remove_state/env"
printf '%s\n' 'SECRET=must-not-be-logged' >"$remove_state/env/$agent_id"
: >"$FAKE_SYSTEMCTL_LOG"
rm -f "$lock"
restore_ready="$tmp/restore-ready"
restore_release="$tmp/restore-release"
PATH="$tmp/bin:$PATH" FAKE_ACTOR=restore FAKE_BLOCK_COMMAND=start \
  FAKE_BLOCK_READY="$restore_ready" FAKE_BLOCK_RELEASE="$restore_release" \
  "$restore" "$remove_state/env" "$remove_state/disabled" "$lock" "$operation_lock" \
  >"$tmp/remove-restore.out" 2>"$tmp/remove-restore.err" &
restore_pid=$!
wait_ready "$restore_ready"
remove_request=$(jq -cn --arg id "$agent_id" '{operation:"remove",agent_id:$id}')
remove_attempt="$tmp/remove-attempt"
(
  printf '%s\n' "$remove_request" | PATH="$tmp/bin:$PATH" \
    FAKE_ACTOR=remove FAKE_FLOCK_ATTEMPT="$remove_attempt" \
    "$helper" "$remove_state" "$lock" "$operation_lock" \
    >"$tmp/remove.out" 2>"$tmp/remove.err"
) &
remove_pid=$!
wait_ready "$remove_attempt"
kill -0 "$remove_pid"
! grep -q '^remove:' "$FAKE_SYSTEMCTL_LOG"
: >"$restore_release"
wait "$restore_pid"
wait "$remove_pid"
jq -e '.ok == true' "$tmp/remove.out" >/dev/null
[[ ! -e $remove_state/env/$agent_id ]]
[[ ! -s $tmp/remove.err && ! -s $tmp/remove-restore.out && ! -s $tmp/remove-restore.err ]]
restore_start_line=$(grep -n "^restore:start buzz-agent@$agent_id.service$" "$FAKE_SYSTEMCTL_LOG" | cut -d: -f1)
remove_stop_line=$(grep -n "^remove:stop buzz-agent@$agent_id.service$" "$FAKE_SYSTEMCTL_LOG" | cut -d: -f1)
(( restore_start_line < remove_stop_line ))
! grep -Fq 'must-not-be-logged' "$tmp"/*.out "$tmp"/*.err "$FAKE_SYSTEMCTL_LOG"

# Restore drops the state lock around systemctl. If verified shutdown records a
# marker after restore's initial check, restore rechecks and stops the stale
# start instead of resurrecting the agent.
restore_shutdown_state="$tmp/restore-shutdown-state"
mkdir -p "$restore_shutdown_state/env"
printf '%s\n' 'SECRET=must-not-be-logged' >"$restore_shutdown_state/env/$agent_id"
: >"$FAKE_SYSTEMCTL_LOG"
PATH="$tmp/bin:$PATH" FAKE_ACTOR=restore-shutdown FAKE_RECORD_COMMAND=start \
  FAKE_RECORDER="$recorder" FAKE_DISABLED_DIR="$restore_shutdown_state/disabled" \
  FAKE_LIFECYCLE_LOCK="$lock" FAKE_AGENT_ID="$agent_id" \
  "$restore" "$restore_shutdown_state/env" "$restore_shutdown_state/disabled" \
  "$lock" "$operation_lock" >"$tmp/restore-shutdown.out" 2>"$tmp/restore-shutdown.err"
[[ ! -s $tmp/restore-shutdown.out && ! -s $tmp/restore-shutdown.err ]]
[[ -f $restore_shutdown_state/disabled/$agent_id ]]
grep -Fx "restore-shutdown:start buzz-agent@$agent_id.service" "$FAKE_SYSTEMCTL_LOG" >/dev/null
grep -Fx "restore-shutdown:stop buzz-agent@$agent_id.service" "$FAKE_SYSTEMCTL_LOG" >/dev/null

# A verified shutdown that lands while deploy has dropped only the state lock
# wins over deploy's stale start decision. The operation lock still excludes
# restore/remove, and deploy must not erase the recorder's marker afterward.
shutdown_state="$tmp/shutdown-state"
mkdir -p "$shutdown_state"
: >"$FAKE_SYSTEMCTL_LOG"
set +e
printf '%s\n' "$request" | PATH="$tmp/bin:$PATH" \
  BUZZ_AGENT_STABILITY_CHECKS=1 BUZZ_AGENT_STABILITY_INTERVAL=0 \
  FAKE_ACTOR=shutdown-deploy FAKE_RECORD_COMMAND=start \
  FAKE_RECORDER="$recorder" FAKE_DISABLED_DIR="$shutdown_state/disabled" \
  FAKE_LIFECYCLE_LOCK="$lock" FAKE_AGENT_ID="$agent_id" \
  "$helper" "$shutdown_state" "$lock" "$operation_lock" \
  >"$tmp/shutdown-deploy.out" 2>"$tmp/shutdown-deploy.err"
shutdown_rc=$?
set -e
[[ $shutdown_rc == 0 && ! -s $tmp/shutdown-deploy.err ]]
jq -e '.ok == false and .error == "helper: service inactive"' "$tmp/shutdown-deploy.out" >/dev/null
[[ -f $shutdown_state/disabled/$agent_id ]]
grep -Fx "shutdown-deploy:stop buzz-agent@$agent_id.service" "$FAKE_SYSTEMCTL_LOG" >/dev/null

printf '%s\n' 'lifecycle race tests passed'
