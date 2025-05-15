{config, ...}: {
  sops.age.sshKeyPaths = ["/home/default/id_infrastructure"];
  sops.defaultSopsFile = config.secrets.sopsYaml;
  sops.secrets.metrics-sabnzbd-env = {
    sopsFile = config.secrets.host.external-metrics.sabnzbd;
    mode = "0400";
    key = "data";
  };
  sops.secrets.metrics-sonarr-env = {
    sopsFile = config.secrets.host.external-metrics.sonarr;
    mode = "0400";
    key = "data";
  };
  sops.secrets.metrics-radarr-env = {
    sopsFile = config.secrets.host.external-metrics.radarr;
    mode = "0400";
    key = "data";
  };

  virtualisation.containers.enable = true;
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
  };

  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      sabnzbd_exporter = {
        image = "docker.io/msroest/sabnzbd_exporter";
        autoStart = true;
        ports = ["${config.soft-secrets.host.external-metrics.admin_ip_address}:9387:9387"];
        environmentFiles = [
          config.sops.secrets.metrics-sabnzbd-env.path
        ];
      };
      sonarr_exporter = {
        image = "ghcr.io/onedr0p/exportarr:latest";
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
        image = "ghcr.io/onedr0p/exportarr:latest";
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
}
