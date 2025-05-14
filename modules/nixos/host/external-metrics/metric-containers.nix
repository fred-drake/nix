{config, ...}: {
  sops.age.sshKeyPaths = ["/home/default/id_infrastructure"];
  sops.defaultSopsFile = config.secrets.sopsYaml;
  sops.secrets.metrics-sabnzbd-env = {
    sopsFile = config.secrets.host.external-metrics.sabnzbd;
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
    };
  };
}
