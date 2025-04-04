{
  config,
  pkgs,
  ...
}: let
  host = "overseerr";
  proxyPort = "5055";
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
      package = pkgs.nginx;
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
    jellyseerr = {
      enable = true;
      package = pkgs.jellyseerr;
    };
  };

  # virtualisation.containers.enable = true;
  # virtualisation.podman = {
  #   enable = true;
  #   dockerCompat = true;
  #   defaultNetwork.settings.dns_enabled = true;
  # };
  # virtualisation.oci-containers = {
  #   backend = "podman";
  #   containers = {
  #     my-container = {
  #       image = "lscr.io/linuxserver/overseerr:latest";
  #       autoStart = true;
  #       ports = ["127.0.0.1:${proxyPort}:${proxyPort}"];
  #       volumes = ["/var/overseerr/config:/config"];
  #       environment = {
  #         PUID = "1000";
  #         PGID = "1000";
  #         TZ = "America/New_York";
  #       };
  #     };
  #   };
  # };
}
