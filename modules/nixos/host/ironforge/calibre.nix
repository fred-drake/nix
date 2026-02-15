{
  config,
  pkgs,
  ...
}: let
  containers-sha = import ../../../../apps/fetcher/containers-sha.nix {inherit pkgs;};
  desktopPort = "8082";
  contentServerPort = "8081";
  webPort = "8083";
in {
  security.acme.certs = {
    "calibre-desktop.${config.soft-secrets.networking.domain}" = {
      domain = "calibre-desktop.${config.soft-secrets.networking.domain}";
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      webroot = null;
      listenHTTP = null;
      s3Bucket = null;
      environmentFile = config.sops.secrets.cloudflare-api-key.path;
    };
    "calibre-desktop-web.${config.soft-secrets.networking.domain}" = {
      domain = "calibre-desktop-web.${config.soft-secrets.networking.domain}";
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      webroot = null;
      listenHTTP = null;
      s3Bucket = null;
      environmentFile = config.sops.secrets.cloudflare-api-key.path;
    };
    "calibre-web.${config.soft-secrets.networking.domain}" = {
      domain = "calibre-web.${config.soft-secrets.networking.domain}";
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
      "calibre-desktop.${config.soft-secrets.networking.domain}" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${desktopPort}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };
      "calibre-desktop-web.${config.soft-secrets.networking.domain}" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${contentServerPort}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };
      "calibre-web.${config.soft-secrets.networking.domain}" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${webPort}";
          proxyWebsockets = true;
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

  environment.systemPackages = [pkgs.cifs-utils];

  fileSystems."/mnt/calibre-storage" = {
    device = "//u543742.your-storagebox.de/u543742-sub5";
    fsType = "cifs";
    options = [
      "credentials=${config.sops.templates."calibre-storage-credentials".path}"
      "_netdev"
      "noauto"
      "x-systemd.automount"
      "uid=1000"
      "gid=1000"
      "iocharset=utf8"
      "nobrl"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/calibre-web/config 0755 1000 1000 -"
  ];

  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      calibre = {
        image = containers-sha."ghcr.io"."linuxserver/calibre"."latest"."linux/amd64";
        autoStart = true;
        ports = [
          "127.0.0.1:${desktopPort}:8080"
          "127.0.0.1:${contentServerPort}:8081"
        ];
        volumes = [
          "/mnt/calibre-storage:/config"
        ];
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "America/New_York";
        };
      };
      calibre-web = {
        image = containers-sha."ghcr.io"."linuxserver/calibre-web"."latest"."linux/amd64";
        autoStart = true;
        ports = [
          "127.0.0.1:${webPort}:8083"
        ];
        volumes = [
          "/var/calibre-web/config:/config"
          "/mnt/calibre-storage:/books"
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
