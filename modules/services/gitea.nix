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
  giteaStorage = mkCifsMount {
    name = "gitea";
    sub = "sub3";
    secretsHost = "ironforge";
  };
in
  lib.mkMerge [
    giteaStorage
    {
      sops.secrets = {
        gitea-check-service-env = {
          sopsFile = config.secrets.host.gitea.check-service-env;
          mode = "0400";
          key = "data";
        };
      };

      security.acme.certs = {
        "${host}.${config.soft-secrets.networking.domain}" = {};
        "gitea-status.${config.soft-secrets.networking.domain}" = {};
      };

      services = {
        nginx = {
          enable = true;
          virtualHosts = {
            "${host}.${config.soft-secrets.networking.domain}" = {
              useACMEHost = "${host}.${config.soft-secrets.networking.domain}";
              forceSSL = true;
              locations."/" = {
                proxyPass = "http://127.0.0.1:${proxyPort}";
                proxyWebsockets = true;
                extraConfig = ''
                  client_max_body_size 0;
                  proxy_request_buffering off;
                  proxy_read_timeout 3600s;
                  proxy_send_timeout 3600s;
                  proxy_connect_timeout 3600s;
                '';
              };
            };
            "gitea-status.${config.soft-secrets.networking.domain}" = {
              useACMEHost = "gitea-status.${config.soft-secrets.networking.domain}";
              forceSSL = true;
              locations."/" = {
                proxyPass = "http://127.0.0.1:8080";
                proxyWebsockets = true;
                extraConfig = ''
                  client_max_body_size 0;
                  proxy_request_buffering off;
                  proxy_read_timeout 3600s;
                  proxy_send_timeout 3600s;
                  proxy_connect_timeout 3600s;
                '';
              };
            };
          };
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
              GITEA__webhook__ALLOWED_HOST_LIST = "woodpecker.${config.soft-secrets.networking.domain}";
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
