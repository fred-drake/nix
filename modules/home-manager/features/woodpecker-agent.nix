{
  config,
  lib,
  pkgs,
  osConfig ? {},
  ...
}: let
  hasWoodpeckerAgent = (osConfig.my or {}).hasWoodpeckerAgent or config.my.hasWoodpeckerAgent;
  home = config.home.homeDirectory;
  workdir = "${home}/.cache/woodpecker-agent";
  logdir = "${home}/.local/state/woodpecker-agent";
in
  lib.mkIf hasWoodpeckerAgent {
    sops.secrets.woodpecker-agent-token = {
      sopsFile = config.secrets.host.mac-studio.woodpecker;
      mode = "0400";
      key = "agent-token";
    };

    home.file.".cache/woodpecker-agent/.keep".text = "";

    launchd.agents.woodpecker-agent = {
      enable = true;
      config = {
        Label = "com.freddrake.woodpecker-agent";
        ProgramArguments = [
          "/bin/sh"
          "-c"
          ''
            export WOODPECKER_AGENT_SECRET="$(cat ${config.sops.secrets.woodpecker-agent-token.path})"
            mkdir -p ${workdir} ${logdir}
            exec ${pkgs.woodpecker-agent}/bin/woodpecker-agent
          ''
        ];
        EnvironmentVariables = {
          WOODPECKER_SERVER = "10.1.1.4:9010";
          WOODPECKER_GRPC_SECURE = "false";
          WOODPECKER_GRPC_VERIFY = "false";
          WOODPECKER_BACKEND = "local";
          WOODPECKER_FILTER_LABELS = "platform=darwin,arch=arm64";
          WOODPECKER_HOSTNAME = "mac-studio";
          WOODPECKER_MAX_WORKFLOWS = "1";
          WOODPECKER_BACKEND_LOCAL_TEMP_DIR = workdir;
          PATH = "/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:${home}/.nix-profile/bin:/etc/profiles/per-user/fdrake/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin";
        };
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 10;
        StandardOutPath = "${logdir}/agent.log";
        StandardErrorPath = "${logdir}/agent.err";
        WorkingDirectory = workdir;
      };
    };
  }
