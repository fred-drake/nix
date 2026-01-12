{
  config,
  pkgs,
  ...
}: let
  containers-sha = import ./fetcher/containers-sha.nix {inherit pkgs;};
  host = "woodpecker";
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
            '';
          };
        };
      };
    };
  };

  systemd = {
    tmpfiles.rules = [
      "d /var/woodpecker/data 0755 1000 1000 -"
      "d /var/postgresql 0755 999 999 -"
    ];
    services = {
      podman-network-woodpecker = {
        description = "Create woodpecker podman network with DNS enabled";
        wantedBy = ["multi-user.target"];
        before = ["podman-woodpecker-postgres.service" "podman-woodpecker-server.service" "podman-woodpecker-agent.service"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.podman}/bin/podman network create --ignore woodpecker-net";
        };
      };
      podman-woodpecker-agent = {
        after = ["podman.socket"];
        bindsTo = ["podman.socket"];
      };
    };
    # Ensure the socket is properly created at boot
    sockets.podman = {
      wantedBy = ["sockets.target"];
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
        woodpecker-postgres = {
          image = containers-sha."docker.io"."postgres"."18"."linux/amd64";
          autoStart = true;
          extraOptions = ["--network=woodpecker-net"];
          ports = [
            "0.0.0.0:5432:5432"
          ];
          volumes = [
            "/var/postgresql:/var/lib/postgresql"
          ];
          environment = {
            TZ = "America/New_York";
          };
          environmentFiles = [config.sops.secrets.postgresql-env.path];
        };
        woodpecker-server = {
          image = containers-sha."docker.io"."woodpeckerci/woodpecker-server"."v3"."linux/amd64";
          autoStart = true;
          dependsOn = ["woodpecker-postgres"];
          extraOptions =
            ["--network=woodpecker-net"]
            ++ map (dns: "--dns=${dns}") config.soft-secrets.networking.nameservers.internal;
          ports = [
            "127.0.0.1:${proxyPort}:8000"
          ];
          volumes = [
            "/var/woodpecker/data:/var/lib/woodpecker"
          ];
          environment = {
            WOODPECKER_HOST = "https://${host}.${config.soft-secrets.networking.domain}";
            WOODPECKER_DATABASE_DRIVER = "postgres";
            WOODPECKER_OPEN = "true";
            WOODPECKER_PLUGINS_PRIVILEGED = "woodpeckerci/plugin-docker-buildx";
            TZ = "America/New_York";
          };
          environmentFiles = [config.sops.secrets.woodpecker-env.path];
        };
        woodpecker-agent = {
          image = containers-sha."docker.io"."woodpeckerci/woodpecker-agent"."v3"."linux/amd64";
          autoStart = true;
          dependsOn = ["woodpecker-server"];
          extraOptions = [
            "--network=woodpecker-net"
            "--privileged"
          ];
          volumes = [
            "/run/podman/podman.sock:/var/run/docker.sock"
          ];
          environment = {
            WOODPECKER_SERVER = "woodpecker-server:9000";
            WOODPECKER_BACKEND = "docker";
            TZ = "America/New_York";
          };
          environmentFiles = [config.sops.secrets.woodpecker-agent-env.path];
        };
      };
    };
  };
}
