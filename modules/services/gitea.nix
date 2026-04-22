{
  config,
  lib,
  pkgs,
  ...
}: let
  containers-sha = import ../../apps/fetcher/containers-sha.nix {inherit pkgs;};
  host = "gitea";
  proxyPort = "3001";
  mkCifsMount = import ../../lib/mk-cifs-mount.nix {inherit config pkgs;};
  mkNginxProxy = import ../../lib/mk-nginx-proxy.nix {inherit config;};
  giteaLongTimeouts = ''
    client_max_body_size 0;
    proxy_request_buffering off;
    proxy_read_timeout 3600s;
    proxy_send_timeout 3600s;
    proxy_connect_timeout 3600s;
  '';
  giteaStorage = mkCifsMount {
    name = "gitea";
    sub = "sub3";
    secretsHost = "ironforge";
  };
in
  lib.mkMerge [
    giteaStorage
    (mkNginxProxy {
      inherit host;
      port = proxyPort;
      extraConfig = giteaLongTimeouts;
    })
    (mkNginxProxy {
      host = "gitea-status";
      port = 8080;
      extraConfig = giteaLongTimeouts;
    })
    {
      sops.secrets = {
        gitea-check-service-env = {
          sopsFile = config.secrets.host.gitea.check-service-env;
          mode = "0400";
          key = "data";
        };
      };

      systemd.tmpfiles.rules = [
        "d /var/gitea/local-data 0755 1000 1000 -"
      ];

      virtualisation.oci-containers = {
        backend = "podman";
        containers = {
          gitea = {
            image = containers-sha."docker.gitea.com"."gitea"."1-rootless"."linux/amd64";
            autoStart = true;
            # Resolve woodpecker via the host so webhooks can reach the
            # nginx proxy without leaving orgrimmar (and without needing
            # public DNS inside the container's default resolver).
            extraOptions = [
              "--add-host=woodpecker.${config.soft-secrets.networking.domain}:host-gateway"
            ];
            ports = [
              "127.0.0.1:${proxyPort}:3000"
              "0.0.0.0:22:2222"
            ];
            volumes = [
              "/mnt/gitea-storage/data:/var/lib/gitea"
              "/var/gitea/local-data:/var/lib/gitea/data"
              "/mnt/gitea-storage/config:/etc/gitea"
            ];
            environment = {
              PUID = "1000";
              PGID = "1000";
              TZ = "America/New_York";
              GITEA__webhook__ALLOWED_HOST_LIST = "private";
            };
          };
          gitea-check-service = {
            image = containers-sha."ghcr.io"."fred-drake/gitea-check-service"."latest"."linux/amd64";
            autoStart = true;
            ports = [
              "127.0.0.1:8080:8080"
            ];
            environment = {
              GITEA_URL = "https://gitea.${config.soft-secrets.networking.domain}";
            };
            environmentFiles = [config.sops.secrets.gitea-check-service-env.path];
          };
        };
      };
    }
  ]
