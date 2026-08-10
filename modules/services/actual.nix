{
  config,
  pkgs,
  ...
}: let
  containers-sha = import ../../apps/fetcher/containers-sha.nix {inherit pkgs;};
  mkNginxProxy = import ../../lib/mk-nginx-proxy.nix {inherit config;};
  host = "actual";
  port = "5006";
in {
  imports = [
    (mkNginxProxy {
      inherit host port;
      extraConfig = ''
        allow 10.1.0.0/16;
        allow 100.64.0.0/10;
        deny all;
      '';
    })
  ];

  systemd.tmpfiles.rules = [
    "d /var/actual 0750 root root -"
  ];

  virtualisation.oci-containers = {
    backend = "podman";
    containers.actual = {
      image = containers-sha."docker.io"."actualbudget/actual-server"."latest"."linux/amd64";
      autoStart = true;
      ports = ["127.0.0.1:${port}:5006"];
      volumes = ["/var/actual:/data"];
    };
  };
}
