{
  config,
  lib,
  pkgs,
  ...
}: let
  containers-sha = import ../../apps/fetcher/containers-sha.nix {inherit pkgs;};
  mkPodmanNetwork = import ../../lib/mk-podman-network.nix {inherit pkgs;};
  mkNginxProxy = import ../../lib/mk-nginx-proxy.nix {inherit config;};
  host = "traceway";
  proxyPort = "8000";
in
  lib.mkMerge [
    (mkNginxProxy {
      inherit host;
      port = proxyPort;
    })
    {
      sops.secrets = {
        traceway-env = {
          sopsFile = config.secrets.host.stormwind.traceway-env;
          mode = "0400";
          key = "data";
        };
      };

      systemd = {
        tmpfiles.rules = [
          "d /var/traceway/postgresql 0755 999 999 -"
          "d /var/traceway/clickhouse 0755 101 101 -"
        ];
        services = mkPodmanNetwork "traceway" [
          "podman-traceway-postgres.service"
          "podman-traceway-clickhouse.service"
          "podman-traceway-app.service"
        ];
      };

      virtualisation.oci-containers = {
        backend = "podman";
        containers = {
          traceway-postgres = {
            image = containers-sha."docker.io"."postgres"."17"."linux/amd64";
            autoStart = true;
            extraOptions = ["--network=traceway-net"];
            volumes = ["/var/traceway/postgresql:/var/lib/postgresql/data"];
            environment = {
              TZ = "America/New_York";
              POSTGRES_USER = "traceway";
              POSTGRES_DB = "traceway";
            };
            environmentFiles = [config.sops.secrets.traceway-env.path];
          };
          traceway-clickhouse = {
            image = containers-sha."docker.io"."clickhouse/clickhouse-server"."24.8-alpine"."linux/amd64";
            autoStart = true;
            extraOptions = ["--network=traceway-net"];
            volumes = ["/var/traceway/clickhouse:/var/lib/clickhouse"];
            environment = {
              TZ = "America/New_York";
              CLICKHOUSE_DB = "traceway";
            };
            environmentFiles = [config.sops.secrets.traceway-env.path];
          };
          traceway-app = {
            image = containers-sha."gitea.internal.freddrake.com"."fdrake/traceway"."latest"."linux/amd64";
            autoStart = true;
            dependsOn = ["traceway-postgres" "traceway-clickhouse"];
            extraOptions = ["--network=traceway-net"];
            ports = [
              "127.0.0.1:${proxyPort}:80"
            ];
            environment = {
              TZ = "America/New_York";
              APP_BASE_URL = "https://${host}.${config.soft-secrets.networking.domain}";
              CLICKHOUSE_SERVER = "traceway-clickhouse:9000";
              CLICKHOUSE_DATABASE = "traceway";
              CLICKHOUSE_USERNAME = "default";
              CLICKHOUSE_TLS = "false";
              POSTGRES_HOST = "traceway-postgres";
              POSTGRES_PORT = "5432";
              POSTGRES_DATABASE = "traceway";
              POSTGRES_USERNAME = "traceway";
              POSTGRES_SSLMODE = "disable";
              GIN_MODE = "release";
              SESSION_RECORDING_RETENTION_DAYS = "30";
            };
            environmentFiles = [config.sops.secrets.traceway-env.path];
          };
        };
      };
    }
  ]
