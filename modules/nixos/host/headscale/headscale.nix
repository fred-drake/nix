{config, ...}: let
  host = "headscale";
  domain = "freddrake.com";
  proxyPort = "8080";
in {
  imports = [
    ../../../secrets/cloudflare.nix
  ];

  security = {
    acme = {
      acceptTerms = true;
      defaults = {
        inherit (config.soft-secrets.acme) email;
        dnsProvider = "cloudflare";
        environmentFile = config.sops.secrets.cloudflare-api-key.path;
      };
      certs = {
        "${host}.${domain}" = {
          domain = "${host}.${domain}";
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
        "${host}.${domain}" = {
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

    headscale = {
      enable = true;
      address = "0.0.0.0";
      port = 8080;
      settings = {
        server_url = "https://${host}.${domain}";
        listen_addr = "0.0.0.0:8080";
        metrics_listen_addr = "127.0.0.1:9090";

        noise = {
          private_key_path = "/var/lib/headscale/noise_private.key";
        };

        prefixes = {
          v4 = "100.64.0.0/10";
          v6 = "fd7a:115c:a1e0::/48";
        };

        derp = {
          server = {
            enabled = false;
          };
          urls = [
            "https://controlplane.tailscale.com/derpmap/default"
          ];
          auto_update_enabled = true;
          update_frequency = "24h";
        };

        database = {
          type = "sqlite";
          sqlite = {
            path = "/var/lib/headscale/db.sqlite";
          };
        };

        dns = {
          magic_dns = true;
          base_domain = "ts.freddrake.com";
          domains = [
            "freddrake.com"
            "internal.freddrake.com"
          ];
          nameservers = {
            global = [
              "1.1.1.1"
              "1.0.0.1"
            ];
            split = {
              "internal.freddrake.com" = ["192.168.30.1"];
            };
          };
          extra_records = [
            {
              name = "gateway.ts.freddrake.com";
              type = "A";
              value = "100.64.0.1";
            }
          ];
        };

        unix_socket = "/run/headscale/headscale.sock";
        unix_socket_permission = "0770";

        logtail = {
          enabled = false;
        };

        log = {
          level = "info";
        };

        acl_policy = {
          groups = {};
          acls = [
            {
              action = "accept";
              src = ["*"];
              dst = ["*:*"];
            }
          ];
          autoApprovers = {
            routes = {
              "10.1.0.0/16" = ["*"];
              "192.168.30.0/24" = ["*"];
              "192.168.40.0/24" = ["*"];
              "192.168.50.0/24" = ["*"];
              "192.168.208.0/24" = ["*"];
            };
          };
        };
      };
    };
  };
}
