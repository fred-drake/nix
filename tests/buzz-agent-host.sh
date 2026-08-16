#!/usr/bin/env bash
set -euo pipefail

provider_path=$(nix eval --raw .#packages.aarch64-darwin.buzz-backend-gnomeregan)
provider_link=$(nix eval --raw '.#darwinConfigurations.macbook-pro.config.home-manager.users.fdrake.home.file.".local/bin/buzz-backend-gnomeregan".source')
test "$provider_link" = "$provider_path/bin/buzz-backend-gnomeregan"

buzz_acp_patch=$(nix eval --json --impure --expr '
  let
    f = builtins.getFlake (toString ./.);
    pkgs = f.inputs.nixpkgs.legacyPackages.aarch64-darwin;
    package = pkgs.callPackage ./apps/buzz-acp.nix {};
  in map toString package.patches
' | jq -r 'if length == 1 then .[0] else error("expected one pinned shutdown patch") end')
[[ ${buzz_acp_patch##*/} == buzz-acp-owner-shutdown-exit.patch ]]
nix build --no-link .#buzz-backend-gnomeregan .#buzz-acp .#codex .#codex-acp
nix run .#buzz-acp -- --help >/dev/null
nix run .#codex -- --version >/dev/null
nix run .#codex-acp -- --version >/dev/null

buzz_cli=$(nix build --no-link --print-out-paths --impure --expr \
  'let f = builtins.getFlake (toString ./.); pkgs = f.inputs.nixpkgs.legacyPackages.aarch64-darwin; in pkgs.callPackage ./apps/buzz-cli.nix { static = false; }')
login_bash=$(nix build --no-link --print-out-paths --impure --expr \
  'let f = builtins.getFlake (toString ./.); pkgs = f.inputs.nixpkgs.legacyPackages.aarch64-darwin; in pkgs.lib.getBin pkgs.bashInteractive')
codex_cli=$(nix build --no-link --print-out-paths .#codex)
codex_acp=$(nix build --no-link --print-out-paths .#codex-acp)
test -x "$buzz_cli/bin/buzz"
test -x "$codex_cli/bin/codex"
buzz_cli_src=$(nix eval --raw --impure --expr \
  'let f = builtins.getFlake (toString ./.); pkgs = f.inputs.nixpkgs.legacyPackages.aarch64-darwin; in (pkgs.callPackage ./apps/buzz-cli.nix { static = false; }).src.outPath')
buzz_acp_src=$(nix eval --raw --impure --expr \
  'let f = builtins.getFlake (toString ./.); pkgs = f.inputs.nixpkgs.legacyPackages.aarch64-darwin; in (pkgs.callPackage ./apps/buzz-acp.nix {}).src.outPath')
test "$buzz_cli_src" = "$buzz_acp_src"
test -f "$codex_acp/lib/node_modules/@agentclientprotocol/codex-acp/node_modules/@openai/codex/bin/codex.js"

acp_out=$(mktemp)
trap 'rm -f "$acp_out"' EXIT
{
  printf '%s\n' '{"jsonrpc":"2.0","id":"initialize","method":"initialize","params":{"protocolVersion":1,"clientCapabilities":{}}}'
  sleep 2
} | timeout 10 "$codex_acp/bin/codex-acp" >"$acp_out"
jq -e '.id == "initialize" and .result.protocolVersion == 1' "$acp_out" >/dev/null
if grep -F 'Cannot find module '\''@openai/codex/bin/codex.js'\''' "$acp_out"; then
  echo 'codex-acp could not load the packaged Codex dependency' >&2
  exit 1
fi

system_packages=$(colmena eval --impure -E '{ nodes, ... }: map toString nodes.gnomeregan.config.environment.systemPackages')
agent_exec=$(colmena eval --impure -E '{ nodes, ... }: nodes.gnomeregan.config.systemd.services."buzz-agent@".serviceConfig.ExecStart' | jq -r)
read -r -a agent_exec_words <<<"$agent_exec"
[[ ${#agent_exec_words[@]} == 2 ]]
[[ ${agent_exec_words[0]} == /nix/store/*-buzz-agent-run-*/bin/buzz-agent-run ]]
[[ ${agent_exec_words[1]} == /nix/store/*-buzz-acp-*/bin/buzz-acp ]]
if [[ $agent_exec == *BUZZ_RELAY_URL* || $agent_exec == *BUZZ_PRIVATE_KEY* || $agent_exec == *NOSTR_PRIVATE_KEY* || $agent_exec == *BUZZ_AUTH_TAG* ]]; then
  echo 'secret-bearing Buzz variables must remain in EnvironmentFile, not ExecStart argv' >&2
  exit 1
fi
buzz_package=$(printf '%s' "$system_packages" | jq -r '.[] | select(test("-buzz-cli-"))')
codex_package=$(printf '%s' "$system_packages" | jq -r '.[] | select(test("-codex-[0-9]"))')
codex_acp_package=$(printf '%s' "$system_packages" | jq -r '.[] | select(test("-codex-acp-"))')
agentctl_package=$(printf '%s' "$system_packages" | jq -r '.[] | select(test("-buzz-agentctl($|-)"))')
[[ $buzz_package == /nix/store/*-buzz-cli-* ]]
[[ $codex_package == /nix/store/*-codex-* ]]
[[ $codex_acp_package == /nix/store/*-codex-acp-* ]]
[[ $agentctl_package == /nix/store/*-buzz-agentctl ]]

# Codex snapshots the managed account's login shell, which replaces the unit's
# private PATH with the evaluated host profile. Mirror that evaluated package
# membership with the same-revision native CLI so the Darwin test runner can
# exercise login-shell lookup and execution without calling the relay.
(
  login_shell_home=$(mktemp -d)
  login_shell_profile=$(mktemp -d)
  trap 'rm -rf "$login_shell_home" "$login_shell_profile"' EXIT
  mkdir -p "$login_shell_profile/bin"
  if printf '%s' "$system_packages" | jq -e --arg buzz "$buzz_package" 'index($buzz) != null' >/dev/null; then
    ln -s "$buzz_cli/bin/buzz" "$login_shell_profile/bin/buzz"
  fi
  cat >"$login_shell_home/.bash_profile" <<'EOF'
export PATH="$LOGIN_SHELL_PROFILE/bin"
EOF
  if ! resolved=$(HOME="$login_shell_home" LOGIN_SHELL_PROFILE="$login_shell_profile" "$login_bash/bin/bash" -lc 'command -v buzz'); then
    echo 'buzz is not resolvable from the gnomeregan login-shell profile' >&2
    exit 1
  fi
  test "$resolved" = "$login_shell_profile/bin/buzz"
  HOME="$login_shell_home" LOGIN_SHELL_PROFILE="$login_shell_profile" "$login_bash/bin/bash" -lc 'buzz --help' >/dev/null
)
printf '%s' "$system_packages" | jq -e --arg buzz "$buzz_package" 'index($buzz) != null' >/dev/null
printf '%s' "$system_packages" | jq -e --arg codex "$codex_package" 'index($codex) != null' >/dev/null
printf '%s' "$system_packages" | jq -e --arg adapter "$codex_acp_package" 'index($adapter) != null' >/dev/null
colmena eval --impure -E '{ nodes, ... }: nodes.gnomeregan.config.systemd.services."buzz-agent@".serviceConfig.User' | jq -r | grep -Fx buzz1
colmena eval --impure -E '{ nodes, ... }: nodes.gnomeregan.config.systemd.services."buzz-agent@".serviceConfig.Type' | jq -r | grep -Fx exec
colmena eval --impure -E '{ nodes, ... }: nodes.gnomeregan.config.systemd.services."buzz-agent@".serviceConfig.Restart' | jq -r | grep -Fx always
colmena eval --impure -E '{ nodes, ... }: nodes.gnomeregan.config.systemd.services."buzz-agent@".serviceConfig.RestartPreventExitStatus' | jq -e '. == [42]' >/dev/null
colmena eval --impure -E '{ nodes, ... }: nodes.gnomeregan.config.systemd.services."buzz-agent@".serviceConfig.WorkingDirectory' | jq -r | grep -Fx /home/buzz1
colmena eval --impure -E '{ nodes, ... }: with nodes.gnomeregan.config.systemd.services."buzz-agent@".serviceConfig; { inherit ProtectSystem ProtectHome BindPaths ReadWritePaths NoNewPrivileges PrivateTmp; }' \
  | jq -e '.ProtectSystem == "strict" and .ProtectHome == "tmpfs" and .BindPaths == ["/home/buzz1"] and .ReadWritePaths == ["/home/buzz1", "/var/lib/buzz-agents/disabled"] and .NoNewPrivileges and .PrivateTmp' >/dev/null
colmena eval --impure -E '{ nodes, ... }: nodes.gnomeregan.config.systemd.services."buzz-agent@".wantedBy' | jq -e 'length == 0' >/dev/null
colmena eval --impure -E '{ nodes, ... }: nodes.gnomeregan.config.systemd.services.buzz-agent-restore.wantedBy' | jq -e '. == ["multi-user.target"]' >/dev/null
colmena eval --impure -E '{ nodes, ... }: nodes.gnomeregan.config.systemd.services.buzz-agent-restore.before' | jq -e 'index("multi-user.target") != null' >/dev/null
colmena eval --impure -E '{ nodes, ... }: nodes.gnomeregan.config.systemd.services.buzz-agent-restore.after' | jq -e 'index("local-fs.target") != null and index("network-online.target") != null' >/dev/null
colmena eval --impure -E '{ nodes, ... }: nodes.gnomeregan.config.systemd.services.buzz-agent-restore.serviceConfig.Type' | jq -r | grep -Fx oneshot
colmena eval --impure -E '{ nodes, ... }: nodes.gnomeregan.config.systemd.services.buzz-agent-restore.requiredBy' | jq -e 'length == 0' >/dev/null

restore_unit=$(colmena eval --impure -E '{ nodes, ... }: nodes.gnomeregan.config.systemd.units."buzz-agent-restore.service".text' | jq -r)
template_unit=$(colmena eval --impure -E '{ nodes, ... }: nodes.gnomeregan.config.systemd.units."buzz-agent@.service".text' | jq -r)
printf '%s\n' "$restore_unit" | grep -Fx 'After=local-fs.target network-online.target' >/dev/null
printf '%s\n' "$restore_unit" | grep -Fx 'Before=multi-user.target' >/dev/null
printf '%s\n' "$restore_unit" | grep -Fx 'Wants=network-online.target' >/dev/null
printf '%s\n' "$restore_unit" | grep -Fx 'Type=oneshot' >/dev/null
printf '%s\n' "$restore_unit" | grep -E '^ExecStart=/nix/store/.+-buzz-agent-restore/bin/buzz-agent-restore /var/lib/buzz-agents/env /var/lib/buzz-agents/disabled /run/lock/buzz-agent-lifecycle.lock /run/lock/buzz-agent-lifecycle-operation.lock$' >/dev/null
! printf '%s\n' "$template_unit" | grep -q '^RefuseManualStart='
printf '%s\n' "$template_unit" | grep -Fx 'EnvironmentFile=/var/lib/buzz-agents/env/%i' >/dev/null
! printf '%s\n' "$template_unit" | grep -q '^ExecCondition='
printf '%s\n' "$template_unit" | grep -F "ExecStart=$agent_exec" >/dev/null
printf '%s\n' "$template_unit" | grep -E '^ExecStopPost=\+/nix/store/.+-buzz-agent-record-clean-exit/bin/buzz-agent-record-clean-exit /var/lib/buzz-agents/disabled /run/lock/buzz-agent-lifecycle.lock %i$' >/dev/null
printf '%s\n' "$template_unit" | grep -Fx 'Restart=always' >/dev/null
printf '%s\n' "$template_unit" | grep -Fx 'RestartPreventExitStatus=42' >/dev/null
colmena eval --impure -E '{ nodes, ... }: nodes.gnomeregan.config.systemd.tmpfiles.rules' \
  | jq -e 'index("d /var/lib/buzz-agents/disabled 0700 root root -") != null and all(.[]; contains("buzz-agent-start-intents") | not)' >/dev/null
! printf '%s\n' "$template_unit" | grep -q '^WantedBy='
colmena eval --impure -E '{ nodes, ... }: builtins.attrNames nodes.gnomeregan.config.systemd.units' \
  | jq -e 'all(.[]; if startswith("buzz-agent@") then . == "buzz-agent@.service" elif startswith("buzz-agent-activate@") then false else true end)' >/dev/null
colmena eval --impure -E '{ nodes, ... }: nodes.gnomeregan.config.users.users.buzz1.extraGroups' | jq -e 'index("wheel") | not'
deploy_authorized_key=$(colmena eval --impure -E '{ nodes, ... }: nodes.gnomeregan.config.users.users.buzz-deploy.openssh.authorizedKeys.keys' | jq -re 'if length == 1 then .[0] else error("expected one restricted deploy key") end')
[[ $deploy_authorized_key =~ ^command=\"/nix/store/.+-buzz-agent-deploy-ssh/bin/buzz-agent-deploy-ssh\",restrict,no-agent-forwarding,no-port-forwarding,no-pty,no-user-rc,no-X11-forwarding\ ssh-ed25519\ AAAAC3NzaC1lZDI1NTE5AAAAIPy5EdETPOdH7LQnAQ4nwehWhrnrlrLup/PPzuhe2hF4$ ]]
colmena eval --impure -E '{ nodes, ... }: nodes.gnomeregan.config.security.sudo.extraRules' \
  | jq -e '[.[] | select(.users == ["buzz-deploy"]) | .commands[] | select(.options == ["NOPASSWD"] and (.command | test("/buzz-agent-deploy \\\"\\\"$")))] | length == 1' >/dev/null

# The target unit is x86_64-linux, so exercise its final exec-time environment
# with native packages, the declared workdir, and buzz1 identity variables. The
# Darwin test host cannot assume the target's numeric buzz1 uid.
runtime_home=$(mktemp -d)
runtime_out=$(mktemp)
timeout_bin=$(command -v timeout)
bash_bin=$(command -v bash)
cat >"$runtime_home/codex-env-probe" <<EOF
#!$bash_bin
set -euo pipefail
for name in BUZZ_RELAY_URL BUZZ_PRIVATE_KEY NOSTR_PRIVATE_KEY BUZZ_AUTH_TAG; do
  test -n "\${!name}"
done
exec "$codex_cli/bin/codex" "\$@"
EOF
chmod +x "$runtime_home/codex-env-probe"
trap 'rm -rf "$runtime_home" "$runtime_out" "$acp_out"' EXIT
{
  printf '%s\n' '{"jsonrpc":"2.0","id":"initialize","method":"initialize","params":{"protocolVersion":1,"clientCapabilities":{}}}'
  sleep 2
} | (
  cd "$runtime_home"
  env -i \
    HOME="$runtime_home" \
    USER=buzz1 \
    LOGNAME=buzz1 \
    BUZZ_ACP_AGENT_COMMAND=codex-acp \
    BUZZ_ACP_MCP_COMMAND=buzz-dev-mcp \
    CODEX_PATH=/tmp/forged-codex \
    PATH=/tmp/forged-path \
    BUZZ_ACP_AGENT_COMMAND="$codex_acp/bin/codex-acp" \
    BUZZ_ACP_MCP_COMMAND= \
    CODEX_PATH="$runtime_home/codex-env-probe" \
    PATH="$buzz_cli/bin:$codex_acp/bin:$codex_cli/bin" \
    BUZZ_RELAY_URL=wss://relay.example \
    BUZZ_PRIVATE_KEY=private-key-sentinel \
    NOSTR_PRIVATE_KEY=private-key-sentinel \
    BUZZ_AUTH_TAG=auth-tag-sentinel \
    BUZZ_ACP_MODEL=gpt-5.6-sol \
    BUZZ_ACP_SYSTEM_PROMPT=spawn-regression-sentinel \
    "$timeout_bin" 10 "$bash_bin" -c '
      set -e
      test "$(command -v buzz)" = "'"$buzz_cli"'/bin/buzz"
      buzz --help >/dev/null
      for name in BUZZ_RELAY_URL BUZZ_PRIVATE_KEY NOSTR_PRIVATE_KEY BUZZ_AUTH_TAG; do
        test -n "${!name}"
      done
      exec "$BUZZ_ACP_AGENT_COMMAND"
    '
) >"$runtime_out"
jq -e '.id == "initialize" and .result.protocolVersion == 1' "$runtime_out" >/dev/null

"$PWD/tests/buzz-provider-conformance.sh"
"$PWD/tests/buzz-helper-conformance.sh"
"$PWD/tests/buzz-agent-restore.sh"
"$PWD/tests/buzz-agent-clean-exit.sh"
"$PWD/tests/buzz-agent-lifecycle-races.sh"
"$PWD/tests/buzz-publication-contract.sh"
