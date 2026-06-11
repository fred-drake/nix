{
  config,
  pkgs,
  ...
}: {
  sops.secrets.otel-collector-env = {
    sopsFile = config.secrets.host.${config.my.hostName}.otel-collector-env;
    mode = "0400";
    key = "data";
  };

  systemd.services.opentelemetry-collector.serviceConfig.EnvironmentFile =
    config.sops.secrets.otel-collector-env.path;

  services.opentelemetry-collector = {
    enable = true;
    package = pkgs.opentelemetry-collector-contrib;
    settings = {
      receivers = {
        hostmetrics = {
          collection_interval = "30s";
          scrapers = {
            cpu = {
              metrics."system.cpu.utilization".enabled = true;
            };
            memory = {
              metrics."system.memory.utilization".enabled = true;
            };
            disk = {};
            network = {};
            filesystem = {
              metrics."system.filesystem.utilization".enabled = true;
              # Skip podman overlay mounts (permission denied as non-root)
              # and virtual filesystems (no useful signal).
              include_fs_types = {
                fs_types = ["ext4" "ext3" "xfs" "btrfs"];
                match_type = "strict";
              };
            };
            load = {};
            paging = {};
          };
        };
      };
      processors = {
        batch = {};
        resourcedetection = {
          detectors = ["system"];
          system.hostname_sources = ["os"];
        };
      };
      exporters = {
        otlphttp = {
          endpoint = "https://traceway.${config.soft-secrets.networking.domain}/api/otel";
          headers = {
            Authorization = "Bearer \${env:TRACEWAY_OTEL_TOKEN}";
          };
        };
      };
      service = {
        pipelines = {
          metrics = {
            receivers = ["hostmetrics"];
            processors = ["resourcedetection" "batch"];
            exporters = ["otlphttp"];
          };
        };
      };
    };
  };
}
