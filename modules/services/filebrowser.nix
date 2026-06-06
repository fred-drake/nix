{
  config,
  lib,
  pkgs,
  ...
}: let
  containers-sha = import ../../apps/fetcher/containers-sha.nix {inherit pkgs;};
  webPort = "8082";
  mkCifsMount = import ../../lib/mk-cifs-mount.nix {inherit config pkgs;};
  mkNginxProxy = import ../../lib/mk-nginx-proxy.nix {inherit config;};
  # Hetzner Storage Box sub-account holding the files served by filebrowser.
  fredboxStorage = mkCifsMount {
    name = "fredbox";
    sub = "sub10";
    secretsHost = "ironforge";
  };
in
  lib.mkMerge [
    fredboxStorage
    (mkNginxProxy {
      host = "files";
      port = webPort;
    })
    {
      systemd.tmpfiles.rules = [
        "d /var/filebrowser 0755 1000 1000 -"
        "d /var/filebrowser/config 0755 1000 1000 -"
        "d /var/filebrowser/database 0755 1000 1000 -"
      ];

      virtualisation.oci-containers = {
        backend = "podman";
        containers = {
          filebrowser = {
            image = containers-sha."docker.io"."filebrowser/filebrowser"."latest"."linux/amd64";
            autoStart = true;
            # The upstream image bakes in a non-root "user" that can't bind the
            # container-internal port 80; run as root so the listener comes up.
            user = "root";
            ports = [
              "127.0.0.1:${webPort}:80"
            ];
            volumes = [
              "/mnt/fredbox-storage:/srv"
              "/var/filebrowser/config:/config"
              "/var/filebrowser/database:/database"
            ];
            environment = {
              TZ = "America/New_York";
            };
          };
        };
      };
    }
  ]
