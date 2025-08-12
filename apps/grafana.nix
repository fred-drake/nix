{config, ...}: let
  host = "grafana";
  proxyPort = "3000";
in {
  networking.extraHosts = ''
    192.168.50.26 dev.brainrush.ai
    ${config.soft-secrets.host.prometheus.admin_ip_address} prometheus.${config.soft-secrets.networking.domain}
  '';

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
            recommendedProxySettings = true;
          };
        };
      };
    };
    grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = "127.0.0.1";
          http_port = 3000;
          domain = "${host}.${config.soft-secrets.networking.domain}";
          root_url = "https://${host}.${config.soft-secrets.networking.domain}";
        };
        analytics.reporting_enabled = false;
        security = {
          # Initial admin password, should be changed after first login
          admin_password = "$__file{${config.sops.secrets.grafana-admin-password.path}}";
          admin_user = "admin";
        };
      };
      provision = {
        enable = true;
        datasources.settings = {
          apiVersion = 1;
          datasources = [
            {
              name = "Prometheus";
              type = "prometheus";
              url = "https://prometheus.${config.soft-secrets.networking.domain}";
              access = "proxy";
            }
          ];
        };
      };
    };
  };
}
