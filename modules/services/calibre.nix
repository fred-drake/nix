{
  config,
  lib,
  pkgs,
  ...
}: let
  containers-sha = import ../../apps/fetcher/containers-sha.nix {inherit pkgs;};
  desktopPort = "8082";
  contentServerPort = "8081";
  webPort = "8083";
  mkCifsMount = import ../../lib/mk-cifs-mount.nix {inherit config pkgs;};
  mkNginxProxy = import ../../lib/mk-nginx-proxy.nix {inherit config;};
  calibreStorage = mkCifsMount {
    name = "calibre";
    sub = "sub5";
    secretsHost = "ironforge";
    extraOptions = ["nobrl"];
  };
in
  lib.mkMerge [
    calibreStorage
    (mkNginxProxy {
      host = "calibre-desktop";
      port = desktopPort;
    })
    (mkNginxProxy {
      host = "calibre-desktop-web";
      port = contentServerPort;
    })
    (mkNginxProxy {
      host = "calibre-web";
      port = webPort;
    })
    {
      systemd.tmpfiles.rules = [
        "d /var/calibre-web/config 0755 1000 1000 -"
      ];

      virtualisation.oci-containers = {
        backend = "podman";
        containers = {
          calibre = {
            image = containers-sha."ghcr.io"."linuxserver/calibre"."latest"."linux/amd64";
            autoStart = true;
            ports = [
              "127.0.0.1:${desktopPort}:8080"
              "127.0.0.1:${contentServerPort}:8081"
            ];
            volumes = [
              "/mnt/calibre-storage:/config"
            ];
            environment = {
              PUID = "1000";
              PGID = "1000";
              TZ = "America/New_York";
            };
          };
          calibre-web = {
            image = containers-sha."ghcr.io"."linuxserver/calibre-web"."latest"."linux/amd64";
            autoStart = true;
            ports = [
              "127.0.0.1:${webPort}:8083"
            ];
            volumes = [
              "/var/calibre-web/config:/config"
              "/mnt/calibre-storage:/books"
            ];
            environment = {
              PUID = "1000";
              PGID = "1000";
              TZ = "America/New_York";
            };
          };
        };
      };
    }
  ]
