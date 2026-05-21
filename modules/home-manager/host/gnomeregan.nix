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
in {
  systemd.user.services.process-daily = {
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

  systemd.user.timers.process-daily = {
    Unit.Description = "Daily timer for process-daily";
    Timer = {
      OnCalendar = "*-*-* 00:00:00";
      Persistent = true;
    };
    Install.WantedBy = ["timers.target"];
  };

  systemd.user.services.archive-email = {
    Unit = {
      Description = "Archive obvious email via claude + google-workspace MCP";
      After = ["network-online.target"];
      Wants = ["network-online.target"];
    };
    Service = {
      Type = "oneshot";
      WorkingDirectory = pkmDir;
      Environment = "PATH=${jobPath}";
      ExecStart = pkgs.writeShellScript "archive-email" ''
        set -euo pipefail
        mkdir -p ${logDir}
        cd ${pkmDir}
        exec timeout 1200 claude \
          --model sonnet \
          --verbose \
          --output-format stream-json \
          --mcp-config "${home}/mcp/google-workspace.json" \
          -p /archive-obvious
      '';
      StandardOutput = "append:${logDir}/archive-email.log";
      StandardError = "append:${logDir}/archive-email.err";
    };
  };

  systemd.user.timers.archive-email = {
    Unit.Description = "Hourly timer for archive-email";
    Timer = {
      OnCalendar = "hourly";
      Persistent = true;
    };
    Install.WantedBy = ["timers.target"];
  };
}
