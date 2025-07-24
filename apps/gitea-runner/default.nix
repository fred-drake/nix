runnerName: {
  config,
  pkgs,
  ...
}: let
  containers-sha = import ../fetcher/containers-sha.nix {inherit pkgs;};
  configFile = pkgs.writeText "gitea-runner-config" (builtins.readFile ./config.yaml);
in {
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerSocket.enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    oci-containers = {
      backend = "podman";
      containers = {
        ${runnerName} = {
          image = containers-sha."docker.gitea.com"."act_runner"."latest"."linux/amd64";
          autoStart = true;
          privileged = true;
          volumes = [
            "${config.sops.secrets.gitea-registration-token.path}:/gitea-registration-token"
            "${configFile}:/config/config.yaml:ro"
            "/var/${runnerName}/data:/data"
            "/var/run/docker.sock:/var/run/docker.sock:ro"
          ];
          environment = {
            PUID = "1000";
            PGID = "1000";
            TZ = "America/New_York";
            GITEA_INSTANCE_URL = "https://gitea.${config.soft-secrets.networking.domain}";
            GITEA_RUNNER_REGISTRATION_TOKEN_FILE = "/gitea-registration-token";
            GITEA_RUNNER_NAME = runnerName;
            CONFIG_FILE = "/config/config.yaml";
          };
          extraOptions = [
            "--dns=192.168.40.4"
          ];
        };
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/${runnerName}/data 0755 1000 1000 -"
  ];
}
