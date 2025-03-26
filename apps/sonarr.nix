{config, ...}: let
  host = "sonarr";
  proxyPort = "8989";
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
  };

  systemd.tmpfiles.rules = [
    "d /var/sonarr/config 0755 root root -"
  ];

  virtualisation.containers.enable = true;
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };
  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      sonarr = {
        image = "lscr.io/linuxserver/sonarr:latest";
        autoStart = true;
        ports = ["127.0.0.1:${proxyPort}:${proxyPort}"];
        volumes = [
          "/var/sonarr/config:/config"
          "/mnt/downloads:/downloads"
          "/mnt/videos/Episodic:/tv"
        ];
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "America/New_York";
        };
      };
    };
  };
}
