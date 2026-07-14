{
  config,
  lib,
  pkgs,
  ...
}: let
  containers-sha = import ../../apps/fetcher/containers-sha.nix {inherit pkgs;};
  mkNginxProxy = import ../../lib/mk-nginx-proxy.nix {inherit config;};
  host = "gatus";
  hostPort = 8090; # host-side port nginx proxies to; container listens on 8080
  domain = config.soft-secrets.networking.domain;

  # Discord alerting. The webhook URL is injected at container runtime via the
  # gatus-env EnvironmentFile and substituted by gatus's ${VAR} support, so it
  # never lands in the (world-readable) Nix store.

  # Shared Hetzner split DNS resolves these names through Hearthstone. Probing
  # by hostname preserves each endpoint's TLS SNI/Host matching; a 4xx auth gate
  # still counts as "up" (only a connection failure or nginx 5xx is a failure).
  endpointGroups = {
    ironforge = [
      "jellyfin"
      "seerr"
      "jellyseerr"
      "sonarr"
      "radarr"
      "lidarr"
      "prowlarr"
      "sabnzbd"
      "bazarr"
    ];
    orgrimmar = [
      "resume"
      "woodpecker"
      "gitea"
      "gitea-status"
      "paperless"
      "paperless-ai"
      "calibre-web"
      "files"
    ];
  };

  # Each Storage Box host publishes mount health through node_exporter's
  # textfile collector. The host-local probe catches both an inaccessible share
  # and the subtle case where a long-lived CIFS mount still uses an address no
  # longer returned by Storage Box DNS.
  storageBoxMounts = {
    ironforge = ["videos" "downloads"];
    orgrimmar = ["fredbox" "gitea" "paperless" "calibre"];
  };
  storageBoxEndpoints =
    lib.mapAttrsToList (group: mounts: {
      name = "Storage Box CIFS mounts";
      inherit group;
      url = "http://${config.soft-secrets.host.${group}.admin_ip_address}:9000/metrics";
      interval = "60s";
      conditions =
        ["[STATUS] == 200"]
        ++ map (name: "[BODY] == pat(*storagebox_cifs_mount_healthy{name=\"${name}\"} 1*)") mounts;
      alerts = [{type = "discord";}];
    })
    storageBoxMounts;

  gatusConfig = (pkgs.formats.yaml {}).generate "gatus-config.yaml" {
    web.port = 8080;
    storage = {
      type = "sqlite";
      path = "/data/data.db";
    };
    alerting.discord = {
      webhook-url = "\${DISCORD_WEBHOOK_URL}";
      # Applied to every endpoint's `discord` alert. Three consecutive failures
      # before alerting (avoids flapping on a single 60s blip), two successes to
      # resolve, and a recovery message when the endpoint comes back.
      default-alert = {
        failure-threshold = 3;
        success-threshold = 2;
        send-on-resolved = true;
      };
    };
    endpoints =
      lib.concatMap (
        group:
          map (name: {
            inherit name group;
            url = "https://${name}.${domain}";
            interval = "60s";
            conditions = [
              "[CONNECTED] == true"
              "[STATUS] < 500"
            ];
            alerts = [{type = "discord";}];
          })
          endpointGroups.${group}
      ) (lib.attrNames endpointGroups)
      ++ storageBoxEndpoints;
  };
in
  lib.mkMerge [
    (mkNginxProxy {
      inherit host;
      port = hostPort;
    })
    {
      sops.secrets = {
        gatus-env = {
          sopsFile = config.secrets.host.stormwind.gatus-env;
          mode = "0400";
          key = "data";
          # The container reads this env file only at start, so a token rotation
          # (new secret content, same path) would otherwise leave the running
          # container holding the stale token. Restart it when the secret changes.
          restartUnits = ["podman-gatus.service"];
        };
      };

      systemd.tmpfiles.rules = [
        "d /var/gatus 0750 root root -"
      ];

      virtualisation.oci-containers = {
        backend = "podman";
        containers.gatus = {
          image = containers-sha."ghcr.io"."twin/gatus"."latest"."linux/amd64";
          autoStart = true;
          ports = ["127.0.0.1:${toString hostPort}:8080"];
          volumes = [
            "${gatusConfig}:/config/config.yaml:ro"
            "/var/gatus:/data"
          ];
          environment = {
            TZ = "America/New_York";
            GATUS_CONFIG_PATH = "/config/config.yaml";
          };
          environmentFiles = [config.sops.secrets.gatus-env.path];
        };
      };
    }
  ]
