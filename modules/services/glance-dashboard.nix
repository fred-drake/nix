{config, ...}: let
  glanceConfig = import ./glance-config.nix;
in {
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

  systemd.services.glance.serviceConfig.EnvironmentFile = [
    config.sops.secrets.glance-env.path
  ];
}
