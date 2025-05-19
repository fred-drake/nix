{config, ...}: let
  host = "prometheus";
  proxyPort = "9090";
in {
  security = {
    acme = {
      acceptTerms = true;
      preliminarySelfsigned = false;
      defaults = {
        inherit (config.soft-secrets.acme) email;
        dnsProvider = "cloudflare";
        environmentFile = config.sops.secrets.cloudflare-api-key.path;
      };
      certs = {
        "${host}.${config.soft-secrets.networking.domain}" = {
          domain = "${host}.${config.soft-secrets.networking.domain}";
          dnsProvider = "cloudflare";
          dnsResolver = "1.1.1.1:53";
          webroot = null;
          listenHTTP = null;
          s3Bucket = null;
          environmentFile = config.sops.secrets.cloudflare-api-key.path;
        };
      };
    };
  };

  services = {
    nginx = {
      enable = true;
      virtualHosts = {
        "${host}.${config.soft-secrets.networking.domain}" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:${proxyPort}";
            proxyWebsockets = true;
            extraConfig = ''
              # Increase the maximum size of the hash table
              proxy_headers_hash_max_size 1024;

              # Increase the bucket size of the hash table
              proxy_headers_hash_bucket_size 128;

              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
            '';
          };
        };
      };
    };
    prometheus = {
      enable = true;
      # extraFlags = ["--web.enable-admin-api"];
      listenAddress = "127.0.0.1";
      globalConfig.scrape_interval = "15s";
      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [
            {
              targets = [
                "prometheus.${config.soft-secrets.networking.domain}:9000"
                "gitea.admin.${config.soft-secrets.networking.domain}:9000"
                "gitea-runner-1.admin.${config.soft-secrets.networking.domain}:9000"
                "grafana.admin.${config.soft-secrets.networking.domain}:9000"
                "dns1.${config.soft-secrets.networking.domain}:9000"
                "dns2.${config.soft-secrets.networking.domain}:9000"
                "gateway.${config.soft-secrets.networking.domain}:9100"
                "n8n.admin.${config.soft-secrets.networking.domain}:9000"
                "overseerr.admin.${config.soft-secrets.networking.domain}:9000"
                "prowlarr.admin.${config.soft-secrets.networking.domain}:9000"
                "radarr.admin.${config.soft-secrets.networking.domain}:9000"
                "sabnzbd.admin.${config.soft-secrets.networking.domain}:9000"
                "sonarr.admin.${config.soft-secrets.networking.domain}:9000"
                "uptime-kuma.admin.${config.soft-secrets.networking.domain}:9000"
                "larussa.${config.soft-secrets.networking.domain}:9000"
              ];
            }
          ];
        }
        {
          job_name = "sabnzbd";
          scrape_timeout = "60s";
          scrape_interval = "5m";
          static_configs = [
            {
              targets = [
                "sabnzbd-metrics.${config.soft-secrets.networking.domain}:9387"
              ];
            }
          ];
        }
        {
          job_name = "sonarr";
          scrape_timeout = "60s";
          scrape_interval = "5m";
          static_configs = [
            {
              targets = [
                "sonarr-metrics.${config.soft-secrets.networking.domain}:9707"
              ];
            }
          ];
        }
        {
          job_name = "radarr";
          scrape_timeout = "60s";
          scrape_interval = "5m";
          static_configs = [
            {
              targets = [
                "radarr-metrics.${config.soft-secrets.networking.domain}:9708"
              ];
            }
          ];
        }
      ];
    };
  };
}
