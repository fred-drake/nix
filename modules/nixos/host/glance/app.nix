{
  config,
  pkgs,
  ...
}: let
  containers-sha = import ../../../../apps/fetcher/containers-sha.nix {inherit pkgs;};
  host = "glance";
  proxyPort = "8080";
  # Create the glance configuration file
  glanceConfigFile = pkgs.writeTextFile {
    name = "glance-configuration";
    text = builtins.toJSON (import ./glance-config.nix);
    # destination = "/glance.yml";
  };
in {
  imports = [
    ../../../secrets/cloudflare.nix
  ];
  sops.secrets.glance-env = {
    sopsFile = config.secrets.host.glance;
    mode = "0400";
    key = "data";
  };

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
              client_max_body_size 0;
              proxy_request_buffering off;
            '';
          };
        };
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/glance/assets 0755 99 100 -"
    # "d /var/glance/config 0755 99 100 -"
  ];
  # Tmpfiles rules for glance

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
        glance = {
          image = containers-sha."docker.io"."glanceapp/glance"."latest"."linux/amd64";
          autoStart = true;
          ports = [
            "127.0.0.1:${proxyPort}:${proxyPort}"
          ];
          volumes = [
            "/var/glance/assets:/app/assets"
            "${glanceConfigFile.outPath}:/app/config/glance.yml"
          ];
          environment = {
            PUID = "99";
            PGID = "100";
            TZ = "America/New_York";
          };
          environmentFiles = [config.sops.secrets.glance-env.path];
        };
      };
    };
  };
}
