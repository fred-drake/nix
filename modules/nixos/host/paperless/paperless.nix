{
  config,
  pkgs,
  ...
}: let
  containers-sha = import ../../../../apps/fetcher/containers-sha.nix {inherit pkgs;};
  host = "paperless";
  proxyPort = "8000";
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
        "${host}-ai.${config.soft-secrets.networking.domain}" = {
          domain = "${host}-ai.${config.soft-secrets.networking.domain}";
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
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
    nginx = {
      enable = true;
      virtualHosts = {
        "${host}.${config.soft-secrets.networking.domain}" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://${config.soft-secrets.host.paperless.service_ip_address}:${proxyPort}";
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
        "${host}-ai.${config.soft-secrets.networking.domain}" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://${config.soft-secrets.host.paperless.service_ip_address}:3000";
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
    "d /var/paperless/data 0755 1000 1000 -"
    "d /var/paperless/media 0755 1000 1000 -"
    "d /var/paperless/export 0755 1000 1000 -"
    "d /var/paperless/consume 0755 1000 1000 -"
    "d /var/redis/data 0755 1000 1000 -"
    "d /var/postgresql/data 0755 1000 1000 -"
    "d /var/paperless-ai/data 0755 1000 1000 -"
  ];

  environment.systemPackages = [
    pkgs.rsync
  ];

  # Add public key for scanner to connect
  users.users.default.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIaQl0o8WD6inmcntGzrCmHdsB/Gj5PEUXSFM/eYrukI"
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
        redis = {
          image = containers-sha."docker.io"."library/redis"."latest"."linux/amd64";
          autoStart = true;
          ports = ["6379:6379"];
          volumes = ["/var/redis/data:/data"];
          environment = {
            PUID = "1000";
            PGID = "1000";
            TZ = "America/New_York";
          };
        };
        postgresql = {
          image = containers-sha."docker.io"."postgres"."17"."linux/amd64";
          autoStart = true;
          ports = ["5432:5432"];
          volumes = ["/var/postgresql/data:/var/lib/postgresql/data"];
          environment = {
            PUID = "1000";
            PGID = "1000";
            TZ = "America/New_York";
          };
          environmentFiles = [config.sops.secrets.paperless-postgresql-env.path];
        };
        gotenberg = {
          image = containers-sha."docker.io"."gotenberg/gotenberg"."latest"."linux/amd64";
          autoStart = true;
          ports = ["3001:3000"];
          cmd = ["gotenberg" "--chromium-disable-javascript=true" "--chromium-allow-list=file:///tmp/.*"];
        };
        tika = {
          image = containers-sha."ghcr.io"."paperless-ngx/tika"."latest"."linux/amd64";
          autoStart = true;
          ports = ["9998:9998"];
        };
        paperless = {
          image = containers-sha."ghcr.io"."paperless-ngx/paperless-ngx"."latest"."linux/amd64";
          autoStart = true;
          ports = ["8000:8000"];
          volumes = [
            "/var/paperless/data:/usr/src/paperless/data"
            "/var/paperless/media:/usr/src/paperless/media"
            "/var/paperless/export:/usr/src/paperless/export"
            "/var/paperless/consume:/usr/src/paperless/consume"
          ];
          dependsOn = ["postgresql" "redis" "gotenberg" "tika"];
          environment = {
            PUID = "1000";
            PGID = "1000";
            TZ = "America/New_York";
            PAPERLESS_REDIS = "redis://host.containers.internal:6379";
            PAPERLESS_TIKA_ENABLED = "1";
            PAPERLESS_TIKA_GOTENBERG_ENDPOINT = "http://host.containers.internal:3001";
            PAPERLESS_TIKA_ENDPOINT = "http://host.containers.internal:9998";
            PAPERLESS_OCR_LANGUAGE = "eng";
            PAPERLESS_CONSUMER_POLLING = "30";
            PAPERLESS_URL = "https://paperless.${config.soft-secrets.networking.domain}";
          };
          environmentFiles = [config.sops.secrets.paperless-env.path];
        };
        paperless-ai = {
          image = containers-sha."docker.io"."clusterzx/paperless-ai"."latest"."linux/amd64";
          autoStart = true;
          ports = ["3000:3000"];
          volumes = [
            "/var/paperless-ai/data:/app/data"
          ];
          environment = {
            PUID = "1000";
            PGID = "1000";
            TZ = "America/New_York";
            PAPERLESS_AI_PORT = "3000";
            RAG_SERVICE_URL = "http://host.containers.internal:8000";
            RAG_SERVICE_ENABLED = "true";
            PAPERLESS_API_URL = "http://host.containers.internal:8000/api";
          };
          environmentFiles = [config.sops.secrets.paperless-ai-env.path];
        };
      };
    };
  };
}
