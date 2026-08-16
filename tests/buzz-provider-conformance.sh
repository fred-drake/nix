#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
provider="$root/apps/scripts/buzz-backend-gnomeregan"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"
real_jq=$(command -v jq)

cat >"$tmp/bin/nak" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ $* == "key public" ]]
IFS= read -r key
case $key in
  nsec1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqsmhltgl)
    printf '%s\n' 79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798
    ;;
  nsec1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpqptcfk2)
    printf '%s\n' AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    ;;
  *) exit 1 ;;
esac
EOF
cat >"$tmp/bin/ssh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$FAKE_SSH_LOG"
[[ $* == "-o BatchMode=yes -- buzz-deploy@gnomeregan.internal.freddrake.com buzz-agent-deploy" ]]
stdin_path=$(lsof -a -p $$ -d 0 -Fn 2>/dev/null | awk '/^n/ {sub(/^n/, ""); print; exit}')
[[ -n $stdin_path && $(stat -c %a "$(dirname "$stdin_path")") == 700 ]]
while IFS= read -r temp_file; do
  [[ $(stat -c %a "$temp_file") == 600 ]]
done < <(find "$(dirname "$stdin_path")" -maxdepth 1 -type f)
if env | grep -E -q 'auth-secret-sentinel|system-prompt-sentinel|nsec1qqqq'; then
  exit 92
fi
secret_stderr='auth-secret-sentinel nsec1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqsmhltgl system-prompt-sentinel'
case ${FAKE_SSH_MODE:-success} in
  dns) printf '%s: %s\n' 'ssh: Could not resolve hostname host: nodename nor servname provided' "$secret_stderr" >&2; exit 255 ;;
  host-key) printf '%s: %s\n' 'Host key verification failed.' "$secret_stderr" >&2; exit 255 ;;
  auth) printf '%s: %s\n' 'Permission denied (publickey).' "$secret_stderr" >&2; exit 255 ;;
  connection) printf '%s: %s\n' 'ssh: connect to host host port 22: Connection refused' "$secret_stderr" >&2; exit 255 ;;
  malformed) printf '%s\n' 'not-json'; exit 0 ;;
  helper-invalid) printf '%s\n' '{"ok":false,"error":"helper: invalid request"}'; exit 0 ;;
  helper-install) printf '%s\n' '{"ok":false,"error":"helper: environment install failed"}'; exit 0 ;;
  helper-start) printf '%s\n' '{"ok":false,"error":"helper: systemd start failed"}'; exit 0 ;;
  helper-inactive) printf '%s\n' '{"ok":false,"error":"helper: service inactive"}'; exit 0 ;;
  helper-crash) printf '%s\n' '{"ok":false,"error":"helper: service crashed immediately"}'; exit 0 ;;
  helper-rollback) printf '%s\n' '{"ok":false,"error":"helper: service crashed immediately","rollback":"helper: rollback failed","rollback_step":"environment"}'; exit 0 ;;
  success)
    request=$(mktemp)
    trap 'rm -f "$request"' EXIT
    cat >"$request"
    "$REAL_JQ" -e '
      .operation == "deploy"
      and .agent_id == "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"
      and (.environment.BUZZ_MANAGED_AGENT_START_NONCE | type == "string" and length > 0)
      and (.environment | has("CODEX_PATH") | not)
      and (.environment | has("PATH") | not)
    ' "$request" >/dev/null
    effective_agent_command=$("$REAL_JQ" -r --arg unit_command "$MODULE_AGENT_COMMAND" \
      '.environment.BUZZ_ACP_AGENT_COMMAND // $unit_command' "$request")
    if [[ $effective_agent_command != "$MODULE_AGENT_COMMAND" ]]; then
      printf '%s\n' "provider environment overrode the unit ACP command: $effective_agent_command" >"$ACP_OVERRIDE_LOG"
      exit 1
    fi
    "$REAL_JQ" -e '
      .environment
      | (has("BUZZ_ACP_AGENT_COMMAND") | not)
        and (has("BUZZ_ACP_MCP_COMMAND") | not)
    ' "$request" >/dev/null
    case ${FAKE_CASE:-basic} in
      entry-limit)
        [[ $("$REAL_JQ" '.environment | length' "$request") == 224 ]]
        ;;
      full)
        "$REAL_JQ" -e '
          .environment as $e
          | ($e | del(.BUZZ_MANAGED_AGENT_START_NONCE)) == {
            "BUZZ_ACP_AGENT_ARGS":"serve,--profile,remote",
            "BUZZ_ACP_AGENT_OWNER":"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
            "BUZZ_ACP_AGENTS":"10",
            "BUZZ_ACP_IDLE_TIMEOUT":"17",
            "BUZZ_ACP_MAX_TURN_DURATION":"23",
            "BUZZ_ACP_MODEL":"gpt-5.6-sol",
            "BUZZ_ACP_NO_PRESENCE_SAFE":"allowed",
            "BUZZ_ACP_HEARTBEAT_INTERVAL":"0",
            "BUZZ_ACP_RESPOND_TO":"owner-only",
            "BUZZ_ACP_RESPOND_TO_ALLOWLIST":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            "BUZZ_ACP_SUBSCRIBE":"mentions",
            "BUZZ_ACP_SYSTEM_PROMPT":"system-prompt-sentinel",
            "BUZZ_AUTH_TAG":"auth-secret-sentinel",
            "BUZZ_PRIVATE_KEY":"nsec1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqsmhltgl",
            "BUZZ_RELAY_URL":"wss://relay.example",
            "BUZZ_MANAGED_TEAM_INSTRUCTIONS_B64":"RGVza3RvcC90ZWFtIGxpbmUgMQoicXVvdGVkIjsgJChsaXRlcmFsKQllbmQ=",
            "NOSTR_PRIVATE_KEY":"nsec1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqsmhltgl",
            "SHARED":"launch",
            "USER_SETTING":"user-value"
          }
        ' "$request" >/dev/null
        ;;
      legacy)
        "$REAL_JQ" -e '.environment.LEGACY_SETTING == "legacy-value" and .environment.BUZZ_RELAY_URL == "wss://relay.example"' "$request" >/dev/null
        ;;
      owner)
        "$REAL_JQ" -e '.environment.BUZZ_ACP_AGENT_OWNER == "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb" and (.environment | has("BUZZ_AUTH_TAG") | not)' "$request" >/dev/null
        ;;
      routing)
        "$REAL_JQ" -e '
          .environment.BUZZ_ACP_SUBSCRIBE == "mentions"
          and .environment.BUZZ_ACP_HEARTBEAT_INTERVAL == "0"
          and (.environment | has("BUZZ_ACP_NO_MENTION_FILTER") | not)
          and (.environment | has("BUZZ_ACP_KINDS") | not)
          and (.environment | has("BUZZ_ACP_CHANNELS") | not)
          and (.environment | has("BUZZ_ACP_CONFIG") | not)
          and (.environment | has("BUZZ_ACP_HEARTBEAT_PROMPT") | not)
          and (.environment | has("BUZZ_ACP_HEARTBEAT_PROMPT_FILE") | not)
        ' "$request" >/dev/null
        ;;
      always-on)
        "$REAL_JQ" -e '
          .environment.BUZZ_ACP_IDLE_TIMEOUT == "17"
          and .environment.BUZZ_ACP_MAX_TURN_DURATION == "23"
          and (.environment | has("BUZZ_ACP_EXIT_AFTER_INACTIVITY") | not)
          and (.environment | has("BUZZ_AGENT_DISABLED_DIR") | not)
          and (.environment | has("BUZZ_AGENT_LOCK_FILE") | not)
          and (.environment | has("BUZZ_AGENT_STATE_ROOT") | not)
          and (.environment | has("SERVICE_RESULT") | not)
          and (.environment | has("EXIT_CODE") | not)
          and (.environment | has("EXIT_STATUS") | not)
        ' "$request" >/dev/null
        ;;
      upstream)
        "$REAL_JQ" -e '
          .environment as $e
          | ($e | del(.BUZZ_MANAGED_AGENT_START_NONCE)) == {
            "BUZZ_ACP_AGENT_ARGS":"acp",
            "BUZZ_ACP_AGENT_OWNER":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            "BUZZ_ACP_AGENTS":"10",
            "BUZZ_ACP_DISPLAY_NAME":"worker",
            "BUZZ_ACP_LAZY_POOL":"true",
            "BUZZ_ACP_MODEL":"gpt-5",
            "BUZZ_ACP_RELAY_OBSERVER":"true",
            "BUZZ_ACP_HEARTBEAT_INTERVAL":"0",
            "BUZZ_ACP_RESPOND_TO":"owner-only",
            "BUZZ_ACP_RESPOND_TO_ALLOWLIST":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa,bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
            "BUZZ_ACP_SUBSCRIBE":"mentions",
            "BUZZ_ACP_SESSION_TITLE":"worker",
            "BUZZ_AUTH_TAG":"tag-1",
            "BUZZ_PRIVATE_KEY":"nsec1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqsmhltgl",
            "BUZZ_RELAY_URL":"wss://relay.example",
            "GOOSE_MODE":"auto",
            "GOOSE_MODEL":"gpt-5",
            "GOOSE_PROVIDER":"openai",
            "NOSTR_PRIVATE_KEY":"nsec1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqsmhltgl",
            "USER_KEY":"user-value"
          }
        ' "$request" >/dev/null
        ;;
    esac
    printf '%s\n' '{"ok":true,"unit":"buzz-agent@79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798.service"}'
    ;;
esac
EOF
chmod +x "$tmp/bin/nak" "$tmp/bin/ssh"

export REAL_JQ="$real_jq" FAKE_SSH_LOG="$tmp/ssh.log"
export MODULE_AGENT_COMMAND=/nix/store/module-owned-codex-acp/bin/codex-acp
export ACP_OVERRIDE_LOG="$tmp/acp-override.log"
: >"$FAKE_SSH_LOG"

run_case() {
  local name=$1 expected=$2 input=$3 mode=${4:-success} fake_case=${5:-basic}
  local out="$tmp/$name.out" err="$tmp/$name.err"
  set +e
  printf '%s\n' "$input" | PATH="$tmp/bin:$PATH" FAKE_SSH_MODE="$mode" FAKE_CASE="$fake_case" "$provider" >"$out" 2>"$err"
  local rc=$?
  set -e
  [[ $rc == 0 ]] || { echo "$name: expected exit 0, got $rc" >&2; return 1; }
  [[ ! -s $err ]] || { echo "$name: stderr was not empty" >&2; return 1; }
  [[ $(wc -l <"$out" | tr -d ' ') == 1 ]]
  jq -e --arg error "$expected" 'keys == ["error","ok"] and .ok == false and .error == $error' "$out" >/dev/null
  ! grep -E -q 'auth-secret-sentinel|legacy-auth-secret|system-prompt-sentinel|nsec1qqqq' "$out" "$err" "$FAKE_SSH_LOG"
}

run_success_case() {
  local name=$1 input=$2 fake_case=${3:-basic}
  local out="$tmp/$name.out" err="$tmp/$name.err"
  printf '%s\n' "$input" | PATH="$tmp/bin:$PATH" FAKE_SSH_MODE=success FAKE_CASE="$fake_case" \
    "$provider" >"$out" 2>"$err"
  [[ ! -s $err ]]
  jq -e 'keys == ["agent_id","ok"] and .ok == true' "$out" >/dev/null
}

base=$(jq -c . "$root/tests/fixtures/buzz-provider-full-launch.json")
official_provider=${BUZZ_OFFICIAL_KUBERNETES_PROVIDER:-/Applications/Buzz.app/Contents/MacOS/buzz-backend-kubernetes}
[[ -x $official_provider ]]
KUBECONFIG=/nonexistent/kubeconfig-for-fixture-tests "$official_provider" \
  <"$root/tests/fixtures/buzz-provider-upstream-full-launch.json" >"$tmp/upstream.out" 2>"$tmp/upstream.err"
[[ ! -s $tmp/upstream.err && $(wc -l <"$tmp/upstream.out" | tr -d ' ') == 1 ]]
jq -e 'keys == ["error","ok"] and .ok == false and (.error | contains("kubeconfig"))' "$tmp/upstream.out" >/dev/null

printf '%s\n' '{"op":"info"}' | PATH="$tmp/bin:$PATH" "$provider" >"$tmp/info.out" 2>"$tmp/info.err"
jq -e '
  .ok == true
  and (.config_schema.properties | has("inactivity_seconds") | not)
' "$tmp/info.out" >/dev/null
run_case invalid-request 'provider: invalid request' '{}'
run_case identity-derivation 'provider: identity derivation failed' "$(jq -c '.agent.private_key_nsec="nsec1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqsmhltgq"' <<<"$base")"
run_case invalid-derived 'provider: invalid derived identity' "$(jq -c '.agent.private_key_nsec="nsec1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpqptcfk2"' <<<"$base")"
run_case relay-mesh 'provider: relay-mesh conflict' "$(jq -c '.agent.provider=" relay-mesh "' <<<"$base")"
run_case missing-owner 'provider: missing owner' "$(jq -c '.agent.auth_tag=null | .agent.launch.owner_pubkey=null' <<<"$base")"
run_case invalid-owner 'provider: invalid owner' "$(jq -c '.agent.auth_tag=null | .agent.launch.owner_pubkey="not-a-pubkey"' <<<"$base")"
run_case invalid-allowlist 'provider: invalid allowlist' "$(jq -c '.agent.respond_to_allowlist=["not-a-pubkey"]' <<<"$base")"
run_case presence 'provider: presence suppression refused' "$(jq -c '.agent.launch.env.BUZZ_ACP_NO_PRESENCE="1"' <<<"$base")"
run_case invalid-key 'provider: invalid environment' "$(jq -c '.agent.launch.env["bad.key"]="value"' <<<"$base")"
for startup_key in \
  BASH_ENV ENV SHELLOPTS BASHOPTS BASH_XTRACEFD PS4 PROMPT_COMMAND ZDOTDIR \
  LD_PRELOAD LD_LIBRARY_PATH LD_AUDIT DYLD_INSERT_LIBRARIES DYLD_LIBRARY_PATH \
  NODE_OPTIONS NODE_PATH NODE_DEBUG NODE_DEBUG_NATIVE BUN_OPTIONS \
  NPM_CONFIG_NODE_OPTIONS npm_config_node_options DENO_DIR \
  OPENSSL_CONF OPENSSL_MODULES OPENSSL_ENGINES GCONV_PATH LOCPATH NLSPATH \
  HOME CODEX_HOME CODEX_CONFIG CODEX_MANAGED_PACKAGE_ROOT CODEX_SQLITE_HOME \
  XDG_CONFIG_HOME XDG_CONFIG_DIRS XDG_DATA_HOME XDG_DATA_DIRS \
  XDG_STATE_HOME XDG_CACHE_HOME; do
  run_case "startup-$startup_key" 'provider: invalid environment' \
    "$(jq -c --arg key "$startup_key" '.agent.launch.env[$key]="injection"' <<<"$base")"
done
run_case function-export 'provider: invalid environment' \
  "$(jq -c '.agent.launch.env["BASH_FUNC_probe%%"]="() { :; }"' <<<"$base")"
run_case nul-team-instructions 'provider: invalid environment' \
  "$(jq -c '.agent.launch.policy_env.BUZZ_ACP_TEAM_INSTRUCTIONS="prefix\u0000suffix"' <<<"$base")"
below_team_limit=$(python3 -c 'print("x" * 65535, end="")')
at_team_limit=$(python3 -c 'print("x" * 65536, end="")')
above_team_limit=$(python3 -c 'print("x" * 65537, end="")')
run_success_case team-limit-below \
  "$(jq -c --arg team "$below_team_limit" '.agent.launch.env.BUZZ_ACP_TEAM_INSTRUCTIONS=$team' <<<"$base")"
run_success_case team-limit-at \
  "$(jq -c --arg team "$at_team_limit" '.agent.launch.env.BUZZ_ACP_TEAM_INSTRUCTIONS=$team' <<<"$base")"
run_case team-limit-above 'provider: team instructions too large' \
  "$(jq -c --arg team "$above_team_limit" '.agent.launch.env.BUZZ_ACP_TEAM_INSTRUCTIONS=$team' <<<"$base")"
# The fixture renders 20 persisted entries before these boundary fillers.
entry_limit_at=$(jq -c --argjson count $((224 - 20)) '
  .agent.launch.env += reduce range(0; $count) as $index ({}; .["ENTRY_\($index)"]="")
' <<<"$base")
run_success_case entry-limit-at "$entry_limit_at" entry-limit
entry_limit_above=$(jq -c '.agent.launch.env.ENTRY_EXTRA=""' <<<"$entry_limit_at")
run_case entry-limit-above 'provider: environment too large' "$entry_limit_above"
run_case access 'provider: unsupported access policy' "$(jq -c '.agent.respond_to="anyone"' <<<"$base")"
run_case command 'provider: unsupported launch command' "$(jq -c '.agent.launch.command="goose"' <<<"$base")"
run_success_case ignored-inactivity-zero "$(jq -c '.provider_config.inactivity_seconds=0' <<<"$base")"
run_success_case ignored-inactivity-negative "$(jq -c '.provider_config.inactivity_seconds=-1' <<<"$base")"
run_case dns 'ssh: name resolution failed' "$base" dns
run_case host-key 'ssh: host key verification failed' "$base" host-key
run_case auth 'ssh: authentication failed' "$base" auth
run_case connection 'ssh: connection failed' "$base" connection
run_case helper-invalid 'helper: invalid request' "$base" helper-invalid
run_case helper-install 'helper: environment install failed' "$base" helper-install
run_case helper-start 'helper: systemd start failed' "$base" helper-start
run_case helper-inactive 'helper: service inactive' "$base" helper-inactive
run_case helper-crash 'helper: service crashed immediately' "$base" helper-crash

set +e
printf '%s\n' "$base" | PATH="$tmp/bin:$PATH" FAKE_SSH_MODE=helper-rollback "$provider" >"$tmp/helper-rollback.out" 2>"$tmp/helper-rollback.err"
rc=$?
set -e
[[ $rc == 0 && ! -s $tmp/helper-rollback.err ]]
jq -e '
  keys == ["error","ok","rollback","rollback_step"]
  and .ok == false
  and .error == "helper: service crashed immediately"
  and .rollback == "helper: rollback failed"
  and .rollback_step == "environment"
' "$tmp/helper-rollback.out" >/dev/null

run_case helper-malformed 'helper: invalid response' "$base" malformed

python3 - "$root/tests/fixtures/buzz-provider-full-launch.json" <<'PY' >"$tmp/oversized.json"
import json, sys
with open(sys.argv[1]) as f:
    request = json.load(f)
request["agent"]["launch"]["env"]["HUGE"] = "x" * 1049000
print(json.dumps(request))
PY
set +e
PATH="$tmp/bin:$PATH" "$provider" <"$tmp/oversized.json" >"$tmp/oversized.out" 2>"$tmp/oversized.err"
rc=$?
set -e
[[ $rc == 0 && ! -s $tmp/oversized.err ]]
jq -e 'keys == ["error","ok"] and .ok == false and .error == "provider: environment too large"' "$tmp/oversized.out" >/dev/null

python3 - "$root/tests/fixtures/buzz-provider-full-launch.json" <<'PY' >"$tmp/oversized-key.json"
import json, sys
with open(sys.argv[1]) as f:
    request = json.load(f)
request["agent"]["launch"]["env"]["A" * 1048576] = ""
print(json.dumps(request))
PY
PATH="$tmp/bin:$PATH" "$provider" <"$tmp/oversized-key.json" >"$tmp/oversized-key.out" 2>"$tmp/oversized-key.err"
jq -e 'keys == ["error","ok"] and .ok == false and .error == "provider: environment too large"' "$tmp/oversized-key.out" >/dev/null

python3 - "$root/tests/fixtures/buzz-provider-full-launch.json" <<'PY' >"$tmp/oversized-utf8.json"
import json, sys
with open(sys.argv[1]) as f:
    request = json.load(f)
request["agent"]["launch"]["env"]["UTF8"] = "é" * 525000
print(json.dumps(request, ensure_ascii=False))
PY
PATH="$tmp/bin:$PATH" "$provider" <"$tmp/oversized-utf8.json" >"$tmp/oversized-utf8.out" 2>"$tmp/oversized-utf8.err"
jq -e 'keys == ["error","ok"] and .ok == false and .error == "provider: environment too large"' "$tmp/oversized-utf8.out" >/dev/null

: >"$FAKE_SSH_LOG"
PATH="$tmp/bin:$PATH" FAKE_CASE=full "$provider" <"$root/tests/fixtures/buzz-provider-full-launch.json" >"$tmp/full.out" 2>"$tmp/full.err"
if ! jq -e 'keys == ["agent_id","ok"] and .ok == true' "$tmp/full.out" >/dev/null; then
  [[ ! -s $ACP_OVERRIDE_LOG ]] || cat "$ACP_OVERRIDE_LOG" >&2
  exit 1
fi
[[ ! -s $tmp/full.err ]]
[[ $(wc -l <"$FAKE_SSH_LOG" | tr -d ' ') == 1 ]]
if grep -E -q 'auth-secret-sentinel|system-prompt-sentinel|nsec1qqqq' "$tmp/full.out" "$tmp/full.err" "$FAKE_SSH_LOG"; then
  echo 'full launch leaked a secret sentinel' >&2
  exit 1
fi

: >"$FAKE_SSH_LOG"
jq '
  .agent.launch.policy_env.BUZZ_ACP_SUBSCRIBE="config"
  | .agent.launch.env.BUZZ_ACP_SUBSCRIBE="all"
  | .agent.launch.policy_env.BUZZ_ACP_NO_MENTION_FILTER="1"
  | .agent.launch.env.BUZZ_ACP_KINDS="1,7"
  | .agent.launch.env.BUZZ_ACP_CHANNELS="00000000-0000-0000-0000-000000000000"
  | .agent.launch.env.BUZZ_ACP_CONFIG="/tmp/caller-buzz-acp.toml"
  | .agent.launch.env.BUZZ_ACP_HEARTBEAT_INTERVAL="300"
  | .agent.launch.policy_env.BUZZ_ACP_HEARTBEAT_PROMPT="caller prompt"
  | .agent.launch.env.BUZZ_ACP_HEARTBEAT_PROMPT_FILE="/tmp/caller-heartbeat"
' "$root/tests/fixtures/buzz-provider-full-launch.json" \
  | PATH="$tmp/bin:$PATH" FAKE_CASE=routing "$provider" >"$tmp/routing.out" 2>"$tmp/routing.err"
jq -e '.ok == true' "$tmp/routing.out" >/dev/null
[[ ! -s $tmp/routing.err ]]

: >"$FAKE_SSH_LOG"
jq '
  .agent.idle_timeout_seconds=7200
  | .provider_config.inactivity_seconds=7200
  | .agent.launch.policy_env.BUZZ_ACP_EXIT_AFTER_INACTIVITY="7200"
  | .agent.launch.env.BUZZ_ACP_EXIT_AFTER_INACTIVITY="1"
  | .agent.launch.env.BUZZ_AGENT_DISABLED_DIR="/tmp/caller-disabled"
  | .agent.launch.policy_env.BUZZ_AGENT_LOCK_FILE="/tmp/caller-lock"
  | .agent.launch.policy_env.BUZZ_AGENT_STATE_ROOT="/tmp/caller-state"
  | .agent.launch.policy_env.SERVICE_RESULT="exit-code"
  | .agent.launch.policy_env.EXIT_CODE="exited"
  | .agent.launch.policy_env.EXIT_STATUS="42"
' "$root/tests/fixtures/buzz-provider-full-launch.json" \
  | PATH="$tmp/bin:$PATH" FAKE_CASE=always-on "$provider" >"$tmp/always-on.out" 2>"$tmp/always-on.err"
jq -e '.ok == true' "$tmp/always-on.out" >/dev/null
[[ ! -s $tmp/always-on.err ]]

: >"$FAKE_SSH_LOG"
jq '
  .agent.private_key_nsec="nsec1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqsmhltgl"
  | .agent.launch.command="codex-acp"
  | .agent.respond_to="owner-only"
' "$root/tests/fixtures/buzz-provider-upstream-full-launch.json" \
  | PATH="$tmp/bin:$PATH" FAKE_CASE=upstream "$provider" >"$tmp/upstream-custom.out" 2>"$tmp/upstream-custom.err"
jq -e '.ok == true' "$tmp/upstream-custom.out" >/dev/null

: >"$FAKE_SSH_LOG"
PATH="$tmp/bin:$PATH" FAKE_CASE=legacy "$provider" <"$root/tests/fixtures/buzz-provider-legacy.json" >"$tmp/legacy.out" 2>"$tmp/legacy.err"
jq -e '.ok == true' "$tmp/legacy.out" >/dev/null

: >"$FAKE_SSH_LOG"
jq '.agent.auth_tag=null' "$root/tests/fixtures/buzz-provider-full-launch.json" \
  | PATH="$tmp/bin:$PATH" FAKE_CASE=owner "$provider" >"$tmp/owner.out" 2>"$tmp/owner.err"
jq -e '.ok == true' "$tmp/owner.out" >/dev/null

printf '%s\n' 'provider conformance tests passed'
