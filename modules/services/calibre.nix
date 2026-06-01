{
  config,
  lib,
  pkgs,
  ...
}: let
  containers-sha = import ../../apps/fetcher/containers-sha.nix {inherit pkgs;};
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
  # The linuxserver/calibre desktop container was removed: it migrated to a
  # GPU-accelerated Selkies/Xorg desktop that can't initialize on this headless
  # host (glamor fails on the server GPU; image ships no software-X driver), so
  # pixelflux screen capture EIO-panicked and crash-looped, dumping cores until
  # it starved the disk and took down paperless. calibre-web covers e-book
  # reading and is fully independent.
  lib.mkMerge [
    calibreStorage
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
