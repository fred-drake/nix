{
  config,
  pkgs,
  ...
}: let
  containers-sha = import ../../../../apps/fetcher/containers-sha.nix {inherit pkgs;};
  host = "paperless";
  proxyPort = "8001";
  aiProxyPort = "3002";
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

  services.nginx = {
    enable = true;
    virtualHosts = {
      "${host}.${config.soft-secrets.networking.domain}" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${proxyPort}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            proxy_connect_timeout 300;
            proxy_send_timeout 300;
            proxy_read_timeout 300;

            client_max_body_size 50M;
          '';
        };
      };
      "${host}-ai.${config.soft-secrets.networking.domain}" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${aiProxyPort}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            proxy_connect_timeout 300;
            proxy_send_timeout 300;
            proxy_read_timeout 300;
          '';
        };
      };
    };
  };

  environment.systemPackages = [pkgs.cifs-utils];

  fileSystems."/mnt/paperless-storage" = {
    device = "//u543742.your-storagebox.de/u543742-sub4";
    fsType = "cifs";
    options = [
      "credentials=${config.sops.templates."paperless-storage-credentials".path}"
      "_netdev"
      "noauto"
      "x-systemd.automount"
      "uid=1000"
      "gid=1000"
      "iocharset=utf8"
    ];
  };

  # Scanner SSH access for auto-transfer
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIaQl0o8WD6inmcntGzrCmHdsB/Gj5PEUXSFM/eYrukI"
  ];

  systemd = {
    tmpfiles.rules = [
      "d /var/paperless/data 0755 1000 1000 -"
      "d /var/paperless/consume 0755 1000 1000 -"
      "d /var/paperless/redis 0755 999 999 -"
      "d /var/paperless/postgresql 0755 999 999 -"
      "d /var/paperless/ai 0755 1000 1000 -"
    ];
    services.podman-network-paperless = {
      description = "Create paperless podman network with DNS enabled";
      wantedBy = ["multi-user.target"];
      before = [
        "podman-paperless-redis.service"
        "podman-paperless-postgres.service"
        "podman-paperless-gotenberg.service"
        "podman-paperless-tika.service"
        "podman-paperless-ngx.service"
        "podman-paperless-ai.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.podman}/bin/podman network create --ignore paperless-net";
      };
    };
  };

  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      paperless-redis = {
        image = containers-sha."docker.io"."library/redis"."latest"."linux/amd64";
        autoStart = true;
        extraOptions = ["--network=paperless-net"];
        volumes = ["/var/paperless/redis:/data"];
        environment = {
          TZ = "America/New_York";
        };
      };
      paperless-postgres = {
        image = containers-sha."docker.io"."postgres"."17"."linux/amd64";
        autoStart = true;
        extraOptions = ["--network=paperless-net"];
        volumes = ["/var/paperless/postgresql:/var/lib/postgresql/data"];
        environment = {
          TZ = "America/New_York";
        };
        environmentFiles = [config.sops.secrets.paperless-postgresql-env.path];
      };
      paperless-gotenberg = {
        image = containers-sha."docker.io"."gotenberg/gotenberg"."latest"."linux/amd64";
        autoStart = true;
        extraOptions = ["--network=paperless-net"];
        cmd = ["gotenberg" "--chromium-disable-javascript=true" "--chromium-allow-list=file:///tmp/.*"];
      };
      paperless-tika = {
        image = containers-sha."docker.io"."apache/tika"."latest"."linux/amd64";
        autoStart = true;
        extraOptions = ["--network=paperless-net"];
      };
      paperless-ngx = {
        image = containers-sha."ghcr.io"."paperless-ngx/paperless-ngx"."latest"."linux/amd64";
        autoStart = true;
        dependsOn = ["paperless-postgres" "paperless-redis" "paperless-gotenberg" "paperless-tika"];
        extraOptions = ["--network=paperless-net"];
        ports = [
          "127.0.0.1:${proxyPort}:8000"
        ];
        volumes = [
          "/var/paperless/data:/usr/src/paperless/data"
          "/mnt/paperless-storage/media:/usr/src/paperless/media"
          "/mnt/paperless-storage/export:/usr/src/paperless/export"
          "/var/paperless/consume:/usr/src/paperless/consume"
        ];
        environment = {
          TZ = "America/New_York";
          PAPERLESS_REDIS = "redis://paperless-redis:6379";
          PAPERLESS_TIKA_ENABLED = "1";
          PAPERLESS_TIKA_GOTENBERG_ENDPOINT = "http://paperless-gotenberg:3000";
          PAPERLESS_TIKA_ENDPOINT = "http://paperless-tika:9998";
          PAPERLESS_OCR_LANGUAGE = "eng";
          PAPERLESS_CONSUMER_POLLING = "30";
          PAPERLESS_URL = "https://paperless.${config.soft-secrets.networking.domain}";
        };
        environmentFiles = [config.sops.secrets.paperless-env.path];
      };
      paperless-ai = {
        image = containers-sha."docker.io"."clusterzx/paperless-ai"."latest"."linux/amd64";
        autoStart = true;
        dependsOn = ["paperless-ngx"];
        extraOptions = ["--network=paperless-net"];
        ports = [
          "127.0.0.1:${aiProxyPort}:3000"
        ];
        volumes = [
          "/var/paperless/ai:/app/data"
        ];
        environment = {
          TZ = "America/New_York";
          PAPERLESS_AI_PORT = "3000";
          RAG_SERVICE_URL = "http://paperless-ngx:8000";
          RAG_SERVICE_ENABLED = "true";
          PAPERLESS_API_URL = "http://paperless-ngx:8000/api";
        };
        environmentFiles = [config.sops.secrets.paperless-ai-env.path];
      };
    };
  };
}
