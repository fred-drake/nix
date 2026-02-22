{
  config,
  lib,
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

  # Override nixarr's hardcoded permissions = "775" for sabnzbd.
  # CIFS mounts don't support chmod, so sabnzbd must not attempt it.
  # Also reduce cache_limit to avoid OOM on this memory-constrained host.
  systemd.services.sabnzbd.serviceConfig.ExecStartPre = lib.mkAfter [
    (pkgs.writeShellScript "sabnzbd-cifs-fixup" ''
      ini="/data/.state/nixarr/sabnzbd/sabnzbd.ini"
      ${pkgs.gnused}/bin/sed -i 's/^permissions = .*/permissions = /' "$ini"
      ${pkgs.gnused}/bin/sed -i 's/^cache_limit = .*/cache_limit = 256M/' "$ini"
    '')
  ];

  # SABnzbd health check - detects stuck downloads and restarts automatically.
  # Checks every 5 minutes. Restarts if API is unresponsive or if downloads
  # are stuck (queued items, not paused, zero speed) for 3 consecutive checks.
  systemd.services.sabnzbd-healthcheck = {
    description = "SABnzbd health check";
    after = ["sabnzbd.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "sabnzbd-healthcheck" ''
        STATE_FILE="/tmp/sabnzbd-healthcheck-failures"
        INI="/data/.state/nixarr/sabnzbd/sabnzbd.ini"
        MAX_FAILURES=3

        # Read API key from sabnzbd.ini
        api_key=$(${pkgs.gawk}/bin/awk '/^api_key = / {print $3}' "$INI")
        if [ -z "$api_key" ]; then
          echo "Cannot read API key from $INI"
          exit 1
        fi

        # Query SABnzbd API
        response=$(${pkgs.curl}/bin/curl -sf --max-time 10 \
          "http://127.0.0.1:6336/api?mode=queue&output=json&apikey=$api_key" 2>/dev/null)

        if [ -z "$response" ]; then
          echo "SABnzbd API unresponsive, restarting"
          rm -f "$STATE_FILE"
          systemctl restart sabnzbd
          exit 0
        fi

        # Parse queue status with jq
        paused=$(echo "$response" | ${pkgs.jq}/bin/jq -r '.queue.paused')
        slots=$(echo "$response" | ${pkgs.jq}/bin/jq -r '.queue.noofslots')
        speed=$(echo "$response" | ${pkgs.jq}/bin/jq -r '.queue.kbpersec')
        status=$(echo "$response" | ${pkgs.jq}/bin/jq -r '.queue.status')

        # Check if stuck: has items, not paused, status says Downloading, but zero speed
        if [ "$paused" = "false" ] && [ "$status" = "Downloading" ] && [ "$slots" -gt 0 ] 2>/dev/null; then
          # Speed is a float; check if it rounds to zero
          is_zero=$(${pkgs.gawk}/bin/awk "BEGIN {print ($speed < 1) ? 1 : 0}")
          if [ "$is_zero" = "1" ]; then
            failures=$(cat "$STATE_FILE" 2>/dev/null || echo 0)
            failures=$((failures + 1))
            echo "$failures" > "$STATE_FILE"
            echo "SABnzbd stuck (attempt $failures/$MAX_FAILURES): speed=$speed status=$status slots=$slots"
            if [ "$failures" -ge "$MAX_FAILURES" ]; then
              echo "SABnzbd stuck for $MAX_FAILURES consecutive checks, restarting"
              rm -f "$STATE_FILE"
              systemctl restart sabnzbd
            fi
            exit 0
          fi
        fi

        # All good, reset counter
        rm -f "$STATE_FILE"
        echo "SABnzbd healthy: speed=''${speed}KB/s status=$status slots=$slots paused=$paused"
      '';
    };
  };

  systemd.timers.sabnzbd-healthcheck = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "*:0/5";
      Persistent = true;
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
