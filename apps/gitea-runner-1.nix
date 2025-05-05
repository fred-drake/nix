{
  config,
  pkgs,
  ...
}: let
  containers-sha = import ./fetcher/containers-sha.nix {inherit pkgs;};
in {
  virtualisation.containers.enable = true;
  virtualisation.podman = {
    enable = true;
    dockerSocket.enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };
  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      gitea-runner-1 = {
        image = containers-sha."docker.gitea.com"."act_runner"."latest"."linux/amd64";
        autoStart = true;
        volumes = [
          "${config.sops.secrets.gitea-registration-token.path}:/gitea-registration-token"
          "/var/run/docker.sock:/var/run/docker.sock:ro"
        ];
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "America/New_York";
          GITEA_INSTANCE_URL = "https://gitea.${config.soft-secrets.networking.domain}";
          GITEA_RUNNER_REGISTRATION_TOKEN_FILE = "/gitea-registration-token";
          GITEA_RUNNER_NAME = "gitea-runner-1";
        };
      };
    };
  };
}
