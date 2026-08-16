{pkgs}: let
  recordCleanExit = pkgs.writeShellApplication {
    name = "buzz-agent-record-clean-exit";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.util-linux
    ];
    text = builtins.readFile ../apps/scripts/buzz-agent-record-clean-exit;
  };
  restoreAgents = pkgs.writeShellApplication {
    name = "buzz-agent-restore";
    runtimeInputs = [
      pkgs.systemd
      pkgs.util-linux
    ];
    text = builtins.readFile ../apps/scripts/buzz-agent-restore;
  };
  deployCore = pkgs.writeShellApplication {
    name = "buzz-agent-deploy-core";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
      pkgs.nak
      pkgs.systemd
      pkgs.util-linux
    ];
    text = builtins.readFile ../apps/scripts/buzz-agent-deploy;
  };
  deployHelper = pkgs.writeShellApplication {
    name = "buzz-agent-deploy";
    runtimeInputs = [deployCore];
    text = ''
      exec buzz-agent-deploy-core \
        /var/lib/buzz-agents \
        /run/lock/buzz-agent-lifecycle.lock \
        /run/lock/buzz-agent-lifecycle-operation.lock
    '';
  };
  agentCtl = pkgs.writeShellApplication {
    name = "buzz-agentctl";
    text = ''
      deploy_helper=${deployHelper}/bin/buzz-agent-deploy
      jq_bin=${pkgs.jq}/bin/jq
      mktemp_bin=${pkgs.coreutils}/bin/mktemp
      cat_bin=${pkgs.coreutils}/bin/cat
      rm_bin=${pkgs.coreutils}/bin/rm
      ${builtins.readFile ../apps/scripts/buzz-agentctl}
    '';
  };
  testAgent = pkgs.writeShellApplication {
    name = "buzz-agent-systemd-test-agent";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      agent_id=$1
      [[ -d /run/buzz-agent-invocations && -d /run/buzz-agent-generations ]]
      count_file=/run/buzz-agent-invocations/$agent_id
      count=0
      if [[ -f $count_file ]]; then
        read -r count < "$count_file"
      fi
      count=$((count + 1))
      printf '%s\n' "$count" > "$count_file"
      printf '%s\n' "''${GENERATION:-none}" > "/run/buzz-agent-generations/$agent_id"

      case "$MODE" in
        owner-shutdown)
          exit 42
          ;;
        clean)
          exit 0
          ;;
        crash-once)
          if ((count == 1)); then
            exit 1
          fi
          exec sleep infinity
          ;;
        hold)
          exec sleep infinity
          ;;
        *)
          exit 64
          ;;
      esac
    '';
  };
  markedAtBoot = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
  restoredAtBoot = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb";
  ownerShutdown = "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc";
  ordinaryClean = "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd";
  crashRestart = "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee";
  missingAgent = "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
  deployAgent = "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798";
  deployRequest = generation:
    builtins.toJSON {
      operation = "deploy";
      agent_id = deployAgent;
      environment = {
        BUZZ_PRIVATE_KEY = "nsec1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqsmhltgl";
        NOSTR_PRIVATE_KEY = "nsec1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqsmhltgl";
        BUZZ_RELAY_URL = "wss://relay.example";
        BUZZ_AUTH_TAG = "test-authorization";
        BUZZ_ACP_AGENT_COMMAND = "codex-acp";
        BUZZ_ACP_RESPOND_TO = "owner-only";
        BUZZ_ACP_MCP_COMMAND = "buzz-dev-mcp";
        BUZZ_MANAGED_AGENT_START_NONCE = "0123456789abcdef0123456789abcdef";
        MODE = "hold";
        GENERATION = generation;
      };
    };
  removeRequest = builtins.toJSON {
    operation = "remove";
    agent_id = deployAgent;
  };
in
  pkgs.testers.runNixOSTest {
    name = "buzz-agent-systemd-lifecycle";

    nodes.machine = {lib, ...}: {
      environment.systemPackages = [agentCtl pkgs.jq];

      system.activationScripts.buzzAgentIntegrationFixture = lib.stringAfter ["users"] ''
        install -d -m 0700 /var/lib/buzz-agents/env /var/lib/buzz-agents/disabled
        printf '%s\n' 'MODE=hold' > /var/lib/buzz-agents/env/${markedAtBoot}
        printf '%s\n' 'MODE=hold' > /var/lib/buzz-agents/env/${restoredAtBoot}
        install -m 0600 /dev/null /var/lib/buzz-agents/disabled/${markedAtBoot}
      '';

      systemd = {
        tmpfiles.rules = [
          "d /run/buzz-agent-generations 1777 root root -"
          "d /run/buzz-agent-invocations 1777 root root -"
        ];

        services = {
          buzz-agent-restore = {
            description = "Restore managed Buzz agents after boot (integration test)";
            wantedBy = ["multi-user.target"];
            before = ["multi-user.target"];
            after = ["local-fs.target"];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${restoreAgents}/bin/buzz-agent-restore /var/lib/buzz-agents/env /var/lib/buzz-agents/disabled /run/lock/buzz-agent-lifecycle.lock /run/lock/buzz-agent-lifecycle-operation.lock";
            };
          };

          "buzz-agent@" = {
            description = "Buzz lifecycle integration fixture %i";
            serviceConfig = {
              Type = "exec";
              User = "nobody";
              EnvironmentFile = "/var/lib/buzz-agents/env/%i";
              ExecStart = "${testAgent}/bin/buzz-agent-systemd-test-agent %i";
              ExecStopPost = "+${recordCleanExit}/bin/buzz-agent-record-clean-exit /var/lib/buzz-agents/disabled /run/lock/buzz-agent-lifecycle.lock %i";
              Restart = "always";
              RestartPreventExitStatus = [42];
              RestartSec = "100ms";
            };
          };
        };
      };
    };

    testScript = ''
      start_all()
      machine.wait_for_unit("multi-user.target")

      with subtest("boot restore skips a marked instance and activates an unmarked one"):
          machine.succeed("test -f /var/lib/buzz-agents/disabled/${markedAtBoot}")
          machine.succeed("test ! -e /run/buzz-agent-invocations/${markedAtBoot}")
          machine.fail("systemctl is-active buzz-agent@${markedAtBoot}.service")
          machine.wait_for_unit("buzz-agent@${restoredAtBoot}.service")
          machine.succeed("test $(cat /run/buzz-agent-invocations/${restoredAtBoot}) -eq 1")

      # NixOS switch-to-configuration stops a changed active template instance
      # under the old configuration and starts it directly under the new one.
      with subtest("NixOS changed-unit stop/start reactivates an active template instance"):
          machine.succeed("printf '%s\\n' MODE=hold GENERATION=switched > /var/lib/buzz-agents/env/${restoredAtBoot}")
          machine.succeed("systemctl stop buzz-agent@${restoredAtBoot}.service")
          machine.succeed("systemctl start buzz-agent@${restoredAtBoot}.service")
          machine.wait_for_unit("buzz-agent@${restoredAtBoot}.service")
          machine.succeed("test $(cat /run/buzz-agent-invocations/${restoredAtBoot}) -eq 2")
          machine.succeed("grep -Fx switched /run/buzz-agent-generations/${restoredAtBoot}")
          machine.succeed("test ! -e /var/lib/buzz-agents/disabled/${restoredAtBoot}")

      with subtest("status 42 records a marker and suppresses restart"):
          machine.succeed("printf '%s\\n' MODE=owner-shutdown > /var/lib/buzz-agents/env/${ownerShutdown}")
          machine.execute("systemctl start buzz-agent@${ownerShutdown}.service")
          machine.wait_until_succeeds("test -f /var/lib/buzz-agents/disabled/${ownerShutdown}")
          machine.succeed("test $(cat /run/buzz-agent-invocations/${ownerShutdown}) -eq 1")
          machine.succeed("test $(systemctl show -P ExecMainStatus buzz-agent@${ownerShutdown}.service) -eq 42")
          machine.succeed("test $(systemctl show -P NRestarts buzz-agent@${ownerShutdown}.service) -eq 0")

      with subtest("agentctl recovery persists across reboot"):
          machine.succeed("printf '%s\\n' MODE=hold > /var/lib/buzz-agents/env/${ownerShutdown}")
          machine.succeed("BUZZ_AGENT_STABILITY_CHECKS=1 BUZZ_AGENT_STABILITY_INTERVAL=0 sudo buzz-agentctl start ${ownerShutdown}")
          machine.wait_for_unit("buzz-agent@${ownerShutdown}.service")
          machine.succeed("test ! -e /var/lib/buzz-agents/disabled/${ownerShutdown}")
          machine.succeed("systemctl stop buzz-agent@${ownerShutdown}.service")
          machine.shutdown()
          machine.start()
          machine.wait_for_unit("multi-user.target")
          machine.wait_for_unit("buzz-agent@${ownerShutdown}.service")
          machine.succeed("test ! -e /var/lib/buzz-agents/disabled/${ownerShutdown}")

      with subtest("agentctl validates requests and fails when the helper reports failure"):
          machine.fail("buzz-agentctl")
          machine.fail("buzz-agentctl restart ${ownerShutdown}")
          machine.fail("buzz-agentctl start AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")
          machine.fail("buzz-agentctl start ${ownerShutdown} extra")
          machine.fail("sudo -u nobody buzz-agentctl start ${ownerShutdown}")
          machine.fail("BUZZ_AGENT_STABILITY_CHECKS=1 BUZZ_AGENT_STABILITY_INTERVAL=0 buzz-agentctl start ${missingAgent} > /tmp/agentctl-failure.json 2> /tmp/agentctl-failure.err")
          machine.succeed("jq -e '.ok == false and .error == \"helper: systemd start failed\"' /tmp/agentctl-failure.json")
          machine.succeed("test ! -s /tmp/agentctl-failure.err")

      with subtest("deploy and redeploy run the installed environment generation"):
          machine.succeed("""printf '%s\\n' ${pkgs.lib.escapeShellArg (deployRequest "deployed")} | BUZZ_AGENT_STABILITY_CHECKS=1 BUZZ_AGENT_STABILITY_INTERVAL=0 ${deployHelper}/bin/buzz-agent-deploy | jq -e '.ok == true'""")
          machine.wait_for_unit("buzz-agent@${deployAgent}.service")
          machine.succeed("grep -Fx deployed /run/buzz-agent-generations/${deployAgent}")
          machine.succeed("""printf '%s\\n' ${pkgs.lib.escapeShellArg (deployRequest "redeployed")} | BUZZ_AGENT_STABILITY_CHECKS=1 BUZZ_AGENT_STABILITY_INTERVAL=0 ${deployHelper}/bin/buzz-agent-deploy | jq -e '.ok == true'""")
          machine.wait_for_unit("buzz-agent@${deployAgent}.service")
          machine.succeed("grep -Fx redeployed /run/buzz-agent-generations/${deployAgent}")
          machine.succeed("test $(cat /run/buzz-agent-invocations/${deployAgent}) -eq 2")

      with subtest("remove leaves the deployment absent and stopped"):
          machine.succeed("""printf '%s\\n' ${pkgs.lib.escapeShellArg removeRequest} | ${deployHelper}/bin/buzz-agent-deploy | jq -e '.ok == true'""")
          machine.succeed("test ! -e /var/lib/buzz-agents/env/${deployAgent}")
          machine.succeed("test ! -e /var/lib/buzz-agents/disabled/${deployAgent}")
          machine.fail("systemctl is-active buzz-agent@${deployAgent}.service")
          machine.fail("systemctl start buzz-agent@${deployAgent}.service")
          machine.fail("systemctl is-active buzz-agent@${deployAgent}.service")

      with subtest("ordinary status 0 restarts without creating a marker"):
          machine.succeed("printf '%s\\n' MODE=clean > /var/lib/buzz-agents/env/${ordinaryClean}")
          machine.succeed("systemctl start buzz-agent@${ordinaryClean}.service")
          machine.wait_until_succeeds("test $(cat /run/buzz-agent-invocations/${ordinaryClean}) -ge 2")
          machine.succeed("test ! -e /var/lib/buzz-agents/disabled/${ordinaryClean}")
          machine.succeed("test $(systemctl show -P NRestarts buzz-agent@${ordinaryClean}.service) -ge 1")

          machine.succeed("systemctl stop buzz-agent@${ordinaryClean}.service")
          machine.succeed("cp /run/buzz-agent-invocations/${ordinaryClean} /run/ordinary-clean-stopped-count")
          machine.sleep(1)
          machine.succeed("cmp /run/ordinary-clean-stopped-count /run/buzz-agent-invocations/${ordinaryClean}")
          machine.fail("systemctl is-active buzz-agent@${ordinaryClean}.service")

      with subtest("a crash creates no marker and is restarted"):
          machine.succeed("printf '%s\\n' MODE=crash-once > /var/lib/buzz-agents/env/${crashRestart}")
          machine.succeed("systemctl start buzz-agent@${crashRestart}.service")
          machine.wait_until_succeeds("test $(cat /run/buzz-agent-invocations/${crashRestart}) -ge 2")
          machine.wait_for_unit("buzz-agent@${crashRestart}.service")
          machine.succeed("test ! -e /var/lib/buzz-agents/disabled/${crashRestart}")
          machine.succeed("test $(systemctl show -P NRestarts buzz-agent@${crashRestart}.service) -ge 1")
    '';
  }
