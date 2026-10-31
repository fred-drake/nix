# Configuration specific to gnomeregan (always-on Linux box that runs the
# personal automation jobs that used to live on mac-studio).
{
  config,
  pkgs,
  ...
}: let
  home = config.home.homeDirectory;
  pkmDir = "${home}/Source/gitea.${config.soft-secrets.networking.domain}/fdrake/PKM-Personal";
  logDir = "${home}/.local/state";

  # PATH for jobs invoking claude + scripts from PKM-Personal.
  jobPath = "${home}/.local/bin:${home}/.nix-profile/bin:/etc/profiles/per-user/fdrake/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:/usr/bin:/bin";

  gmailCleanerLogDir = "${logDir}/gmail-cleaner";
  gmailCleanerLogrotateConf = pkgs.writeText "gmail-cleaner-logrotate.conf" ''
    "${gmailCleanerLogDir}/*.log"
    "${gmailCleanerLogDir}/*.out"
    "${gmailCleanerLogDir}/*.err" {
      daily
      rotate 14
      compress
      delaycompress
      missingok
      notifempty
      copytruncate
    }
  '';
in {
  home = {
    packages = [
      pkgs.gmail-cleaner
    ];

    file = {
      ".config/gmail-cleaner/prompt.txt" = {
        text = config.soft-secrets.app.gmail-cleaner.prompt;
        force = true;
      };
      ".local/state/gmail-cleaner/.keep".text = "";
    };
  };

  systemd.user = {
    services = {
      process-daily = {
        Unit = {
          Description = "Process yesterday's PKM daily note";
          After = ["network-online.target"];
          Wants = ["network-online.target"];
        };
        Service = {
          Type = "oneshot";
          Environment = "PATH=${jobPath}";
          ExecStart = pkgs.writeShellScript "process-daily" ''
            set -euo pipefail
            YESTERDAY=$(date -d 'yesterday' '+%Y-%m-%d')
            mkdir -p ${logDir}
            exec ${pkmDir}/.claude/hooks/process-daily-cron.sh "$YESTERDAY"
          '';
          StandardOutput = "append:${logDir}/process-daily.log";
          StandardError = "append:${logDir}/process-daily.err";
        };
      };

      gmail-cleaner = {
        Unit = {
          Description = "Classify and archive unwanted Gmail inbox messages";
          After = ["network-online.target"];
          Wants = ["network-online.target"];
        };
        Service = {
          Type = "oneshot";
          Environment = [
            "HOME=${home}"
            "PATH=${jobPath}"
          ];
          ExecStart = pkgs.writeShellScript "gmail-cleaner-job" ''
            set -euo pipefail
            mkdir -p ${gmailCleanerLogDir}
            exec ${pkgs.gmail-cleaner}/bin/gmail-cleaner --silent
          '';
          StandardOutput = "append:${gmailCleanerLogDir}/gmail-cleaner.out";
          StandardError = "append:${gmailCleanerLogDir}/gmail-cleaner.err";
        };
      };

      gmail-cleaner-logrotate = {
        Unit.Description = "Rotate and compress gmail-cleaner logs";
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.logrotate}/bin/logrotate --state ${gmailCleanerLogDir}/logrotate.status ${gmailCleanerLogrotateConf}";
        };
      };
    };

    timers = {
      process-daily = {
        Unit.Description = "Daily timer for process-daily";
        Timer = {
          OnCalendar = "*-*-* 00:00:00";
          Persistent = true;
        };
        Install.WantedBy = ["timers.target"];
      };

      gmail-cleaner = {
        Unit.Description = "Run gmail-cleaner every 15 minutes";
        Timer = {
          OnCalendar = "*:0/15";
          Persistent = true;
        };
        Install.WantedBy = ["timers.target"];
      };

      gmail-cleaner-logrotate = {
        Unit.Description = "Daily log rotation for gmail-cleaner";
        Timer = {
          OnCalendar = "daily";
          Persistent = true;
        };
        Install.WantedBy = ["timers.target"];
      };
    };
  };
}
