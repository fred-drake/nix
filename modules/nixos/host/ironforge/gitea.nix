{
  config,
  pkgs,
  ...
}: let
  containers-sha = import ../../../../apps/fetcher/containers-sha.nix {inherit pkgs;};
  host = "gitea";
  proxyPort = "3001";
in {
  security.acme.certs = {
    "${host}.${config.soft-secrets.networking.domain}" = {
      domain = "${host}.${config.soft-secrets.networking.domain}";
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      webroot = null;
      listenHTTP = null;
      s3Bucket = null;
      environmentFile = config.sops.secrets.cloudflare-api-key.path;
    };
    "gitea-status.${config.soft-secrets.networking.domain}" = {
      domain = "gitea-status.${config.soft-secrets.networking.domain}";
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      webroot = null;
      listenHTTP = null;
      s3Bucket = null;
      environmentFile = config.sops.secrets.cloudflare-api-key.path;
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

              proxy_read_timeout 3600s;
              proxy_send_timeout 3600s;
              proxy_connect_timeout 3600s;
            '';
          };
        };
        "gitea-status.${config.soft-secrets.networking.domain}" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8080";
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

              proxy_read_timeout 3600s;
              proxy_send_timeout 3600s;
              proxy_connect_timeout 3600s;
            '';
          };
        };
      };
    };
  };

  environment.systemPackages = [pkgs.cifs-utils];

  fileSystems."/mnt/gitea-storage" = {
    device = "//u543742.your-storagebox.de/u543742-sub3";
    fsType = "cifs";
    options = [
      "credentials=${config.sops.templates."gitea-storage-credentials".path}"
      "_netdev"
      "noauto"
      "x-systemd.automount"
      "uid=1000"
      "gid=1000"
      "iocharset=utf8"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/gitea/local-data 0755 1000 1000 -"
  ];

  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      gitea = {
        image = containers-sha."docker.gitea.com"."gitea"."1-rootless"."linux/amd64";
        autoStart = true;
        ports = [
          "127.0.0.1:${proxyPort}:3000"
          "0.0.0.0:22:2222"
        ];
        volumes = [
          "/mnt/gitea-storage/data:/var/lib/gitea"
          "/var/gitea/local-data:/var/lib/gitea/data"
          "/mnt/gitea-storage/config:/etc/gitea"
        ];
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "America/New_York";
          GITEA__webhook__ALLOWED_HOST_LIST = "woodpecker.${config.soft-secrets.networking.domain}";
        };
      };
      gitea-check-service = {
        image = containers-sha."ghcr.io"."fred-drake/gitea-check-service"."latest"."linux/amd64";
        autoStart = true;
        ports = [
          "127.0.0.1:8080:8080"
        ];
        environment = {
          GITEA_URL = "https://gitea.${config.soft-secrets.networking.domain}";
        };
        environmentFiles = [config.sops.secrets.gitea-check-service-env.path];
      };
    };
  };
}
