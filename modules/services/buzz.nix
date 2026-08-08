# Private Buzz community relay for the Tailnet.
#
# The relay, Postgres, Redis, and MinIO are isolated on buzz-net. Only the
# relay is published to loopback; nginx supplies the TLS WebSocket endpoint.
{
  config,
  pkgs,
  ...
}: let
  containers-sha = import ../../apps/fetcher/containers-sha.nix {inherit pkgs;};
  mkNginxProxy = import ../../lib/mk-nginx-proxy.nix {inherit config;};
  mkPodmanNetwork = import ../../lib/mk-podman-network.nix {inherit pkgs;};

  host = "buzz";
  proxyPort = "3003";
  bucket = "buzz-media";
  dataDir = "/var/buzz";
  buzzEnv = config.sops.secrets.buzz-env.path;

  relayImage = containers-sha."ghcr.io"."block/buzz"."main"."linux/amd64";
  minioImage = containers-sha."docker.io"."minio/minio"."RELEASE.2025-09-07T16-13-09Z"."linux/amd64";
  minioMcImage = containers-sha."docker.io"."minio/mc"."RELEASE.2025-08-13T08-35-41Z"."linux/amd64";

  minioInit = pkgs.writeShellScript "buzz-minio-init" ''
    # The mc image is distroless, so use its MC_HOST_<alias> environment form
    # instead of trying to invoke a shell inside it.
    export MC_HOST_local="http://$BUZZ_S3_ACCESS_KEY:$BUZZ_S3_SECRET_KEY@buzz-minio:9000"

    ${pkgs.podman}/bin/podman run --rm --network=buzz-net \
      --env MC_HOST_local \
      ${minioMcImage} mb --ignore-existing "local/${bucket}"
    exec ${pkgs.podman}/bin/podman run --rm --network=buzz-net \
      --env MC_HOST_local \
      ${minioMcImage} anonymous set none "local/${bucket}"
  '';
in {
  imports = [
    (mkNginxProxy {
      inherit host;
      port = proxyPort;
      # This hostname resolves only on the private network. Restrict the vhost
      # as well, so a client that reaches the public IP cannot use the relay.
      extraConfig = ''
        allow 10.1.0.0/16;
        allow 100.64.0.0/10;
        deny all;
        client_max_body_size 250M;
      '';
    })
  ];

  sops.secrets.buzz-env = {
    sopsFile = config.secrets.host.orgrimmar.buzz-env;
    mode = "0400";
    key = "data";
  };

  systemd = {
    tmpfiles.rules = [
      "d ${dataDir} 0755 root root -"
      "d ${dataDir}/git 0750 1000 1000 -"
      "d ${dataDir}/minio 0750 1000 1000 -"
      "d ${dataDir}/postgres 0700 999 999 -"
      "d ${dataDir}/redis 0700 999 999 -"
    ];

    services =
      (mkPodmanNetwork "buzz" [
        "podman-buzz-postgres.service"
        "podman-buzz-redis.service"
        "podman-buzz-minio.service"
        "podman-buzz-relay.service"
      ])
      // {
        buzz-minio-init = {
          description = "Create the private Buzz MinIO bucket";
          wantedBy = ["multi-user.target"];
          after = ["podman-network-buzz.service" "podman-buzz-minio.service"];
          requires = ["podman-network-buzz.service" "podman-buzz-minio.service"];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            Restart = "on-failure";
            RestartSec = "5s";
            EnvironmentFile = buzzEnv;
            ExecStart = minioInit;
          };
        };

        # The relay only starts after the bucket initializer has completed.
        podman-buzz-relay = {
          after = ["buzz-minio-init.service"];
          requires = ["buzz-minio-init.service"];
        };
      };
  };

  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      buzz-postgres = {
        image = containers-sha."docker.io"."postgres"."17-alpine"."linux/amd64";
        autoStart = true;
        extraOptions = ["--network=buzz-net"];
        volumes = ["${dataDir}/postgres:/var/lib/postgresql/data"];
        environment = {
          POSTGRES_DB = "buzz";
          POSTGRES_USER = "buzz";
        };
        environmentFiles = [buzzEnv];
      };

      buzz-redis = {
        image = containers-sha."docker.io"."library/redis"."7-alpine"."linux/amd64";
        autoStart = true;
        extraOptions = ["--network=buzz-net" "--entrypoint=/bin/sh"];
        cmd = ["-ec" ''exec redis-server --appendonly yes --requirepass "$REDIS_PASSWORD"''];
        volumes = ["${dataDir}/redis:/data"];
        environmentFiles = [buzzEnv];
      };

      buzz-minio = {
        image = minioImage;
        autoStart = true;
        # Expand the SOPS-provided credentials inside the container rather than
        # putting either value in the Nix store or a podman command line.
        extraOptions = ["--network=buzz-net" "--entrypoint=/bin/sh"];
        cmd = [
          "-ec"
          ''
            export MINIO_ROOT_USER="$BUZZ_S3_ACCESS_KEY"
            export MINIO_ROOT_PASSWORD="$BUZZ_S3_SECRET_KEY"
            exec minio server /data --console-address :9001
          ''
        ];
        volumes = ["${dataDir}/minio:/data"];
        environmentFiles = [buzzEnv];
      };

      buzz-relay = {
        image = relayImage;
        autoStart = true;
        dependsOn = ["buzz-postgres" "buzz-redis" "buzz-minio"];
        extraOptions = ["--network=buzz-net" "--entrypoint=/bin/sh"];
        cmd = [
          "-ec"
          ''
            export DATABASE_URL="postgres://$POSTGRES_USER:$POSTGRES_PASSWORD@buzz-postgres:5432/$POSTGRES_DB"
            export REDIS_URL="redis://:$REDIS_PASSWORD@buzz-redis:6379"
            exec /usr/local/bin/buzz-relay
          ''
        ];
        ports = ["127.0.0.1:${proxyPort}:3000"];
        volumes = ["${dataDir}/git:/data/git"];
        environment = {
          BUZZ_BIND_ADDR = "0.0.0.0:3000";
          BUZZ_HEALTH_PORT = "8080";
          BUZZ_METRICS_PORT = "9102";
          BUZZ_S3_ENDPOINT = "http://buzz-minio:9000";
          BUZZ_S3_ADDRESSING_STYLE = "path";
          BUZZ_S3_BUCKET = bucket;
          BUZZ_GIT_REPO_PATH = "/data/git";
          BUZZ_AUTO_MIGRATE = "true";
          BUZZ_GIT_CONFORMANCE_PROBE = "true";
          POSTGRES_DB = "buzz";
          POSTGRES_USER = "buzz";
          RELAY_URL = "wss://buzz.internal.freddrake.com";
          BUZZ_MEDIA_BASE_URL = "https://buzz.internal.freddrake.com/media";
          BUZZ_MEDIA_SERVER_DOMAIN = "buzz.internal.freddrake.com";
          BUZZ_CORS_ORIGINS = "https://buzz.internal.freddrake.com";
          BUZZ_REQUIRE_AUTH_TOKEN = "true";
          BUZZ_REQUIRE_RELAY_MEMBERSHIP = "true";
          BUZZ_ALLOW_NIP_OA_AUTH = "true";
          RUST_LOG = "buzz_relay=info,buzz_db=info,buzz_auth=info,buzz_pubsub=info,tower_http=info";
        };
        environmentFiles = [buzzEnv];
      };
    };
  };
}
