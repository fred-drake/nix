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

  # Endpoints Gatus probes, keyed by the private IP of the host that serves them.
  # stormwind's nameserver is public 8.8.8.8 and can't resolve *.internal, so the
  # container gets static --add-host entries below. Probing by hostname keeps the
  # TLS SNI/Host matching each endpoint's ACME cert; a 4xx auth gate still counts
  # as "up" (only a connection failure or nginx 5xx is a real outage).
  endpointHosts = {
    # ironforge media stack (10.1.1.3)
    jellyfin = "10.1.1.3";
    seerr = "10.1.1.3";
    jellyseerr = "10.1.1.3";
    sonarr = "10.1.1.3";
    radarr = "10.1.1.3";
    lidarr = "10.1.1.3";
    prowlarr = "10.1.1.3";
    sabnzbd = "10.1.1.3";
    bazarr = "10.1.1.3";
    # orgrimmar app stack (10.1.1.4)
    resume = "10.1.1.4";
    woodpecker = "10.1.1.4";
    gitea = "10.1.1.4";
    gitea-status = "10.1.1.4";
    paperless = "10.1.1.4";
    paperless-ai = "10.1.1.4";
    calibre-web = "10.1.1.4";
    files = "10.1.1.4";
  };
  groupOf = ip:
    if ip == "10.1.1.3"
    then "ironforge"
    else "orgrimmar";

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
      lib.mapAttrsToList (name: ip: {
        inherit name;
        group = groupOf ip;
        url = "https://${name}.${domain}";
        interval = "60s";
        conditions = [
          "[CONNECTED] == true"
          "[STATUS] < 500"
        ];
        alerts = [{type = "discord";}];
      })
      endpointHosts;
  };

  addHostOptions =
    lib.mapAttrsToList (name: ip: "--add-host=${name}.${domain}:${ip}") endpointHosts;
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
          extraOptions = addHostOptions;
        };
      };
    }
  ]
