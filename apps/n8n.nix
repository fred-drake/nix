{
  config,
  pkgs,
  ...
}: let
  containers-sha = import ./fetcher/containers-sha.nix {inherit pkgs;};
  host = "n8n";
  proxyPort = "5678";
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
  };

  systemd.tmpfiles.rules = [
    "d /var/n8n/config 0755 1000 1000 -"
  ];

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    oci-containers = {
      backend = "podman";
      containers = {
        n8n = {
          image = containers-sha."docker.n8n.io"."n8nio/n8n"."latest"."linux/amd64";
          autoStart = true;
          ports = ["127.0.0.1:${proxyPort}:${proxyPort}"];
          volumes = ["/var/n8n/config:/home/node/.n8n"];
          environment = {
            PUID = "1000";
            PGID = "1000";
            N8N_HOST = "${host}.${config.soft-secrets.networking.domain}";
            N8N_URL = "https://${host}.${config.soft-secrets.networking.domain}";
            N8N_PROTOCL = "https";
            N8N_WEBHOOK = "https://${host}.${config.soft-secrets.networking.domain}/";
            N8N_EDITOR_BASE_URL = "https://${host}.${config.soft-secrets.networking.domain}/";
            N8N_RUNNERS_ENABLED = "true";
            TZ = "America/New_York";
          };
        };
      };
    };
  };
}
