{
  config,
  pkgs,
  ...
}: let
  containers-sha = import ../../apps/fetcher/containers-sha.nix {inherit pkgs;};
  glanceConfig = import ./glance-config.nix;
  glanceConfigFile = (pkgs.formats.yaml {}).generate "glance.yml" (glanceConfig
    // {
      server = {
        host = "0.0.0.0";
        port = 8080;
      };
    });
  mkNginxProxy = import ../../lib/mk-nginx-proxy.nix {inherit config;};
in {
  imports = [
    ./nginx-acme-proxy.nix
    (mkNginxProxy {
      host = "glance";
      port = 8084;
    })
  ];
  sops.secrets.glance-env = {
    sopsFile = config.secrets.host.glance;
    mode = "0400";
    key = "data";
  };

  sops.secrets.glance-env.restartUnits = ["podman-glance.service"];

  virtualisation.oci-containers = {
    backend = "podman";
    containers.glance = {
      image = containers-sha."docker.io"."glanceapp/glance"."latest"."linux/amd64";
      autoStart = true;
      ports = ["127.0.0.1:8084:8080"];
      volumes = ["${glanceConfigFile}:/app/config/glance.yml:ro"];
      environmentFiles = [config.sops.secrets.glance-env.path];
    };
  };

  systemd.services.podman-glance = {
    # Default `After=network.target` doesn't actually wait for the link to
    # come up, so on a fresh boot Glance can trip its start limit before
    # wpa_supplicant associates. network-online.target blocks until
    # wpa_supplicant + dhcpcd actually have a route.
    after = ["network-online.target"];
    wants = ["network-online.target"];
  };
}
