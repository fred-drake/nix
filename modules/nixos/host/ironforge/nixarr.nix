{
  config,
  pkgs,
  ...
}: let
  inherit (config.soft-secrets.networking) domain;

  # Helper to generate nginx virtualHost + ACME cert for a service
  mkMediaProxy = name: port: {
    acmeCert = {
      "${name}.${domain}" = {
        domain = "${name}.${domain}";
        dnsProvider = "cloudflare";
        dnsResolver = "1.1.1.1:53";
        webroot = null;
        listenHTTP = null;
        s3Bucket = null;
        environmentFile = config.sops.secrets.cloudflare-api-key.path;
      };
    };
    virtualHost = {
      "${name}.${domain}" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString port}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            proxy_connect_timeout 300;
            proxy_send_timeout 300;
            proxy_read_timeout 300;

            client_max_body_size 0;
          '';
        };
      };
    };
  };

  mediaServices = [
    {
      name = "jellyfin";
      port = 8096;
    }
    {
      name = "jellyseerr";
      port = 5055;
    }
    {
      name = "sonarr";
      port = 8989;
    }
    {
      name = "radarr";
      port = 7878;
    }
    {
      name = "lidarr";
      port = 8686;
    }
    {
      name = "prowlarr";
      port = 9696;
    }
    {
      name = "sabnzbd";
      port = 6336;
    }
    {
      name = "bazarr";
      port = 6767;
    }
  ];

  proxies = map (s: mkMediaProxy s.name s.port) mediaServices;
in {
  # nixarr service configuration
  nixarr = {
    enable = true;
    mediaDir = "/data/media";
    stateDir = "/data/.state/nixarr";

    jellyfin.enable = true;
    jellyseerr.enable = true;
    sonarr.enable = true;
    radarr.enable = true;
    lidarr.enable = true;
    prowlarr.enable = true;
    bazarr.enable = true;

    sabnzbd = {
      enable = true;
      whitelistHostnames = [
        "sabnzbd.${domain}"
      ];
    };

    recyclarr = {
      enable = true;
      configuration = {
        sonarr = {
          sonarr = {
            base_url = "http://127.0.0.1:8989";
            api_key = "!env_var SONARR_API_KEY";
          };
        };
        radarr = {
          radarr = {
            base_url = "http://127.0.0.1:7878";
            api_key = "!env_var RADARR_API_KEY";
          };
        };
      };
    };
  };

  # ACME certificates for all media services
  security.acme.certs = builtins.foldl' (acc: p: acc // p.acmeCert) {} proxies;

  # nginx reverse proxies for all media services
  services.nginx = {
    enable = true;
    virtualHosts = builtins.foldl' (acc: p: acc // p.virtualHost) {} proxies;
  };

  # CIFS utilities
  environment.systemPackages = [pkgs.cifs-utils];

  # Videos CIFS mount - used as nixarr mediaDir
  fileSystems."/data/media" = {
    device = "//u543742.your-storagebox.de/u543742-sub2";
    fsType = "cifs";
    options = [
      "credentials=${config.sops.templates."videos-storage-credentials".path}"
      "_netdev"
      "noauto"
      "x-systemd.automount"
      "uid=0"
      "gid=169"
      "dir_mode=0775"
      "file_mode=0775"
      "iocharset=utf8"
      "mapposix"
    ];
  };

  # Downloads CIFS mount - auxiliary storage
  fileSystems."/mnt/downloads-storage" = {
    device = "//u543742.your-storagebox.de/u543742-sub6";
    fsType = "cifs";
    options = [
      "credentials=${config.sops.templates."downloads-storage-credentials".path}"
      "_netdev"
      "noauto"
      "x-systemd.automount"
      "uid=0"
      "gid=169"
      "dir_mode=0775"
      "file_mode=0775"
      "iocharset=utf8"
      "mapposix"
    ];
  };

  # Ensure media group exists with GID 169 (nixarr default)
  users.groups.media.gid = 169;
}
