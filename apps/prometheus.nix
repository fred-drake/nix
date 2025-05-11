{
  config,
  secrets,
  ...
}: let
  host = "prometheus";
  proxyPort = "9090";
  soft-secrets = import "${secrets}/soft-secrets";
in {
  security = {
    acme = {
      acceptTerms = true;
      preliminarySelfsigned = false;
      defaults = {
        email = config.soft-secrets.acme.email;
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
      listenAddress = "127.0.0.1";
      globalConfig.scrape_interval = "1m";
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
                "adguard1.${config.soft-secrets.networking.domain}:9000"
                "adguard2.${config.soft-secrets.networking.domain}:9000"
              ];
            }
          ];
        }
      ];
    };
  };
}
