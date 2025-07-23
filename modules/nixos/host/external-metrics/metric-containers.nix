{
  config,
  pkgs,
  ...
}: let
  containers-sha = import ../../../../apps/fetcher/containers-sha.nix {inherit pkgs;};
in {
  sops = {
    age.sshKeyPaths = ["/home/default/id_infrastructure"];
    defaultSopsFile = config.secrets.sopsYaml;
    secrets = {
      metrics-sabnzbd-env = {
        sopsFile = config.secrets.host.external-metrics.sabnzbd;
        mode = "0400";
        key = "data";
      };
      metrics-sonarr-env = {
        sopsFile = config.secrets.host.external-metrics.sonarr;
        mode = "0400";
        key = "data";
      };
      metrics-radarr-env = {
        sopsFile = config.secrets.host.external-metrics.radarr;
        mode = "0400";
        key = "data";
      };
    };
  };

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      dockerSocket.enable = true;
    };

    oci-containers = {
      backend = "podman";
      containers = {
        sabnzbd_exporter = {
          image = containers-sha."docker.io"."msroest/sabnzbd_exporter"."latest"."linux/amd64";
          autoStart = true;
          ports = ["${config.soft-secrets.host.external-metrics.admin_ip_address}:9387:9387"];
          environmentFiles = [
            config.sops.secrets.metrics-sabnzbd-env.path
          ];
        };
        sonarr_exporter = {
          image = containers-sha."ghcr.io"."onedr0p/exportarr"."latest"."linux/amd64";
          autoStart = true;
          ports = ["${config.soft-secrets.host.external-metrics.admin_ip_address}:9707:9707"];
          environment = {
            PORT = "9707";
            URL = "https://sonarr.${config.soft-secrets.networking.domain}";
          };
          environmentFiles = [
            config.sops.secrets.metrics-sonarr-env.path
          ];
          cmd = ["sonarr"];
        };
        radarr_exporter = {
          image = containers-sha."ghcr.io"."onedr0p/exportarr"."latest"."linux/amd64";
          autoStart = true;
          ports = ["${config.soft-secrets.host.external-metrics.admin_ip_address}:9708:9708"];
          environment = {
            PORT = "9708";
            URL = "https://radarr.${config.soft-secrets.networking.domain}";
          };
          environmentFiles = [
            config.sops.secrets.metrics-radarr-env.path
          ];
          cmd = ["radarr"];
        };
      };
    };
  };
}
