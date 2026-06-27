{config, ...}: let
  glanceConfig = import ./glance-config.nix;
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

  services.glance = {
    enable = true;
    settings =
      glanceConfig
      // {
        server = {
          host = "0.0.0.0";
          port = 8084;
        };
      };
  };

  systemd.services.glance = {
    # Default `After=network.target` doesn't actually wait for the link to
    # come up, so on a fresh boot glance retries and trips the systemd
    # start-limit before wpa_supplicant associates. network-online.target
    # blocks until wpa_supplicant + dhcpcd actually have a route.
    after = ["network-online.target"];
    wants = ["network-online.target"];
    serviceConfig.EnvironmentFile = [
      config.sops.secrets.glance-env.path
    ];
  };
}
