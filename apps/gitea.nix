{
  config,
  pkgs,
  ...
}: let
  containers-sha = import ./fetcher/containers-sha.nix {inherit pkgs;};
  host = "gitea";
  proxyPort = "3000";
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
              client_max_body_size 0;
              proxy_request_buffering off;
            '';
          };
        };
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/gitea/data 0755 1000 1000 -"
    "d /var/gitea/config 0755 1000 1000 -"
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
      gitea = {
        image = containers-sha."docker.gitea.com"."gitea"."1-rootless"."linux/amd64";
        autoStart = true;
        ports = [
          "127.0.0.1:${proxyPort}:${proxyPort}"
          "0.0.0.0:22:2222"
        ];
        volumes = [
          "/var/gitea/data:/var/lib/gitea"
          "/var/gitea/config:/etc/gitea"
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
