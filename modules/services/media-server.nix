{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.soft-secrets.networking) domain;

  mkNginxProxy = import ../../lib/mk-nginx-proxy.nix {inherit config;};
  mediaProxyExtraConfig = ''
    proxy_connect_timeout 300;
    proxy_send_timeout 300;
    proxy_read_timeout 300;
    client_max_body_size 0;
  '';

  mediaServices = [
    {
      host = "jellyfin";
      port = 8096;
    }
    {
      host = "jellyseerr";
      port = 5055;
    }
    {
      host = "sonarr";
      port = 8989;
    }
    {
      host = "radarr";
      port = 7878;
    }
    {
      host = "lidarr";
      port = 8686;
    }
    {
      host = "prowlarr";
      port = 9696;
    }
    {
      host = "sabnzbd";
      port = 6336;
    }
    {
      host = "bazarr";
      port = 6767;
    }
  ];

  mediaProxies = map (s: mkNginxProxy (s // {extraConfig = mediaProxyExtraConfig;})) mediaServices;

  mkCifsMount = import ../../lib/mk-cifs-mount.nix {inherit config pkgs;};
  # Halve CIFS write buffer from the default 4 MiB to 1 MiB so each in-flight
  # SMB3-encrypted write asks the page allocator for an order-2 region (16
  # KiB) instead of order-4 (64 KiB). Reduces ENOMEM risk on this 7.6 GiB
  # host under sabnzbd write pressure; small throughput cost is acceptable
  # over the ~150 ms WG path where wsize isn't the bottleneck anyway.
  cifsWriteTune = ["wsize=1048576"];
  videosStorage = mkCifsMount {
    name = "videos";
    sub = "sub2";
    secretsHost = "ironforge";
    mountPath = "/data/media";
    uid = "0";
    gid = "169";
    extraOptions = ["dir_mode=0775" "file_mode=0775" "mapposix"] ++ cifsWriteTune;
  };
  downloadsStorage = mkCifsMount {
    name = "downloads";
    sub = "sub6";
    secretsHost = "ironforge";
    uid = "0";
    gid = "169";
    extraOptions = ["dir_mode=0775" "file_mode=0775" "mapposix"] ++ cifsWriteTune;
  };
in
  lib.mkMerge ([
      videosStorage
      downloadsStorage
    ]
    ++ mediaProxies
    ++ [
      {
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

        systemd = {
          services = {
            # Cap jellyfin memory so library scans don't push the rest of the
            # services into swap. Soft limit — kernel reclaims if exceeded but
            # the service isn't killed.
            jellyfin.serviceConfig.MemoryHigh = "4G";

            sabnzbd.serviceConfig = {
              # Cap sabnzbd similarly: its assembler cache plus encrypted SMB3
              # writes had pushed peak RSS over 5 GiB and contributed to the
              # 2026-05-09 page-allocator failures. 2 GiB is comfortably above
              # the 256 MiB internal cache_limit set in the ExecStartPre fixup.
              MemoryHigh = "2G";

              # Override nixarr's hardcoded permissions = "775" for sabnzbd.
              # CIFS mounts don't support chmod, so sabnzbd must not attempt it.
              # Also reduce cache_limit to avoid OOM on this memory-constrained host.
              ExecStartPre = lib.mkAfter [
                (pkgs.writeShellScript "sabnzbd-cifs-fixup" ''
                  ini="/data/.state/nixarr/sabnzbd/sabnzbd.ini"
                  ${pkgs.gnused}/bin/sed -i 's/^permissions = .*/permissions = /' "$ini"
                  ${pkgs.gnused}/bin/sed -i 's/^cache_limit = .*/cache_limit = 256M/' "$ini"
                '')
              ];
            };

            # SABnzbd health check - detects stuck downloads and restarts automatically.
            # Checks every 5 minutes. Restarts if API is unresponsive or if downloads
            # are stuck (queued items, not paused, zero speed) for 3 consecutive checks.
            sabnzbd-healthcheck = {
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
          };

          timers.sabnzbd-healthcheck = {
            wantedBy = ["timers.target"];
            timerConfig = {
              OnCalendar = "*:0/5";
              Persistent = true;
            };
          };
        };

        # Ensure media group exists with GID 169 (nixarr default)
        users.groups.media.gid = 169;
      }
    ])
