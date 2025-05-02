{config, ...}: {
  virtualisation.containers.enable = true;
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };
  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      gitea = {
        image = "docker.gitea.com/act_runner:latest";
        autoStart = true;
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "America/New_York";
          GITEA_INSTANCE_URL = "https://gitea.${config.soft-secrets.networking.domain}";
          GITEA_RUNNER_REGISTRATION_TOKEN_FILE = config.sops.secrets.gitea-registration-token.path;
          GITEA_RUNNER_NAME = "gitea-runner-1";
          DOCKER_HOST = "unix:///run/user/1000/podman/podman.sock";
        };
      };
    };
  };
}
