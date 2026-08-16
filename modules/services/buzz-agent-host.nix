{
  config,
  lib,
  pkgs,
  ...
}: let
  buzzAcp = pkgs.callPackage ../../apps/buzz-acp.nix {};
  buzzCli = pkgs.callPackage ../../apps/buzz-cli.nix {};
  codexCli = pkgs.callPackage ../../apps/codex.nix {};
  codexAcp = pkgs.callPackage ../../apps/codex-acp.nix {
    npm-packages = import ../../apps/fetcher/npm-packages.nix;
  };
  buzzAgentDeployCore = pkgs.writeShellApplication {
    name = "buzz-agent-deploy-core";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
      pkgs.nak
      pkgs.systemd
      pkgs.util-linux
    ];
    text = builtins.readFile ../../apps/scripts/buzz-agent-deploy;
  };
  buzzAgentDeploy = pkgs.writeShellApplication {
    name = "buzz-agent-deploy";
    runtimeInputs = [buzzAgentDeployCore];
    text = ''
      exec buzz-agent-deploy-core \
        /var/lib/buzz-agents \
        /run/lock/buzz-agent-lifecycle.lock \
        /run/lock/buzz-agent-lifecycle-operation.lock
    '';
  };
  buzzAgentCtl = pkgs.writeShellApplication {
    name = "buzz-agentctl";
    text = ''
      deploy_helper=${buzzAgentDeploy}/bin/buzz-agent-deploy
      jq_bin=${pkgs.jq}/bin/jq
      mktemp_bin=${pkgs.coreutils}/bin/mktemp
      cat_bin=${pkgs.coreutils}/bin/cat
      rm_bin=${pkgs.coreutils}/bin/rm
      ${builtins.readFile ../../apps/scripts/buzz-agentctl}
    '';
  };
  buzzAgentDeploySsh = pkgs.writeShellApplication {
    name = "buzz-agent-deploy-ssh";
    runtimeInputs = [pkgs.coreutils];
    text = builtins.readFile ../../apps/scripts/buzz-agent-deploy-ssh;
  };
  buzzAgentRestore = pkgs.writeShellApplication {
    name = "buzz-agent-restore";
    runtimeInputs = [pkgs.systemd pkgs.util-linux];
    text = builtins.readFile ../../apps/scripts/buzz-agent-restore;
  };
  buzzAgentRecordCleanExit = pkgs.writeShellApplication {
    name = "buzz-agent-record-clean-exit";
    runtimeInputs = [pkgs.coreutils pkgs.util-linux];
    text = builtins.readFile ../../apps/scripts/buzz-agent-record-clean-exit;
  };
  buzzAgentRun = pkgs.callPackage ../../apps/buzz-agent-run.nix {
    agentCommand = "${codexAcp}/bin/codex-acp";
    codexPath = "${codexCli}/bin/codex";
    agentPath = agentPathValue;
    serviceHome = "/home/buzz1";
    static = true;
  };
  agentPath = [
    pkgs.coreutils
    pkgs.findutils
    pkgs.gnugrep
    pkgs.gnused
    pkgs.systemd
    buzzCli
    codexAcp
    codexCli
  ];
  agentPathValue = lib.makeBinPath agentPath;
in {
  options.services.buzzAgentHost.deployAuthorizedKeys = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPy5EdETPOdH7LQnAQ4nwehWhrnrlrLup/PPzuhe2hF4"
    ];
    description = "Public keys allowed to invoke the restricted Buzz deployment transport.";
  };

  config = {
    users = {
      groups.buzz1 = {};
      users = {
        buzz1 = {
          isSystemUser = true;
          group = "buzz1";
          home = "/home/buzz1";
          createHome = true;
          shell = pkgs.bashInteractive;
          # Interactive Codex enrollment is administrator-only via `sudo -iu buzz1`.
          # Do not configure direct SSH credentials for this account.
        };

        buzz-deploy = {
          isNormalUser = true;
          createHome = false;
          home = "/var/empty";
          shell = pkgs.bash;
          # Every deployment key is a forced-command transport. The explicit
          # restrictions deny interactive shells, PTYs, user rc files, X11,
          # agent forwarding, and both TCP and streamlocal forwarding.
          openssh.authorizedKeys.keys =
            map (key: ''command="${buzzAgentDeploySsh}/bin/buzz-agent-deploy-ssh",restrict,no-agent-forwarding,no-port-forwarding,no-pty,no-user-rc,no-X11-forwarding ${key}'')
            config.services.buzzAgentHost.deployAuthorizedKeys;
        };
      };
    };

    security.sudo.extraRules = [
      {
        users = ["buzz-deploy"];
        commands = [
          {
            command = ''/run/current-system/sw/bin/buzz-agent-deploy ""'';
            options = ["NOPASSWD"];
          }
        ];
      }
    ];

    environment.systemPackages = [
      buzzAcp
      buzzCli
      codexCli
      codexAcp
      buzzAgentCtl
      buzzAgentDeploy
      buzzAgentDeploySsh
    ];

    systemd = {
      tmpfiles.rules = [
        "d /var/lib/buzz-agents 0700 root root -"
        "d /var/lib/buzz-agents/env 0700 root root -"
        "d /var/lib/buzz-agents/disabled 0700 root root -"
        "d /var/lib/buzz-agents/units 0700 root root -"
      ];

      services = {
        buzz-agent-restore = {
          description = "Restore managed Buzz agents after boot";
          wantedBy = ["multi-user.target"];
          wants = ["network-online.target"];
          after = ["local-fs.target" "network-online.target"];
          before = ["multi-user.target"];

          serviceConfig = {
            Type = "oneshot";
            User = "root";
            ExecStart = lib.concatStringsSep " " [
              "${buzzAgentRestore}/bin/buzz-agent-restore"
              "/var/lib/buzz-agents/env"
              "/var/lib/buzz-agents/disabled"
              "/run/lock/buzz-agent-lifecycle.lock"
              "/run/lock/buzz-agent-lifecycle-operation.lock"
            ];
          };
        };

        "buzz-agent@" = {
          description = "Buzz agent %i";
          path = agentPath;

          serviceConfig = {
            Type = "exec";
            User = "buzz1";
            WorkingDirectory = "/home/buzz1";
            EnvironmentFile = "/var/lib/buzz-agents/env/%i";
            # The static module-owned launcher cannot execute shell/loader startup
            # hooks from EnvironmentFile=. It sanitizes those variables, restores
            # fixed command/configuration roots, decodes team instructions, and appends the
            # publication contract before executing the harness.
            ExecStart = lib.concatStringsSep " " [
              "${buzzAgentRun}/bin/buzz-agent-run"
              "${buzzAcp}/bin/buzz-acp"
            ];
            # Run as root (the '+' prefix) with only module-owned lifecycle paths.
            # The recorder persists only the pinned harness's verified-owner status.
            ExecStopPost = lib.concatStringsSep " " [
              "+${buzzAgentRecordCleanExit}/bin/buzz-agent-record-clean-exit"
              "/var/lib/buzz-agents/disabled"
              "/run/lock/buzz-agent-lifecycle.lock"
              "%i"
            ];
            Restart = "always";
            RestartPreventExitStatus = [42];

            ProtectSystem = "strict";
            ProtectHome = "tmpfs";
            BindPaths = ["/home/buzz1"];
            ReadWritePaths = [
              "/home/buzz1"
              "/var/lib/buzz-agents/disabled"
            ];
            NoNewPrivileges = true;
            PrivateTmp = true;
          };
        };
      };
    };
  };
}
