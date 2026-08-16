#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
helper="$root/apps/scripts/buzz-agent-deploy"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"
real_mv=$(command -v mv)
cat >"$tmp/bin/mv" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
source_file=
for argument in "$@"; do
  [[ $argument == -* ]] || { source_file=$argument; break; }
done
if [[ -n $source_file && -f $source_file && $source_file != "$FAKE_TEST_ROOT"/* ]]; then
  [[ $(stat -c %a "$(dirname "$source_file")") == 700 && $(stat -c %a "$source_file") == 600 ]] \
    || printf '%s\n' "$(basename "$source_file")" >>"$FAKE_TEMP_MODE_LOG"
fi
if [[ ${FAKE_ROLLBACK_MV_FAIL:-0} == 1 ]]; then
  for argument in "$@"; do
    [[ $argument != *.rollback-staged.* ]] || exit 1
  done
fi
exec "$REAL_MV" "$@"
EOF
cat >"$tmp/bin/flock" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat >"$tmp/bin/nak" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ $* == "key public" ]]
IFS= read -r key
[[ $key == nsec1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqsmhltgl ]] || exit 1
printf '%s\n' 79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798
EOF
cat >"$tmp/bin/systemctl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$FAKE_SYSTEMCTL_LOG"
if env | grep -E -q 'auth-secret-sentinel|nsec1qqqq'; then
  exit 92
fi
case $1 in
  is-active) [[ ${FAKE_WAS_ACTIVE:-0} == 1 ]] ;;
  is-enabled)
    printf '%s\n' static
    exit 0
    ;;
  enable|disable)
    # NixOS owns the immutable static template; dynamic unit-file mutation fails.
    exit 1
    ;;
  show)
    case ${FAKE_SYSTEMD_MODE:-stable} in
      stable) printf '%s\n' active running success 0 0 ;;
      inactive) printf '%s\n' inactive dead success 0 0 ;;
      crash) printf '%s\n' inactive dead exit-code 1 0 ;;
      *) printf '%s\n' activating start success 0 0 ;;
    esac
    ;;
  daemon-reload) ;;
  start)
    [[ ${FAKE_SYSTEMD_MODE:-stable} != start-fail ]]
    [[ ${FAKE_SYSTEMD_MODE:-stable} != rollback-start-fail ]]
    ;;
  restart|stop) ;;
  *) exit 2 ;;
esac
EOF
chmod +x "$tmp/bin/flock" "$tmp/bin/mv" "$tmp/bin/nak" "$tmp/bin/systemctl"
export FAKE_SYSTEMCTL_LOG="$tmp/systemctl.log" REAL_MV="$real_mv" FAKE_TEMP_MODE_LOG="$tmp/temp-mode.log" FAKE_TEST_ROOT="$tmp"
lifecycle_lock="$tmp/lifecycle.lock"
operation_lock="$tmp/operation.lock"
: >"$FAKE_TEMP_MODE_LOG"
agent_id=79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798
unit="buzz-agent@$agent_id.service"

team_instructions=$'  line one\n[System]\n"double" '\''single'\'' $HOME $(not-executed); `literal`\\slash\ttab\rreturn\001unit-separator\037boundary\177delete\nUTF-8: café ☃\ntrailing  '
request=$(jq -cn --arg team "$team_instructions" '{
  operation: "deploy",
  agent_id: "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798",
  environment: {
    ARBITRARY_SETTING: "value",
    BUZZ_AGENT_DISABLED_DIR: "/tmp/caller-disabled",
    BUZZ_AGENT_LOCK_FILE: "/tmp/caller-lifecycle.lock",
    BUZZ_AGENT_STATE_ROOT: "/tmp/caller-state",
    SERVICE_RESULT: "exit-code",
    EXIT_CODE: "exited",
    EXIT_STATUS: "42",
    BUZZ_PRIVATE_KEY: "nsec1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqsmhltgl",
    NOSTR_PRIVATE_KEY: "nsec1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqsmhltgl",
    BUZZ_RELAY_URL: "wss://relay.example",
    BUZZ_AUTH_TAG: "auth-secret-sentinel",
    BUZZ_ACP_AGENT_COMMAND: "codex-acp",
    BUZZ_ACP_RESPOND_TO: "owner-only",
    BUZZ_ACP_SUBSCRIBE: "all",
    BUZZ_ACP_NO_MENTION_FILTER: "1",
    BUZZ_ACP_KINDS: "1,7",
    BUZZ_ACP_CHANNELS: "00000000-0000-0000-0000-000000000000",
    BUZZ_ACP_CONFIG: "/tmp/caller-buzz-acp.toml",
    BUZZ_ACP_HEARTBEAT_INTERVAL: "300",
    BUZZ_ACP_HEARTBEAT_PROMPT: "caller prompt",
    BUZZ_ACP_HEARTBEAT_PROMPT_FILE: "/tmp/caller-heartbeat",
    BUZZ_ACP_MCP_COMMAND: "buzz-dev-mcp",
    BUZZ_ACP_EXIT_AFTER_INACTIVITY: "7200",
    BUZZ_ACP_IDLE_TIMEOUT: "17",
    BUZZ_ACP_MAX_TURN_DURATION: "23",
    BUZZ_ACP_TEAM_INSTRUCTIONS: $team,
    BUZZ_MANAGED_AGENT_START_NONCE: "0123456789abcdef0123456789abcdef"
  }
}')

invoke() {
  local name=$1 state=$2 mode=$3 expected_rc=$4
  local out="$tmp/$name.out" err="$tmp/$name.err"
  [[ -e $state ]] || mkdir -p "$state"
  : >"$FAKE_SYSTEMCTL_LOG"
  set +e
  printf '%s\n' "${5:-$request}" | PATH="$tmp/bin:$PATH" BUZZ_AGENT_STABILITY_CHECKS=3 BUZZ_AGENT_STABILITY_INTERVAL=0 FAKE_SYSTEMD_MODE="$mode" \
    "$helper" "$state" "$lifecycle_lock" "$operation_lock" >"$out" 2>"$err"
  local rc=$?
  set -e
  [[ $rc == "$expected_rc" ]] || { echo "$name: expected rc $expected_rc, got $rc" >&2; return 1; }
  [[ ! -s $err ]] || { echo "$name: stderr was not empty" >&2; return 1; }
  [[ $(wc -l <"$out" | tr -d ' ') == 1 ]]
  ! grep -E -q 'private-secret-sentinel|auth-secret-sentinel' "$out" "$err" "$FAKE_SYSTEMCTL_LOG"
}

assert_error() {
  local name=$1 error=$2
  if ! jq -e --arg error "$error" 'keys == ["error","ok"] and .ok == false and .error == $error' "$tmp/$name.out" >/dev/null; then
    jq -c '{ok,error}' "$tmp/$name.out" >&2
    return 1
  fi
}

assert_rollback_error() {
  local name=$1 error=$2 step=$3
  jq -e --arg error "$error" --arg step "$step" '
    keys == ["error","ok","rollback","rollback_step"]
    and .ok == false
    and .error == $error
    and .rollback == "helper: rollback failed"
    and .rollback_step == $step
  ' "$tmp/$name.out" >/dev/null
}

invoke invalid "$tmp/invalid-state" stable 0 '{}'
assert_error invalid 'helper: invalid request'

bad_key=$(jq -cn --argjson r "$request" '$r | .environment["bad.key"]="value"')
invoke invalid-key "$tmp/invalid-key-state" stable 0 "$bad_key"
assert_error invalid-key 'helper: invalid request'

reserved=$(jq -cn --argjson r "$request" '$r | .environment.CODEX_PATH="/tmp/forged"')
invoke reserved "$tmp/reserved-state" stable 0 "$reserved"
assert_error reserved 'helper: invalid request'

reserved_path=$(jq -cn --argjson r "$request" '$r | .environment.PATH="/tmp/forged"')
invoke reserved-path "$tmp/reserved-path-state" stable 0 "$reserved_path"
assert_error reserved-path 'helper: invalid request'

presence=$(jq -cn --argjson r "$request" '$r | .environment.BUZZ_ACP_NO_PRESENCE="1"')
invoke presence "$tmp/presence-state" stable 0 "$presence"
assert_error presence 'helper: invalid request'

alias_mismatch=$(jq -cn --argjson r "$request" '$r | .environment.NOSTR_PRIVATE_KEY="nsec1mismatch"')
invoke alias-mismatch "$tmp/alias-mismatch-state" stable 0 "$alias_mismatch"
assert_error alias-mismatch 'helper: invalid request'

identity_mismatch=$(jq -cn --argjson r "$request" '$r | .agent_id="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"')
invoke identity-mismatch "$tmp/identity-mismatch-state" stable 0 "$identity_mismatch"
assert_error identity-mismatch 'helper: invalid request'

bad_owner=$(jq -cn --argjson r "$request" '$r | del(.environment.BUZZ_AUTH_TAG) | .environment.BUZZ_ACP_AGENT_OWNER="not-a-pubkey"')
invoke bad-owner "$tmp/bad-owner-state" stable 0 "$bad_owner"
assert_error bad-owner 'helper: invalid request'

bad_allowlist=$(jq -cn --argjson r "$request" '$r | .environment.BUZZ_ACP_RESPOND_TO_ALLOWLIST="not-a-pubkey"')
invoke bad-allowlist "$tmp/bad-allowlist-state" stable 0 "$bad_allowlist"
assert_error bad-allowlist 'helper: invalid request'

forged_mcp=$(jq -cn --argjson r "$request" '$r | .environment.BUZZ_ACP_MCP_COMMAND="forged"')
invoke forged-mcp "$tmp/forged-mcp-state" stable 0 "$forged_mcp"
assert_error forged-mcp 'helper: invalid request'

forged_nonce=$(jq -cn --argjson r "$request" '$r | .environment.BUZZ_MANAGED_AGENT_START_NONCE="forged"')
invoke forged-nonce "$tmp/forged-nonce-state" stable 0 "$forged_nonce"
assert_error forged-nonce 'helper: invalid request'

invalid_inactivity=$(jq -cn --argjson r "$request" '$r | .environment.BUZZ_ACP_EXIT_AFTER_INACTIVITY="0"')
invoke invalid-inactivity "$tmp/invalid-inactivity-state" stable 0 "$invalid_inactivity"
jq -e '.ok == true' "$tmp/invalid-inactivity.out" >/dev/null
! grep -q '^BUZZ_ACP_EXIT_AFTER_INACTIVITY=' "$tmp/invalid-inactivity-state/env/$agent_id"

excessive_inactivity=$(jq -cn --argjson r "$request" '$r | .environment.BUZZ_ACP_EXIT_AFTER_INACTIVITY="2147483648"')
invoke excessive-inactivity "$tmp/excessive-inactivity-state" stable 0 "$excessive_inactivity"
jq -e '.ok == true' "$tmp/excessive-inactivity.out" >/dev/null
! grep -q '^BUZZ_ACP_EXIT_AFTER_INACTIVITY=' "$tmp/excessive-inactivity-state/env/$agent_id"

invoke install-fail /dev/null stable 0
assert_error install-fail 'helper: environment install failed'

mkdir -p "$tmp/stable-state/disabled"
printf '%s\n' stale >"$tmp/stable-state/disabled/$agent_id"
invoke stable "$tmp/stable-state" stable 0
jq -e --arg unit "$unit" 'keys == ["ok","unit"] and .ok == true and .unit == $unit' "$tmp/stable.out" >/dev/null
[[ ! -e $tmp/stable-state/disabled/$agent_id ]]
env_file="$tmp/stable-state/env/$agent_id"
[[ $(stat -c %a "$env_file") == 600 ]]
[[ $(stat -c %u "$env_file") == $(id -u) ]]
grep -Fx 'ARBITRARY_SETTING="value"' "$env_file" >/dev/null
! grep -Eq '^(BUZZ_AGENT_(DISABLED_DIR|LOCK_FILE|STATE_ROOT)|SERVICE_RESULT|EXIT_CODE|EXIT_STATUS)=' "$env_file"
grep -Fx 'BUZZ_ACP_IDLE_TIMEOUT="17"' "$env_file" >/dev/null
grep -Fx 'BUZZ_ACP_MAX_TURN_DURATION="23"' "$env_file" >/dev/null
grep -Fx 'BUZZ_ACP_SUBSCRIBE="mentions"' "$env_file" >/dev/null
grep -Fx 'BUZZ_ACP_HEARTBEAT_INTERVAL="0"' "$env_file" >/dev/null
if grep -Eq '^(BUZZ_ACP_(AGENT_COMMAND|MCP_COMMAND|EXIT_AFTER_INACTIVITY|NO_MENTION_FILTER|KINDS|CHANNELS|CONFIG|HEARTBEAT_PROMPT|HEARTBEAT_PROMPT_FILE)|CODEX_PATH|PATH)=' "$env_file"; then
  echo 'helper persisted a module-owned runtime command' >&2
  exit 1
fi
if grep -Fx 'BUZZ_MANAGED_AGENT_START_NONCE="0123456789abcdef0123456789abcdef"' "$env_file" >/dev/null; then
  echo 'helper retained a caller-chosen lifecycle nonce' >&2
  exit 1
fi
grep -E '^BUZZ_MANAGED_AGENT_START_NONCE="[a-f0-9]{32}"$' "$env_file" >/dev/null
printf '%s' "$team_instructions" >"$tmp/expected-team-instructions"
python3 - "$env_file" "$tmp/effective-team-instructions" "$tmp/team-instructions-base64" <<'PY'
import base64
import pathlib
import sys


def parse_systemd_double_quoted(value: str) -> str:
    assert value.startswith('"') and value.endswith('"')
    value = value[1:-1]
    parsed = []
    index = 0
    while index < len(value):
        char = value[index]
        if char != "\\":
            parsed.append(char)
            index += 1
            continue
        assert index + 1 < len(value)
        escaped = value[index + 1]
        if escaped in {'"', "\\", "`", "$"}:
            parsed.append(escaped)
        elif escaped == "\n":
            pass
        else:
            parsed.extend(("\\", escaped))
        index += 2
    return "".join(parsed)

values = {}
for line in pathlib.Path(sys.argv[1]).read_text().splitlines():
    key, raw = line.split("=", 1)
    values[key] = parse_systemd_double_quoted(raw)
encoded = values.get("BUZZ_MANAGED_TEAM_INSTRUCTIONS_B64")
if encoded is not None:
    effective = base64.b64decode(encoded, validate=True).decode()
    pathlib.Path(sys.argv[3]).write_text(encoded)
else:
    effective = values["BUZZ_ACP_TEAM_INSTRUCTIONS"]
pathlib.Path(sys.argv[2]).write_bytes(effective.encode())
PY
if ! cmp "$tmp/expected-team-instructions" "$tmp/effective-team-instructions"; then
  echo 'team instructions did not round-trip through the generated systemd EnvironmentFile' >&2
  exit 1
fi
[[ -s $tmp/team-instructions-base64 ]]
native_runner=$(nix build --no-link --print-out-paths --impure --expr '
  let
    f = builtins.getFlake (toString ./.);
    pkgs = f.inputs.nixpkgs.legacyPackages.aarch64-darwin;
  in pkgs.callPackage ./apps/buzz-agent-run.nix {
    agentCommand = "/module/codex-acp";
    codexPath = "/module/codex";
    agentPath = "/module/bin";
  }
')/bin/buzz-agent-run
cat >"$tmp/environment-recorder" <<'EOF'
#!/bin/bash
set -euo pipefail
[[ ${BUZZ_ACP_AGENT_COMMAND-} == /module/codex-acp ]]
[[ ${CODEX_PATH-} == /module/codex ]]
[[ $PATH == /module/bin ]]
[[ -z ${BUZZ_MANAGED_TEAM_INSTRUCTIONS_B64+x} ]]
[[ -z ${BUZZ_ACP_EXIT_AFTER_INACTIVITY+x} ]]
[[ ${BUZZ_ACP_IDLE_TIMEOUT-} == 17 ]]
[[ ${BUZZ_ACP_SUBSCRIBE-} == mentions ]]
[[ ${BUZZ_ACP_HEARTBEAT_INTERVAL-} == 0 ]]
for name in BUZZ_ACP_NO_MENTION_FILTER BUZZ_ACP_KINDS BUZZ_ACP_CHANNELS BUZZ_ACP_CONFIG BUZZ_ACP_HEARTBEAT_PROMPT BUZZ_ACP_HEARTBEAT_PROMPT_FILE; do
  if eval "test \"\${$name+x}\" = x"; then
    exit 1
  fi
done
printf '%s' "$BUZZ_ACP_TEAM_INSTRUCTIONS" >"$RECORDED_TEAM_INSTRUCTIONS"
EOF
chmod +x "$tmp/environment-recorder"
RECORDED_TEAM_INSTRUCTIONS="$tmp/recorded-team-instructions" \
  BUZZ_PRIVATE_KEY=credential-present \
  BUZZ_ACP_EXIT_AFTER_INACTIVITY=7200 \
  BUZZ_ACP_IDLE_TIMEOUT=17 \
  BUZZ_ACP_SUBSCRIBE=all \
  BUZZ_ACP_NO_MENTION_FILTER=1 \
  BUZZ_ACP_KINDS=1,7 \
  BUZZ_ACP_CHANNELS=00000000-0000-0000-0000-000000000000 \
  BUZZ_ACP_CONFIG=/tmp/caller-buzz-acp.toml \
  BUZZ_ACP_HEARTBEAT_INTERVAL=300 \
  BUZZ_ACP_HEARTBEAT_PROMPT='caller prompt' \
  BUZZ_ACP_HEARTBEAT_PROMPT_FILE=/tmp/caller-heartbeat \
  BUZZ_ACP_TEAM_INSTRUCTIONS=environment-file-forgery \
  BUZZ_MANAGED_TEAM_INSTRUCTIONS_B64="$(<"$tmp/team-instructions-base64")" \
  "$native_runner" "$tmp/environment-recorder"
cat >"$tmp/owner-shutdown-status" <<'EOF'
#!/bin/bash
exit 42
EOF
chmod +x "$tmp/owner-shutdown-status"
set +e
"$native_runner" "$tmp/owner-shutdown-status"
owner_shutdown_rc=$?
set -e
[[ $owner_shutdown_rc == 42 ]]

cat >"$tmp/graceful-term-harness" <<'EOF'
#!/bin/bash
set -euo pipefail
trap 'exit 0' TERM
: >"$TERM_READY"
while :; do read -r -t 1 || :; done
EOF
chmod +x "$tmp/graceful-term-harness"
TERM_READY="$tmp/term-ready" python3 - "$native_runner" "$tmp/graceful-term-harness" <<'PY' &
import os
import sys

os.setsid()
os.execve(sys.argv[1], [sys.argv[1], sys.argv[2]], os.environ)
PY
supervisor_pid=$!
for _ in $(seq 1 100); do
  [[ -e $tmp/term-ready ]] && break
  sleep 0.01
done
[[ -e $tmp/term-ready ]]
kill -TERM -- "-$supervisor_pid"
set +e
wait "$supervisor_pid"
term_rc=$?
set -e
[[ $term_rc == 143 ]]

printf '%s\n\n%s' "$team_instructions" "$(<"$root/apps/buzz-publication-contract.txt")" \
  >"$tmp/expected-composed-team-instructions"
if ! cmp "$tmp/expected-composed-team-instructions" "$tmp/recorded-team-instructions"; then
  echo 'generated launcher did not preserve EnvironmentFile instructions ahead of the contract' >&2
  exit 1
fi
[[ $(grep -c '^show ' "$FAKE_SYSTEMCTL_LOG") == 3 ]]
grep -Fx "start $unit" "$FAKE_SYSTEMCTL_LOG" >/dev/null
if grep -Eq '^(is-enabled|enable|disable)( |$)' "$FAKE_SYSTEMCTL_LOG"; then
  echo 'stable deploy attempted dynamic unit enablement' >&2
  exit 1
fi
for startup_key in \
  BASH_ENV ENV SHELLOPTS BASHOPTS BASH_XTRACEFD PS4 PROMPT_COMMAND ZDOTDIR \
  LD_PRELOAD LD_LIBRARY_PATH LD_AUDIT DYLD_INSERT_LIBRARIES DYLD_LIBRARY_PATH \
  NODE_OPTIONS NODE_PATH NODE_DEBUG NODE_DEBUG_NATIVE BUN_OPTIONS \
  NPM_CONFIG_NODE_OPTIONS npm_config_node_options DENO_DIR \
  OPENSSL_CONF OPENSSL_MODULES OPENSSL_ENGINES GCONV_PATH LOCPATH NLSPATH \
  HOME CODEX_HOME CODEX_CONFIG CODEX_MANAGED_PACKAGE_ROOT CODEX_SQLITE_HOME \
  XDG_CONFIG_HOME XDG_CONFIG_DIRS XDG_DATA_HOME XDG_DATA_DIRS \
  XDG_STATE_HOME XDG_CACHE_HOME; do
  startup_request=$(jq -cn --argjson r "$request" --arg key "$startup_key" '$r | .environment[$key]="injection"')
  invoke "startup-$startup_key" "$tmp/startup-$startup_key-state" stable 0 "$startup_request"
  assert_error "startup-$startup_key" 'helper: invalid request'
done
function_export=$(jq -cn --argjson r "$request" '$r | .environment["BASH_FUNC_probe%%"]="() { :; }"')
invoke function-export "$tmp/function-export-state" stable 0 "$function_export"
assert_error function-export 'helper: invalid request'
nul_team=$(jq -cn --argjson r "$request" '$r | .environment.BUZZ_ACP_TEAM_INSTRUCTIONS="prefix\u0000suffix"')
invoke nul-team "$tmp/nul-team-state" stable 0 "$nul_team"
assert_error nul-team 'helper: invalid request'
invalid_encoded=$(jq -cn --argjson r "$request" '$r | del(.environment.BUZZ_ACP_TEAM_INSTRUCTIONS) | .environment.BUZZ_MANAGED_TEAM_INSTRUCTIONS_B64="not-base64"')
invoke invalid-encoded "$tmp/invalid-encoded-state" stable 0 "$invalid_encoded"
assert_error invalid-encoded 'helper: invalid request'
below_team_limit=$(python3 -c 'print("x" * 65535, end="")')
at_team_limit=$(python3 -c 'print("x" * 65536, end="")')
above_team_limit=$(python3 -c 'print("x" * 65537, end="")')
below_team_request=$(jq -cn --argjson r "$request" --arg team "$below_team_limit" '$r | .environment.BUZZ_ACP_TEAM_INSTRUCTIONS=$team')
invoke team-limit-below "$tmp/team-limit-below-state" stable 0 "$below_team_request"
jq -e '.ok == true' "$tmp/team-limit-below.out" >/dev/null
at_team_request=$(jq -cn --argjson r "$request" --arg team "$at_team_limit" '$r | .environment.BUZZ_ACP_TEAM_INSTRUCTIONS=$team')
invoke team-limit-at "$tmp/team-limit-at-state" stable 0 "$at_team_request"
jq -e '.ok == true' "$tmp/team-limit-at.out" >/dev/null
above_team_request=$(jq -cn --argjson r "$request" --arg team "$above_team_limit" '$r | .environment.BUZZ_ACP_TEAM_INSTRUCTIONS=$team')
above_team_state="$tmp/team-limit-above-state"
mkdir -p "$above_team_state/env"
printf '%s\n' 'PREVIOUS="healthy-generation"' >"$above_team_state/env/$agent_id"
invoke team-limit-above "$above_team_state" stable 0 "$above_team_request"
assert_error team-limit-above 'helper: team instructions too large'
grep -Fx 'PREVIOUS="healthy-generation"' "$above_team_state/env/$agent_id" >/dev/null
[[ ! -s $FAKE_SYSTEMCTL_LOG ]]

aggregate_base=$(jq -cn --argjson r "$request" '
  $r | del(
    .environment.BUZZ_ACP_TEAM_INSTRUCTIONS,
    .environment.BUZZ_ACP_EXIT_AFTER_INACTIVITY,
    .environment.BUZZ_AGENT_DISABLED_DIR,
    .environment.BUZZ_AGENT_LOCK_FILE,
    .environment.BUZZ_AGENT_STATE_ROOT,
    .environment.SERVICE_RESULT,
    .environment.EXIT_CODE,
    .environment.EXIT_STATUS,
    .environment.BUZZ_ACP_NO_MENTION_FILTER,
    .environment.BUZZ_ACP_KINDS,
    .environment.BUZZ_ACP_CHANNELS,
    .environment.BUZZ_ACP_CONFIG,
    .environment.BUZZ_ACP_HEARTBEAT_PROMPT,
    .environment.BUZZ_ACP_HEARTBEAT_PROMPT_FILE
  )
  | .environment.BUZZ_ACP_SUBSCRIBE="mentions"
  | .environment.BUZZ_ACP_HEARTBEAT_INTERVAL="0"
')
pad_a=$(python3 -c 'print("a" * 10000, end="")')
aggregate_with_a=$(jq -cn --argjson r "$aggregate_base" --arg pad "$pad_a" '$r | .environment.PAD_A=$pad')
aggregate_size=$(jq '[.environment | to_entries[] | ((.key | utf8bytelength) + 2 + ((.value | utf8bytelength) * 6))] | add // 0' <<<"$aggregate_with_a")
remaining_aggregate=$((114688 - aggregate_size))
pad_b_key=
pad_b_size=
for key_size in $(seq 1 128); do
  if (( (remaining_aggregate - key_size - 2) % 6 == 0 )); then
    candidate_size=$(( (remaining_aggregate - key_size - 2) / 6 ))
    if (( candidate_size >= 0 && candidate_size <= 16384 )); then
      pad_b_key=$(python3 -c "print('P' * $key_size, end='')")
      pad_b_size=$candidate_size
      break
    fi
  fi
done
[[ -n $pad_b_key && -n $pad_b_size ]]
pad_b=$(python3 -c "print('b' * $pad_b_size, end='')")
aggregate_at=$(jq -cn --argjson r "$aggregate_with_a" --arg key "$pad_b_key" --arg pad "$pad_b" '$r | .environment[$key]=$pad')
invoke aggregate-limit-at "$tmp/aggregate-limit-at-state" stable 0 "$aggregate_at"
jq -e '.ok == true' "$tmp/aggregate-limit-at.out" >/dev/null
aggregate_above=$(jq -cn --argjson r "$aggregate_at" --arg key "$pad_b_key" '$r | .environment[$key] += "b"')
aggregate_above_state="$tmp/aggregate-limit-above-state"
mkdir -p "$aggregate_above_state/env"
printf '%s\n' 'PREVIOUS="aggregate-generation"' >"$aggregate_above_state/env/$agent_id"
invoke aggregate-limit-above "$aggregate_above_state" stable 0 "$aggregate_above"
assert_error aggregate-limit-above 'helper: environment too large'
grep -Fx 'PREVIOUS="aggregate-generation"' "$aggregate_above_state/env/$agent_id" >/dev/null
[[ ! -s $FAKE_SYSTEMCTL_LOG ]]

at_value_limit=$(python3 -c 'print("v" * 16384, end="")')
at_value_request=$(jq -cn --argjson r "$aggregate_base" --arg value "$at_value_limit" '$r | .environment.VALUE_BOUNDARY=$value')
invoke value-limit-at "$tmp/value-limit-at-state" stable 0 "$at_value_request"
jq -e '.ok == true' "$tmp/value-limit-at.out" >/dev/null
above_value_limit="${at_value_limit}v"
above_value_request=$(jq -cn --argjson r "$aggregate_base" --arg value "$above_value_limit" '$r | .environment.VALUE_BOUNDARY=$value')
invoke value-limit-above "$tmp/value-limit-above-state" stable 0 "$above_value_request"
assert_error value-limit-above 'helper: environment too large'

at_name_limit=$(python3 -c 'print("N" * 128, end="")')
at_name_request=$(jq -cn --argjson r "$aggregate_base" --arg key "$at_name_limit" '$r | .environment[$key]=""')
invoke name-limit-at "$tmp/name-limit-at-state" stable 0 "$at_name_request"
jq -e '.ok == true' "$tmp/name-limit-at.out" >/dev/null
above_name_limit="${at_name_limit}N"
above_name_request=$(jq -cn --argjson r "$aggregate_base" --arg key "$above_name_limit" '$r | .environment[$key]=""')
invoke name-limit-above "$tmp/name-limit-above-state" stable 0 "$above_name_request"
assert_error name-limit-above 'helper: environment too large'

entry_base=$(jq -cn --argjson r "$aggregate_base" '
  $r | del(.environment.BUZZ_ACP_AGENT_COMMAND, .environment.BUZZ_ACP_MCP_COMMAND)
')
base_entry_count=$(jq '.environment | length' <<<"$entry_base")
dummy_entry_count=$((224 - base_entry_count))
entry_limit_at=$(jq -cn --argjson r "$entry_base" --argjson count "$dummy_entry_count" '
  $r | .environment += reduce range(0; $count) as $index ({}; .["DUMMY_\($index)"]="")
')
entry_limit_at_state="$tmp/entry-limit-at-state"
invoke entry-limit-at "$entry_limit_at_state" stable 0 "$entry_limit_at"
jq -e '.ok == true' "$tmp/entry-limit-at.out" >/dev/null
entry_limit_env="$entry_limit_at_state/env/$agent_id"
[[ $(wc -l <"$entry_limit_env" | tr -d ' ') == 224 ]]
cat >"$tmp/entry-recorder" <<'EOF'
#!/bin/bash
set -euo pipefail
[[ $HOME == /home/buzz1 ]]
[[ $CODEX_HOME == /home/buzz1/.codex ]]
[[ ${BUZZ_ACP_AGENT_COMMAND-} == /module/codex-acp ]]
[[ ${CODEX_PATH-} == /module/codex ]]
EOF
chmod +x "$tmp/entry-recorder"
cat >"$tmp/exec-systemd-environment.py" <<'PY'
import json
import os
import pathlib
import sys

values = {}
for line in pathlib.Path(sys.argv[1]).read_text().splitlines():
    key, raw = line.split("=", 1)
    values[key] = json.loads(raw)
for index in range(int(sys.argv[2])):
    values[f"SYSTEMD_ENTRY_{index}"] = ""
os.execve(sys.argv[3], [sys.argv[3], sys.argv[4]], values)
PY
# 224 persisted + 25 simulated systemd + 7 net launcher-owned entries = 256.
python3 "$tmp/exec-systemd-environment.py" "$entry_limit_env" 25 \
  "$native_runner" "$tmp/entry-recorder"
set +e
python3 "$tmp/exec-systemd-environment.py" "$entry_limit_env" 26 \
  "$native_runner" "$tmp/entry-recorder" \
  >"$tmp/effective-entry-limit-above.out" 2>"$tmp/effective-entry-limit-above.err"
effective_entry_rc=$?
set -e
[[ $effective_entry_rc == 65 && ! -s $tmp/effective-entry-limit-above.out ]]
grep -Fx 'buzz-agent-run: environment too large' "$tmp/effective-entry-limit-above.err" >/dev/null
entry_limit_above=$(jq -cn --argjson r "$entry_limit_at" '$r | .environment.DUMMY_EXTRA=""')
entry_limit_above_state="$tmp/entry-limit-above-state"
mkdir -p "$entry_limit_above_state/env"
printf '%s\n' 'PREVIOUS="entry-generation"' >"$entry_limit_above_state/env/$agent_id"
invoke entry-limit-above "$entry_limit_above_state" stable 0 "$entry_limit_above"
assert_error entry-limit-above 'helper: environment too large'
grep -Fx 'PREVIOUS="entry-generation"' "$entry_limit_above_state/env/$agent_id" >/dev/null
[[ ! -s $FAKE_SYSTEMCTL_LOG ]]

active_state="$tmp/active-state"
mkdir -p "$active_state/env"
printf '%s\n' 'PREVIOUS="active-generation"' >"$active_state/env/$agent_id"
: >"$FAKE_SYSTEMCTL_LOG"
printf '%s\n' "$request" | PATH="$tmp/bin:$PATH" BUZZ_AGENT_STABILITY_CHECKS=1 BUZZ_AGENT_STABILITY_INTERVAL=0 FAKE_SYSTEMD_MODE=stable FAKE_WAS_ACTIVE=1 \
  "$helper" "$active_state" "$lifecycle_lock" "$operation_lock" >"$tmp/active.out" 2>"$tmp/active.err"
jq -e '.ok == true' "$tmp/active.out" >/dev/null
grep -Fx "stop $unit" "$FAKE_SYSTEMCTL_LOG" >/dev/null
grep -Fx "start $unit" "$FAKE_SYSTEMCTL_LOG" >/dev/null
if grep -Eq '^(is-enabled|enable|disable)( |$)' "$FAKE_SYSTEMCTL_LOG"; then
  echo 'active replacement attempted dynamic unit enablement' >&2
  exit 1
fi

invoke start-fail "$tmp/start-fail-state" start-fail 0
assert_error start-fail 'helper: systemd start failed'
[[ ! -e "$tmp/start-fail-state/env/$agent_id" ]]
grep -Fx "stop $unit" "$FAKE_SYSTEMCTL_LOG" >/dev/null

invoke inactive "$tmp/inactive-state" inactive 0
assert_error inactive 'helper: service inactive'
[[ ! -e "$tmp/inactive-state/env/$agent_id" ]]

invoke crash "$tmp/crash-state" crash 0
assert_error crash 'helper: service crashed immediately'
[[ ! -e "$tmp/crash-state/env/$agent_id" ]]

marked_rollback="$tmp/marked-rollback-state"
mkdir -p "$marked_rollback/env" "$marked_rollback/disabled"
printf '%s\n' 'PREVIOUS="disabled-generation"' >"$marked_rollback/env/$agent_id"
install -m 0600 /dev/null "$marked_rollback/disabled/$agent_id"
invoke marked-rollback "$marked_rollback" crash 0
assert_error marked-rollback 'helper: service crashed immediately'
grep -Fx 'PREVIOUS="disabled-generation"' "$marked_rollback/env/$agent_id" >/dev/null
[[ -f $marked_rollback/disabled/$agent_id ]]

rollback="$tmp/rollback-state"
mkdir -p "$rollback/env"
printf '%s\n' 'PREVIOUS="generation"' >"$rollback/env/$agent_id"
chmod 600 "$rollback/env/$agent_id"
: >"$FAKE_SYSTEMCTL_LOG"
set +e
printf '%s\n' "$request" | PATH="$tmp/bin:$PATH" BUZZ_AGENT_STABILITY_CHECKS=1 BUZZ_AGENT_STABILITY_INTERVAL=0 FAKE_SYSTEMD_MODE=crash FAKE_WAS_ACTIVE=1 \
  "$helper" "$rollback" "$lifecycle_lock" "$operation_lock" >"$tmp/rollback.out" 2>"$tmp/rollback.err"
rc=$?
set -e
[[ $rc == 0 ]]
assert_error rollback 'helper: service crashed immediately'
grep -Fx 'PREVIOUS="generation"' "$rollback/env/$agent_id" >/dev/null
[[ $(grep -Fxc "start $unit" "$FAKE_SYSTEMCTL_LOG") == 2 ]]
if grep -Eq '^(is-enabled|enable|disable)( |$)' "$FAKE_SYSTEMCTL_LOG"; then
  echo 'replacement rollback attempted dynamic unit enablement' >&2
  exit 1
fi

rollback_failure="$tmp/rollback-failure-state"
mkdir -p "$rollback_failure/env"
printf '%s\n' 'PREVIOUS="generation"' >"$rollback_failure/env/$agent_id"
: >"$FAKE_SYSTEMCTL_LOG"
set +e
printf '%s\n' "$request" | PATH="$tmp/bin:$PATH" BUZZ_AGENT_STABILITY_CHECKS=1 BUZZ_AGENT_STABILITY_INTERVAL=0 FAKE_SYSTEMD_MODE=crash FAKE_WAS_ACTIVE=1 FAKE_ROLLBACK_MV_FAIL=1 \
  "$helper" "$rollback_failure" "$lifecycle_lock" "$operation_lock" >"$tmp/rollback-failure.out" 2>"$tmp/rollback-failure.err"
rc=$?
set -e
[[ $rc == 0 ]]
assert_rollback_error rollback-failure 'helper: service crashed immediately' environment
[[ $(grep -Fxc "start $unit" "$FAKE_SYSTEMCTL_LOG") == 1 ]]

for rollback_mode in rollback-start-fail; do
  state="$tmp/$rollback_mode-state"
  mkdir -p "$state/env"
  printf '%s\n' 'PREVIOUS="generation"' >"$state/env/$agent_id"
  : >"$FAKE_SYSTEMCTL_LOG"
  printf '%s\n' "$request" | PATH="$tmp/bin:$PATH" BUZZ_AGENT_STABILITY_CHECKS=1 BUZZ_AGENT_STABILITY_INTERVAL=0 FAKE_SYSTEMD_MODE="$rollback_mode" FAKE_WAS_ACTIVE=1 \
    "$helper" "$state" "$lifecycle_lock" "$operation_lock" >"$tmp/$rollback_mode.out" 2>"$tmp/$rollback_mode.err"
  assert_rollback_error "$rollback_mode" 'helper: systemd start failed' active-state
done

start_request=$(jq -cn --arg id "$agent_id" '{operation:"start",agent_id:$id}')
mkdir -p "$tmp/stable-state/disabled"
printf '%s\n' deliberate-clean-shutdown >"$tmp/stable-state/disabled/$agent_id"
invoke explicit-start "$tmp/stable-state" stable 0 "$start_request"
jq -e '.ok == true' "$tmp/explicit-start.out" >/dev/null
grep -Fx "start $unit" "$FAKE_SYSTEMCTL_LOG" >/dev/null
[[ ! -e $tmp/stable-state/disabled/$agent_id ]]
! grep -Eq '^(is-enabled|enable|disable)( |$)' "$FAKE_SYSTEMCTL_LOG"

mkdir -p "$tmp/failed-explicit-state/disabled"
install -m 0600 /dev/null "$tmp/failed-explicit-state/disabled/$agent_id"
invoke failed-explicit-start "$tmp/failed-explicit-state" start-fail 0 "$start_request"
assert_error failed-explicit-start 'helper: systemd start failed'
[[ ! -e $tmp/failed-explicit-state/disabled/$agent_id ]]

stop_request=$(jq -cn --arg id "$agent_id" '{operation:"stop",agent_id:$id}')
invoke explicit-stop "$tmp/stable-state" stable 0 "$stop_request"
jq -e '.ok == true' "$tmp/explicit-stop.out" >/dev/null
grep -Fx "stop $unit" "$FAKE_SYSTEMCTL_LOG" >/dev/null
[[ -f $tmp/stable-state/disabled/$agent_id ]]
[[ $(stat -c %a "$tmp/stable-state/disabled/$agent_id") == 600 ]]

remove_state="$tmp/remove-state"
mkdir -p "$remove_state/env" "$remove_state/disabled"
printf '%s\n' 'REMOVE="generation"' >"$remove_state/env/$agent_id"
printf '%s\n' disabled >"$remove_state/disabled/$agent_id"
remove_request=$(jq -cn --arg id "$agent_id" '{operation:"remove",agent_id:$id}')
invoke remove "$remove_state" stable 0 "$remove_request"
jq -e '.ok == true' "$tmp/remove.out" >/dev/null
grep -Fx "stop $unit" "$FAKE_SYSTEMCTL_LOG" >/dev/null
[[ ! -e $remove_state/env/$agent_id ]]
[[ ! -e $remove_state/disabled/$agent_id ]]
! grep -Eq '^(is-enabled|enable|disable)( |$)' "$FAKE_SYSTEMCTL_LOG"

oversize_file="$tmp/oversize.json"
python3 - <<'PY' >"$oversize_file"
import json
print(json.dumps({"operation":"deploy","agent_id":"79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798","environment":{
  "HUGE":"x" * (1024 * 1024 + 1), "BUZZ_PRIVATE_KEY":"nsec1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqsmhltgl",
  "NOSTR_PRIVATE_KEY":"nsec1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqsmhltgl", "BUZZ_RELAY_URL":"wss://relay.example",
  "BUZZ_AUTH_TAG":"auth-secret-sentinel", "BUZZ_ACP_AGENT_COMMAND":"codex-acp", "BUZZ_ACP_MCP_COMMAND":"buzz-dev-mcp",
  "BUZZ_ACP_EXIT_AFTER_INACTIVITY":"7200", "BUZZ_MANAGED_AGENT_START_NONCE":"0123456789abcdef0123456789abcdef",
  "BUZZ_ACP_RESPOND_TO":"owner-only"}}))
PY
invoke oversized "$tmp/oversized-state" stable 0 "$(cat "$oversize_file")"
assert_error oversized 'helper: environment too large'

python3 - <<'PY' >"$tmp/oversized-key.json"
import json
request = {"operation":"deploy","agent_id":"79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798","environment":{
  "A" * 1048576:"", "BUZZ_PRIVATE_KEY":"nsec1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqsmhltgl",
  "NOSTR_PRIVATE_KEY":"nsec1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqsmhltgl", "BUZZ_RELAY_URL":"wss://relay.example",
  "BUZZ_AUTH_TAG":"auth-secret-sentinel", "BUZZ_ACP_AGENT_COMMAND":"codex-acp", "BUZZ_ACP_MCP_COMMAND":"buzz-dev-mcp",
  "BUZZ_ACP_EXIT_AFTER_INACTIVITY":"7200", "BUZZ_MANAGED_AGENT_START_NONCE":"0123456789abcdef0123456789abcdef",
  "BUZZ_ACP_RESPOND_TO":"owner-only"}}
print(json.dumps(request))
PY
PATH="$tmp/bin:$PATH" BUZZ_AGENT_STABILITY_CHECKS=1 BUZZ_AGENT_STABILITY_INTERVAL=0 FAKE_SYSTEMD_MODE=stable \
  "$helper" "$tmp/oversized-key-state" "$lifecycle_lock" "$operation_lock" \
  <"$tmp/oversized-key.json" >"$tmp/oversized-key.out" 2>"$tmp/oversized-key.err"
assert_error oversized-key 'helper: environment too large'

python3 - <<'PY' >"$tmp/oversized-utf8.json"
import json
request = {"operation":"deploy","agent_id":"79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798","environment":{
  "UTF8":"é" * 525000, "BUZZ_PRIVATE_KEY":"nsec1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqsmhltgl",
  "NOSTR_PRIVATE_KEY":"nsec1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqsmhltgl", "BUZZ_RELAY_URL":"wss://relay.example",
  "BUZZ_AUTH_TAG":"auth-secret-sentinel", "BUZZ_ACP_AGENT_COMMAND":"codex-acp", "BUZZ_ACP_MCP_COMMAND":"buzz-dev-mcp",
  "BUZZ_ACP_EXIT_AFTER_INACTIVITY":"7200", "BUZZ_MANAGED_AGENT_START_NONCE":"0123456789abcdef0123456789abcdef",
  "BUZZ_ACP_RESPOND_TO":"owner-only"}}
print(json.dumps(request, ensure_ascii=False))
PY
PATH="$tmp/bin:$PATH" BUZZ_AGENT_STABILITY_CHECKS=1 BUZZ_AGENT_STABILITY_INTERVAL=0 FAKE_SYSTEMD_MODE=stable \
  "$helper" "$tmp/oversized-utf8-state" "$lifecycle_lock" "$operation_lock" \
  <"$tmp/oversized-utf8.json" >"$tmp/oversized-utf8.out" 2>"$tmp/oversized-utf8.err"
assert_error oversized-utf8 'helper: environment too large'

[[ ! -s $FAKE_TEMP_MODE_LOG ]] || {
  echo "helper created temp files with unsafe modes: $(tr '\n' ' ' <"$FAKE_TEMP_MODE_LOG")" >&2
  exit 1
}

printf '%s\n' 'helper conformance tests passed'
