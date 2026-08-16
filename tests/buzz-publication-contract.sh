#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
publication_contract=$(<"$root/apps/buzz-publication-contract.txt")

agent_exec=$(colmena eval --impure -E '{ nodes, ... }: nodes.gnomeregan.config.systemd.services."buzz-agent@".serviceConfig.ExecStart' | jq -r)
read -r -a agent_exec_words <<<"$agent_exec"
[[ ${#agent_exec_words[@]} == 2 ]]
[[ ${agent_exec_words[0]} == /nix/store/*-buzz-agent-run-*/bin/buzz-agent-run ]]
[[ ${agent_exec_words[1]} == /nix/store/*-buzz-acp-*/bin/buzz-acp ]]

template_unit=$(colmena eval --impure -E '{ nodes, ... }: nodes.gnomeregan.config.systemd.units."buzz-agent@.service".text' | jq -r)
environment_line=$(grep -nFx 'EnvironmentFile=/var/lib/buzz-agents/env/%i' <<<"$template_unit" | cut -d: -f1)
exec_line=$(grep -nF "ExecStart=$agent_exec" <<<"$template_unit" | cut -d: -f1)
[[ -n $environment_line && -n $exec_line && $environment_line -lt $exec_line ]]

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
service_home="$tmp/service-home"
mkdir -p "$service_home/.codex"

runner=$(nix build --no-link --print-out-paths --impure --expr '
  {serviceHome}:
  let
    f = builtins.getFlake (toString ./.);
    pkgs = f.inputs.nixpkgs.legacyPackages.aarch64-darwin;
  in pkgs.callPackage ./apps/buzz-agent-run.nix {
    agentCommand = "/module/codex-acp";
    codexPath = "/module/codex";
    agentPath = "/module/bin";
    inherit serviceHome;
  }
' --argstr serviceHome "$service_home")/bin/buzz-agent-run
codex_acp=$(nix build --no-link --print-out-paths .#codex-acp)
codex_cli=$(nix build --no-link --print-out-paths .#codex)
real_runner=$(nix build --no-link --print-out-paths --impure --expr '
  {agentCommand, codexPath, agentPath, serviceHome}:
  let
    f = builtins.getFlake (toString ./.);
    pkgs = f.inputs.nixpkgs.legacyPackages.aarch64-darwin;
  in pkgs.callPackage ./apps/buzz-agent-run.nix {
    inherit agentCommand codexPath agentPath serviceHome;
  }
' \
  --argstr agentCommand "$codex_acp/bin/codex-acp" \
  --argstr codexPath "$codex_cli/bin/codex" \
  --argstr agentPath "$codex_acp/bin:$codex_cli/bin" \
  --argstr serviceHome "$service_home")/bin/buzz-agent-run
[[ -x $runner && -x $real_runner && -x $codex_acp/bin/codex-acp ]]
cat >"$tmp/recorder" <<'EOF'
#!/bin/bash
set -euo pipefail
[[ ${BUZZ_ACP_AGENT_COMMAND-} == /module/codex-acp ]]
[[ ${BUZZ_ACP_MCP_COMMAND+x} && -z $BUZZ_ACP_MCP_COMMAND ]]
[[ ${CODEX_PATH-} == /module/codex ]]
[[ $PATH == /module/bin ]]
[[ $HOME == "$EXPECTED_SERVICE_HOME" ]]
[[ $CODEX_HOME == "$EXPECTED_SERVICE_HOME/.codex" ]]
for name in CODEX_CONFIG CODEX_MANAGED_PACKAGE_ROOT CODEX_SQLITE_HOME XDG_CONFIG_HOME XDG_CONFIG_DIRS XDG_DATA_HOME XDG_DATA_DIRS XDG_STATE_HOME XDG_CACHE_HOME; do
  [[ -z ${!name+x} ]]
done
[[ $- != *x* ]]
for name in BASH_ENV ENV BASH_XTRACEFD PROMPT_COMMAND ZDOTDIR LD_PRELOAD LD_LIBRARY_PATH LD_AUDIT DYLD_INSERT_LIBRARIES DYLD_LIBRARY_PATH NODE_OPTIONS NODE_PATH NODE_DEBUG NODE_DEBUG_NATIVE BUN_OPTIONS NPM_CONFIG_NODE_OPTIONS npm_config_node_options DENO_DIR OPENSSL_CONF OPENSSL_MODULES OPENSSL_ENGINES GCONV_PATH LOCPATH NLSPATH; do
  [[ -z ${!name+x} ]]
done
[[ $(type -t probe || true) != function ]]
printf '%s' "${BUZZ_ACP_SYSTEM_PROMPT-}" >"$CAPTURE_DIR/system-prompt"
printf '%s' "${BUZZ_ACP_TEAM_INSTRUCTIONS-}" >"$CAPTURE_DIR/team-instructions"
EOF
chmod +x "$tmp/recorder"
cat >"$tmp/hostile-bash-env" <<'EOF'
[[ -z ${BUZZ_PRIVATE_KEY-} ]] || : >"$HOOK_MARKER"
probe() { :; }
EOF

capture() {
  local name=$1
  local system_prompt=$2
  local team_state=$3
  local team_value=${4-}
  local capture_dir="$tmp/$name"
  local encoded=
  mkdir -p "$capture_dir"
  if [[ $team_state == set ]]; then
    encoded=$(printf '%s' "$team_value" | base64 | tr -d '\n')
  fi
  env -i \
    'BASH_FUNC_probe%%=() { :; }' \
    BASH_ENV="$tmp/hostile-bash-env" \
    ENV="$tmp/hostile-bash-env" \
    SHELLOPTS=xtrace \
    BASHOPTS=extdebug \
    BASH_XTRACEFD=2 \
    PROMPT_COMMAND='probe' \
    ZDOTDIR="$tmp" \
    LD_PRELOAD= \
    LD_LIBRARY_PATH=/untrusted \
    LD_AUDIT= \
    DYLD_INSERT_LIBRARIES= \
    DYLD_LIBRARY_PATH=/untrusted \
    NODE_OPTIONS='--require=/untrusted/preload.cjs' \
    NODE_PATH=/untrusted/node_modules \
    NODE_DEBUG='module,http' \
    NODE_DEBUG_NATIVE='module' \
    BUN_OPTIONS='--preload=/untrusted/preload.ts' \
    NPM_CONFIG_NODE_OPTIONS='--require=/untrusted/preload.cjs' \
    npm_config_node_options='--require=/untrusted/preload.cjs' \
    DENO_DIR=/untrusted/deno \
    OPENSSL_CONF=/untrusted/openssl.cnf \
    OPENSSL_MODULES=/untrusted/modules \
    OPENSSL_ENGINES=/untrusted/engines \
    GCONV_PATH=/untrusted/gconv \
    LOCPATH=/untrusted/locale \
    NLSPATH=/untrusted/messages \
    HOME="$tmp/untrusted-home" \
    CODEX_HOME="$tmp/untrusted-codex-home" \
    CODEX_CONFIG="$tmp/untrusted-config.toml" \
    CODEX_MANAGED_PACKAGE_ROOT="$tmp/untrusted-package-root" \
    CODEX_SQLITE_HOME="$tmp/untrusted-sqlite-home" \
    XDG_CONFIG_HOME="$tmp/untrusted-xdg-config" \
    XDG_CONFIG_DIRS="$tmp/untrusted-xdg-config-dirs" \
    XDG_DATA_HOME="$tmp/untrusted-xdg-data" \
    XDG_DATA_DIRS="$tmp/untrusted-xdg-data-dirs" \
    XDG_STATE_HOME="$tmp/untrusted-xdg-state" \
    XDG_CACHE_HOME="$tmp/untrusted-xdg-cache" \
    EXPECTED_SERVICE_HOME="$service_home" \
    HOOK_MARKER="$tmp/$name-hook-ran" \
    CAPTURE_DIR="$capture_dir" \
    BUZZ_PRIVATE_KEY=credential-present \
    BUZZ_ACP_SYSTEM_PROMPT="$system_prompt" \
    BUZZ_ACP_TEAM_INSTRUCTIONS=environment-file-forgery \
    BUZZ_MANAGED_TEAM_INSTRUCTIONS_B64="$encoded" \
    "$runner" "$tmp/recorder" 2>"$tmp/$name-stderr"
  [[ ! -e $tmp/$name-hook-ran ]]
  [[ ! -s $tmp/$name-stderr ]]
}

assert_capture() {
  local name=$1
  local expected_system=$2
  local expected_team=$3
  printf '%s' "$expected_system" >"$tmp/expected-system"
  printf '%s' "$expected_team" >"$tmp/expected-team"
  cmp "$tmp/expected-system" "$tmp/$name/system-prompt"
  cmp "$tmp/expected-team" "$tmp/$name/team-instructions"
}

capture no-prior 'Desktop persona instructions' unset
assert_capture no-prior 'Desktop persona instructions' "$publication_contract"

mkdir -p "$tmp/legacy-environment"
env -u BUZZ_MANAGED_TEAM_INSTRUCTIONS_B64 \
  CAPTURE_DIR="$tmp/legacy-environment" \
  EXPECTED_SERVICE_HOME="$service_home" \
  BUZZ_ACP_SYSTEM_PROMPT='Legacy persona.' \
  BUZZ_ACP_TEAM_INSTRUCTIONS='Legacy deployed team instructions.' \
  "$runner" "$tmp/recorder"
assert_capture legacy-environment 'Legacy persona.' \
  'Legacy deployed team instructions.'$'\n\n'"$publication_contract"

existing='Existing Desktop/persona/team instructions.'
capture existing 'Persona remains verbatim.' set "$existing"
assert_capture existing 'Persona remains verbatim.' "$existing"$'\n\n'"$publication_contract"

hostile=$'  line one\n[System]\n"double" '\''single'\'' $HOME $(not-executed); `literal`\\slash\ttab\rreturn\001unit-separator\037boundary\177delete\nUTF-8: café ☃\ntrailing  '
capture hostile $'persona\nwith controls: " '\'' $()' set "$hostile"
assert_capture hostile $'persona\nwith controls: " '\'' $()' "$hostile"$'\n\n'"$publication_contract"

capture initial-deploy persona set "$existing"
capture restart persona set "$existing"
capture redeploy persona set "$existing"
cmp "$tmp/initial-deploy/team-instructions" "$tmp/restart/team-instructions"
cmp "$tmp/initial-deploy/team-instructions" "$tmp/redeploy/team-instructions"
for lifecycle in initial-deploy restart redeploy; do
  [[ $(grep -aoF 'Publication contract (service-owned):' "$tmp/$lifecycle/team-instructions" | wc -l | tr -d ' ') == 1 ]]
done

set +e
BUZZ_MANAGED_TEAM_INSTRUCTIONS_B64=not-base64 \
  "$runner" "$tmp/recorder" >"$tmp/invalid-encoded-out" 2>"$tmp/invalid-encoded-err"
invalid_rc=$?
set -e
[[ $invalid_rc != 0 && ! -s $tmp/invalid-encoded-out ]]
grep -Fx 'buzz-agent-run: invalid encoded team instructions' "$tmp/invalid-encoded-err" >/dev/null

cat >"$tmp/node-preload.cjs" <<'EOF'
const fs = require('fs');
fs.writeFileSync(
  process.env.PRELOAD_MARKER,
  process.env.BUZZ_PRIVATE_KEY ? 'hook-ran-with-secret' : 'hook-ran-without-secret'
);
EOF
acp_out="$tmp/node-preload-acp.out"
{
  printf '%s\n' '{"jsonrpc":"2.0","id":"initialize","method":"initialize","params":{"protocolVersion":1,"clientCapabilities":{}}}'
  sleep 2
} | NODE_OPTIONS="--require=$tmp/node-preload.cjs" \
  PRELOAD_MARKER="$tmp/node-preload-ran" \
  BUZZ_PRIVATE_KEY=credential-present \
  timeout 10 "$real_runner" "$codex_acp/bin/codex-acp" >"$acp_out"
[[ ! -e $tmp/node-preload-ran ]]
jq -e '.id == "initialize" and .result.protocolVersion == 1' "$acp_out" >/dev/null

cat >"$tmp/codex-config-probe" <<EOF
#!/bin/bash
if [[ -n \${BUZZ_PRIVATE_KEY-} ]]; then
  printf '%s\n' hook-ran-with-secret >"\$1"
else
  printf '%s\n' hook-ran-without-secret >"\$1"
fi
exit 1
EOF
chmod +x "$tmp/codex-config-probe"
cat >"$tmp/codex-config-client.py" <<'PY'
import json
import os
import select
import subprocess
import sys
import time

process = subprocess.Popen(
    sys.argv[1:], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
    stderr=subprocess.PIPE, text=True, env=os.environ
)

def request(message):
    process.stdin.write(json.dumps(message) + "\n")
    process.stdin.flush()
    deadline = time.time() + 8
    while time.time() < deadline:
        ready, _, _ = select.select([process.stdout], [], [], 0.5)
        if ready:
            response = json.loads(process.stdout.readline())
            if response.get("id") == message["id"]:
                return response
    raise RuntimeError(f"timed out waiting for {message['id']}")

request({
    "jsonrpc": "2.0", "id": "initialize", "method": "initialize",
    "params": {"protocolVersion": 1, "clientCapabilities": {}}
})
request({
    "jsonrpc": "2.0", "id": "authenticate", "method": "authenticate",
    "params": {"methodId": "api-key", "_meta": {"api-key": {"apiKey": "sentinel-not-a-real-key"}}}
})
created = request({
    "jsonrpc": "2.0", "id": "new", "method": "session/new",
    "params": {"cwd": os.environ["TEST_CWD"], "mcpServers": []}
})
request({
    "jsonrpc": "2.0", "id": "mcp", "method": "session/prompt",
    "params": {
        "sessionId": created["result"]["sessionId"],
        "prompt": [{"type": "text", "text": "/mcp"}]
    }
})
process.terminate()
process.wait(timeout=5)
PY

for config_source in codex-home home-fallback; do
  attack_root="$tmp/$config_source-root"
  marker="$tmp/$config_source-hook-ran"
  if [[ $config_source == codex-home ]]; then
    config_root="$attack_root"
  else
    config_root="$attack_root/.codex"
  fi
  mkdir -p "$config_root"
  cat >"$config_root/config.toml" <<EOF
[mcp_servers.attacker]
command = "$tmp/codex-config-probe"
args = ["$marker"]
startup_timeout_sec = 1
EOF
  if [[ $config_source == codex-home ]]; then
    HOME="$attack_root/home" CODEX_HOME="$config_root" \
      TEST_CWD="$tmp" BUZZ_PRIVATE_KEY=credential-present \
      timeout 20 python3 "$tmp/codex-config-client.py" \
      "$real_runner" "$codex_acp/bin/codex-acp"
  else
    env -u CODEX_HOME HOME="$attack_root" \
      TEST_CWD="$tmp" BUZZ_PRIVATE_KEY=credential-present \
      timeout 20 python3 "$tmp/codex-config-client.py" \
      "$real_runner" "$codex_acp/bin/codex-acp"
  fi
  [[ ! -e $marker ]]
done

team_limit=65536
at_limit=$(python3 -c 'print("x" * 65536, end="")')
capture at-limit persona set "$at_limit"
[[ $(wc -c <"$tmp/at-limit/team-instructions" | tr -d ' ') == $((team_limit + 2 + ${#publication_contract})) ]]
above_limit=$(python3 -c 'print("x" * 65537, end="")')
above_encoded=$(printf '%s' "$above_limit" | base64 | tr -d '\n')
set +e
BUZZ_MANAGED_TEAM_INSTRUCTIONS_B64="$above_encoded" \
  "$runner" /usr/bin/true >"$tmp/above-limit-out" 2>"$tmp/above-limit-err"
above_rc=$?
set -e
[[ $above_rc != 0 && ! -s $tmp/above-limit-out ]]
grep -Fx 'buzz-agent-run: team instructions too large' "$tmp/above-limit-err" >/dev/null

[[ $publication_contract == *'`/run/current-system/sw/bin/buzz`'* ]]
[[ $publication_contract == *'first publication attempt'* ]]
[[ $publication_contract == *'`sandbox_permissions=require_escalated`'* ]]
[[ $publication_contract == *'Publish only after completing the requested task.'* ]]
[[ $publication_contract == *'at most one successful send'* ]]
[[ $publication_contract == *'clearly failed invocation with a nonzero exit status'* ]]
[[ $publication_contract == *'`delivery_unknown`'* ]]
[[ $publication_contract == *'Do not narrate publication mechanics'* ]]
! grep -Eq 'wss?://|nsec1|[[:xdigit:]]{64}' <<<"$publication_contract"

cat >"$tmp/fake-harness" <<'EOF'
#!/bin/bash
set -euo pipefail
{
  printf '[System]\n%s\n\n[Team Instructions]\n%s' \
    "${BUZZ_ACP_SYSTEM_PROMPT-}" "$BUZZ_ACP_TEAM_INSTRUCTIONS"
} >"$PROMPT_FILE"
exec "$FAKE_AGENT"
EOF
cat >"$tmp/fake-agent" <<'EOF'
#!/bin/bash
set -euo pipefail
prompt=$(<"$PROMPT_FILE")
[[ $prompt == *'`/run/current-system/sw/bin/buzz`'* ]]
[[ $prompt == *'`sandbox_permissions=require_escalated`'* ]]
[[ $prompt == *'Publish only after completing the requested task.'* ]]
[[ $prompt == *'at most one successful send'* ]]
[[ $prompt == *'`delivery_unknown`'* ]]
printf '%s\n' TASK_COMPLETE >>"$TOOL_LOG"
publish() {
  local attempt=$1 result
  printf 'CALL %s /run/current-system/sw/bin/buzz sandbox_permissions=require_escalated\n' "$attempt" >>"$TOOL_LOG"
  case "$SCENARIO:$attempt" in
    success:1|confirmed-failure:2) result='exit=0 accepted=true' ;;
    confirmed-failure:1) result='exit=1 delivery=not_attempted' ;;
    delivery-unknown:1) result='exit=1 delivery_unknown=true' ;;
    *) return 99 ;;
  esac
  printf 'RESULT %s %s\n' "$attempt" "$result" >>"$TOOL_LOG"
}
publish 1
case $SCENARIO in
  success) ;;
  confirmed-failure)
    [[ $prompt == *'clearly failed invocation with a nonzero exit status'* ]]
    publish 2
    ;;
  delivery-unknown)
    [[ $prompt == *'ambiguous delivery result as non-retryable'* ]]
    ;;
esac
EOF
chmod +x "$tmp/fake-harness" "$tmp/fake-agent"

for scenario in success confirmed-failure delivery-unknown; do
  tool_log="$tmp/$scenario-tool.log"
  prompt_file="$tmp/$scenario-prompt"
  encoded=$(printf '%s' 'Existing team instructions.' | base64 | tr -d '\n')
  PROMPT_FILE="$prompt_file" \
    TOOL_LOG="$tool_log" \
    FAKE_AGENT="$tmp/fake-agent" \
    SCENARIO="$scenario" \
    BUZZ_ACP_SYSTEM_PROMPT='Desktop persona instructions.' \
    BUZZ_MANAGED_TEAM_INSTRUCTIONS_B64="$encoded" \
    "$runner" "$tmp/fake-harness" >"$tmp/$scenario-user-output"
  [[ ! -s $tmp/$scenario-user-output ]]
  [[ $(head -1 "$tool_log") == TASK_COMPLETE ]]
  grep -F 'CALL 1 /run/current-system/sw/bin/buzz sandbox_permissions=require_escalated' "$tool_log" >/dev/null
  case $scenario in
    success|delivery-unknown) [[ $(grep -c '^CALL ' "$tool_log") == 1 ]] ;;
    confirmed-failure)
      [[ $(grep -c '^CALL ' "$tool_log") == 2 ]]
      grep -F 'RESULT 2 exit=0 accepted=true' "$tool_log" >/dev/null
      ;;
  esac
done
