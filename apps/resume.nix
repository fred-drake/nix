{
  config,
  pkgs,
  ...
}: let
  containers-sha = import ./fetcher/containers-sha.nix {inherit pkgs;};
  host = "resume";
  proxyPort = "3000";
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
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;

              proxy_connect_timeout 300;
              proxy_send_timeout 300;
              proxy_read_timeout 300;

              # Handle large uploads for resumes
              client_max_body_size 10M;
            '';
          };
          locations."/storage/" = {
            proxyPass = "http://127.0.0.1:9001/";
            extraConfig = ''
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
    "d /var/resume/minio 0755 1000 1000 -"
    "d /var/postgresql 0755 999 999 -"
  ];

  systemd.services.podman-network-resume = {
    description = "Create resume podman network with DNS enabled";
    wantedBy = ["multi-user.target"];
    before = [
      "podman-resume-postgres.service"
      "podman-resume-minio.service"
      "podman-resume-chrome.service"
      "podman-resume-app.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.podman}/bin/podman network create --ignore resume-net";
    };
  };

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
        resume-postgres = {
          image = containers-sha."docker.io"."postgres"."16-alpine"."linux/amd64";
          autoStart = true;
          extraOptions = ["--network=resume-net"];
          ports = [
            "0.0.0.0:5432:5432"
          ];
          volumes = [
            "/var/postgresql:/var/lib/postgresql/data"
          ];
          environment = {
            TZ = "America/New_York";
          };
          environmentFiles = [config.sops.secrets.postgresql-env.path];
        };
        resume-minio = {
          image = containers-sha."quay.io"."minio/minio"."latest"."linux/amd64";
          autoStart = true;
          extraOptions = ["--network=resume-net"];
          cmd = ["server" "/data"];
          ports = [
            "127.0.0.1:9001:9000"
          ];
          volumes = [
            "/var/resume/minio:/data"
          ];
          environment = {
            TZ = "America/New_York";
          };
          environmentFiles = [config.sops.secrets.minio-env.path];
        };
        resume-chrome = {
          image = containers-sha."ghcr.io"."browserless/chromium"."v2.18.0"."linux/amd64";
          autoStart = true;
          extraOptions = ["--network=resume-net"];
          environment = {
            TIMEOUT = "10000";
            CONCURRENT = "10";
            EXIT_ON_HEALTH_FAILURE = "true";
            PRE_REQUEST_HEALTH_CHECK = "true";
            TZ = "America/New_York";
          };
          environmentFiles = [config.sops.secrets.chrome-env.path];
        };
        resume-app = {
          image = containers-sha."docker.io"."amruthpillai/reactive-resume"."latest"."linux/amd64";
          autoStart = true;
          dependsOn = ["resume-postgres" "resume-minio" "resume-chrome"];
          extraOptions =
            ["--network=resume-net"]
            ++ map (dns: "--dns=${dns}") config.soft-secrets.networking.nameservers.internal;
          ports = [
            "127.0.0.1:${proxyPort}:3000"
          ];
          environment = {
            PORT = "3000";
            NODE_ENV = "production";
            PUBLIC_URL = "https://${host}.${config.soft-secrets.networking.domain}";
            STORAGE_URL = "https://${host}.${config.soft-secrets.networking.domain}/storage";
            CHROME_URL = "ws://resume-chrome:3000";
            STORAGE_ENDPOINT = "resume-minio";
            STORAGE_PORT = "9000";
            STORAGE_REGION = "us-east-1";
            STORAGE_BUCKET = "default";
            STORAGE_USE_SSL = "false";
            STORAGE_SKIP_BUCKET_CHECK = "false";
            MAIL_FROM = "noreply@${config.soft-secrets.networking.domain}";
            TZ = "America/New_York";
          };
          environmentFiles = [config.sops.secrets.resume-env.path];
        };
      };
    };
  };
}
