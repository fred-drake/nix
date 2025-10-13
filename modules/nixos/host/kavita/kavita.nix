{
  config,
  pkgs,
  ...
}: let
  containers-sha = import ../../../../apps/fetcher/containers-sha.nix {inherit pkgs;};
  host = "kavita";
  proxyPort = "5000";
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
    "d /var/kavita/config 0755 1000 1000 -"
    "d /var/kavita/data 0755 1000 1000 -"
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
        kavita = {
          image = containers-sha."lscr.io"."linuxserver/kavita"."latest"."linux/amd64";
          autoStart = true;
          ports = ["127.0.0.1:${proxyPort}:${proxyPort}"];
          volumes = ["/var/kavita/config:/config" "/var/kavita/data:/data"];
          environment = {
            PUID = "1000";
            PGID = "1000";
            TZ = "America/New_York";
          };
        };
      };
    };
  };
}
