{
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  inherit (config.soft-secrets.networking) domain;

  containers-sha = import ../../apps/fetcher/containers-sha.nix {inherit pkgs;};
  mkPodmanNetwork = import ../../lib/mk-podman-network.nix {inherit pkgs;};
  mkNginxProxy = import ../../lib/mk-nginx-proxy.nix {inherit config;};

  tz = "America/New_York";

  # ---------------------------------------------------------------------------
  # nixarr -> podman migration toggle.
  #
  # Each media service runs either under the nixarr module (the legacy default)
  # or as a pinned podman container. To migrate a service, add its name to
  # `migrated`: that flips the nixarr `<svc>.enable` to false and activates the
  # matching oci-container below. Migrate ONE service per deploy, verify, then
  # move on (see docs/nixarr-to-podman-migration.md).
  #
  # Service name == its config dir under /data/.state/nixarr/<name> (so "seerr",
  # not "jellyseerr").
  # ---------------------------------------------------------------------------
  # recyclarr is included here to take it OFF nixarr (its module asserts that
  # sonarr or radarr must be enabled in nixarr, which fails once both are
  # migrated). It has no container yet — it is temporarily disabled pending its
  # own containerization. Its config under …/recyclarr is preserved.
  migrated = ["bazarr" "sabnzbd" "seerr" "lidarr" "sonarr" "radarr" "recyclarr" "prowlarr" "jellyfin"];
  isPodman = name: builtins.elem name migrated;
  isNixarr = name: !(isPodman name);

  configRoot = name: "/data/.state/nixarr/${name}";

  # nginx reverse proxies for every web UI, regardless of backend. nixarr and
  # the containers both publish their web port on 127.0.0.1:<port>, so the proxy
  # target is identical across the cutover.
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
      # seerr's web UI is served under its canonical `seerr` name. The legacy
      # `jellyseerr` name still resolves but 301-redirects here (see
      # jellyseerrRedirect below) so old bookmarks/clients keep working.
      host = "seerr";
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

  # Legacy jellyseerr -> seerr permanent redirect. seerr is the canonical name;
  # this vhost keeps the old jellyseerr URL alive but 301s every request (path
  # preserved) to the seerr name so bookmarks/clients update themselves.
  jellyseerrRedirect = let
    fqdn = "jellyseerr.${domain}";
  in {
    security.acme.certs.${fqdn} = {};
    services.nginx.virtualHosts.${fqdn} = {
      useACMEHost = fqdn;
      forceSSL = true;
      globalRedirect = "seerr.${domain}";
    };
  };

  # ---------------------------------------------------------------------------
  # LinuxServer.io container factory.
  #
  # All containers run as the shared `media` identity (uid:gid 169:169) so they
  # can read/write the gid=169, mode-0775 CIFS mounts. UMASK=002 keeps new files
  # group-writable (CIFS can't chmod, so this replaces the old chmod fixups).
  # The app's existing nixarr config dir is adopted directly as /config.
  # ---------------------------------------------------------------------------
  mkLs = {
    name,
    image,
    port,
    containerPort ? port,
    configMount ? "/config",
    volumes ? [],
    environment ? {},
    extraOptions ? [],
    # When set, run the container with `--user` instead of LinuxServer's
    # PUID/PGID env (for non-LS images such as jellyseerr).
    user ? null,
  }: {
    ${name} = {
      inherit image;
      autoStart = true;
      extraOptions =
        ["--network=media-net"]
        ++ lib.optional (user != null) "--user=${user}"
        ++ extraOptions;
      ports = ["127.0.0.1:${toString port}:${toString containerPort}"];
      volumes = ["${configRoot name}:${configMount}"] ++ volumes;
      environment =
        (lib.optionalAttrs (user == null) {
          PUID = "169";
          PGID = "169";
          UMASK = "002";
        })
        // {TZ = tz;}
        // environment;
    };
  };

  # Per-service container specs. Only those listed in `migrated` are activated
  # (filtered below); the rest are added here as each service is migrated.
  # Plain attrset merge (each mkLs yields a single-key attrset) so filterAttrs
  # below sees the service names, not a mkMerge wrapper.
  containerDefs = lib.foldl' (acc: c: acc // c) {} [
    (mkLs {
      name = "bazarr";
      image = containers-sha."ghcr.io"."linuxserver/bazarr"."latest"."linux/amd64";
      port = 6767;
      # bazarr writes subtitles next to the video files on the media share, so
      # it needs the library bound at the same absolute path the *arrs report.
      volumes = ["/data/media:/data/media"];
    })
    (mkLs {
      name = "sabnzbd";
      image = containers-sha."ghcr.io"."linuxserver/sabnzbd"."latest"."linux/amd64";
      port = 6336;
      # Downloads land under /data/media/usenet/{.incomplete,manual,tv,movies,…}
      # (per sabnzbd.ini), so it needs the media share at the same absolute path
      # sonarr/radarr import from. sabnzbd binds 0.0.0.0:6336 inside the
      # container (sabnzbd.ini host set to 0.0.0.0 during cutover); we publish it
      # only on loopback and let nginx terminate TLS.
      volumes = ["/data/media:/data/media"];
    })
    (mkLs {
      name = "seerr";
      image = containers-sha."ghcr.io"."seerr-team/seerr"."latest"."linux/amd64";
      port = 5055;
      # seerr (the merged overseerr+jellyseerr successor) is not a LinuxServer
      # image: it ignores PUID/PGID and expects its data at /app/config, not
      # /config. Run it directly as the shared media identity so the adopted
      # settings.json + db are read/written as 169:169. The config layout is
      # unchanged from jellyseerr, so seerr auto-migrates the existing db in
      # place on first start (one-way — see seerr.jellyseerr-bak on the host).
      configMount = "/app/config";
      user = "169:169";
      # seerr no longer bundles an init process (the container runs rootless and
      # expects the runtime to reap), so supply one with --init.
      #
      # seerr connects to jellyfin (login/auth) and sonarr/radarr (request
      # routing) by their public FQDNs over nginx:443. podman copies the host's
      # /etc/hosts into the container, where those names map to 127.0.0.1 (the
      # host's own loopback-to-nginx) — meaningless inside the container, so login
      # fails with "Unable to connect to Jellyfin server". Map each FQDN to
      # host-gateway; --add-host entries take precedence over the propagated
      # 127.0.0.1, so the container reaches the host's nginx (TLS terminator).
      # Drop an entry once its target is on media-net and seerr points at the
      # container name instead.
      extraOptions =
        ["--init"]
        ++ map (h: "--add-host=${h}.${domain}:host-gateway") [
          "jellyfin"
          "sonarr"
          "radarr"
        ];
    })
    (mkLs {
      name = "lidarr";
      image = containers-sha."ghcr.io"."linuxserver/lidarr"."latest"."linux/amd64";
      port = 8686;
      # Standard *arr: config.xml + lidarr.db adopted as /config; needs the media
      # library at the same absolute path it has recorded for root folders +
      # imports (downloads also land under /data/media/usenet).
      volumes = ["/data/media:/data/media"];
    })
    (mkLs {
      name = "sonarr";
      image = containers-sha."ghcr.io"."linuxserver/sonarr"."latest"."linux/amd64";
      port = 8989;
      # Standard *arr: config.xml + sonarr.db adopted as /config; same media bind
      # at the recorded absolute path for root folders + imports. After cutover,
      # repoint its SABnzbd download client to the media-net name sabnzbd:6336
      # (plaintext) — sabnzbd's host_whitelist already includes "sabnzbd".
      volumes = ["/data/media:/data/media"];
    })
    (mkLs {
      name = "radarr";
      image = containers-sha."ghcr.io"."linuxserver/radarr"."latest"."linux/amd64";
      port = 7878;
      # Standard *arr: config.xml + radarr.db adopted as /config; same media bind
      # + post-cutover SABnzbd download-client repoint to sabnzbd:6336 plaintext.
      volumes = ["/data/media:/data/media"];
    })
    (mkLs {
      name = "prowlarr";
      image = containers-sha."ghcr.io"."linuxserver/prowlarr"."latest"."linux/amd64";
      port = 9696;
      # Indexer manager: config.xml + prowlarr.db adopted as /config. No media
      # bind needed (it only talks to the *arrs + indexers). After cutover,
      # repoint its Apps (Settings → Apps) to the media-net names
      # http://sonarr:8989 / http://radarr:7878 / http://lidarr:8686 plaintext.
    })
    (mkLs {
      name = "jellyfin";
      image = containers-sha."ghcr.io"."linuxserver/jellyfin"."latest"."linux/amd64";
      port = 8096;
      # Largest config dir (config/ data/ cache/ log/) adopted as /config; media
      # library bound read-only — jellyfin only reads it. NO /dev/dri: this host
      # software-transcodes (encoding.xml HardwareAccelerationType=none), so no
      # device passthrough is needed to preserve current behavior. MemoryHigh=4G
      # is applied to the podman-jellyfin unit below.
      volumes = ["/data/media:/data/media:ro"];
    })
  ];

  activeContainers = lib.filterAttrs (n: _: isPodman n) containerDefs;
  activeNetworkUnits = map (n: "podman-${n}.service") (builtins.attrNames activeContainers);

  # SABnzbd health check — detects stuck downloads (queued, not paused, zero
  # speed for N consecutive checks) or an unresponsive API and restarts the
  # unit. Identical logic on either backend; only the restart target differs
  # (nixarr `sabnzbd` vs `podman-sabnzbd`). Reads the api key from the same
  # sabnzbd.ini, which is the bind-mounted /config under podman.
  sabnzbdHealthcheck = restartUnit:
    pkgs.writeShellScript "sabnzbd-healthcheck" ''
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
        systemctl restart ${restartUnit}
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
            systemctl restart ${restartUnit}
          fi
          exit 0
        fi
      fi

      # All good, reset counter
      rm -f "$STATE_FILE"
      echo "SABnzbd healthy: speed=''${speed}KB/s status=$status slots=$slots paused=$paused"
    '';

  # recyclarr (podman): a run-to-completion quality-profile sync, not a daemon,
  # so it runs as a systemd timer + `podman run --rm` (below) rather than an
  # oci-container. The config mirrors the former inline nixarr block — just the
  # two *arr instances, no templates — with media-net container names instead of
  # 127.0.0.1. API keys are injected at runtime from each *arr's preserved
  # config.xml (see the recyclarr-sync service), never entering the nix store.
  recyclarrImage = containers-sha."ghcr.io"."recyclarr/recyclarr"."latest"."linux/amd64";
  recyclarrYml = pkgs.writeText "recyclarr.yml" ''
    sonarr:
      sonarr:
        base_url: http://sonarr:8989
        api_key: !env_var SONARR_API_KEY
    radarr:
      radarr:
        base_url: http://radarr:7878
        api_key: !env_var RADARR_API_KEY
  '';

  mkCifsMount = import ../../lib/mk-cifs-mount.nix {inherit config pkgs;};
  # Halve CIFS write buffer from the default 4 MiB to 1 MiB so each in-flight
  # SMB3-encrypted write asks the page allocator for an order-2 region (16
  # KiB) instead of order-4 (64 KiB). Reduces ENOMEM risk on this 7.6 GiB
  # host under sabnzbd write pressure.
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
      jellyseerrRedirect
    ]
    ++ mediaProxies
    ++ [
      {
        # nixarr service configuration. Each service is enabled only while it has
        # not been migrated to a podman container (see `migrated` above).
        nixarr = {
          enable = true;
          mediaDir = "/data/media";
          stateDir = "/data/.state/nixarr";

          # nixarr's bundled `nixarr_py` wheel declares a runtime dependency on
          # a distribution named `jellyfin`, but its generated client installs
          # as `jellyfin-py`, so nixpkgs' (now default-on) pythonRuntimeDepsCheckHook
          # fails the build with "jellyfin not installed". Upstream is unfixed as
          # of 2026-05; disable the check for this package only. Remove if/when
          # nixarr corrects the dependency metadata (or when nixarr is fully
          # decommissioned at the end of this migration).
          nixarr-py.package =
            options.nixarr.nixarr-py.package.default.overridePythonAttrs
            (_: {dontCheckRuntimeDeps = true;});

          jellyfin.enable = isNixarr "jellyfin";
          # nixarr renamed jellyseerr -> seerr; config dir is still …/seerr.
          seerr.enable = isNixarr "seerr";
          sonarr.enable = isNixarr "sonarr";
          radarr.enable = isNixarr "radarr";
          lidarr.enable = isNixarr "lidarr";
          prowlarr.enable = isNixarr "prowlarr";
          bazarr.enable = isNixarr "bazarr";

          sabnzbd = {
            enable = isNixarr "sabnzbd";
            whitelistHostnames = [
              "sabnzbd.${domain}"
            ];
          };

          recyclarr = {
            enable = isNixarr "recyclarr";
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

        # Shared `media` identity for all containers. The group already exists
        # at gid 169 (nixarr default); add a matching user so config dirs can be
        # chowned to a single owner and the CIFS gid-169 ACLs apply.
        users.groups.media.gid = 169;
        users.users.media = {
          isSystemUser = true;
          uid = 169;
          group = "media";
          description = "Shared identity for containerized media services";
        };
      }

      # podman network + container definitions for migrated services.
      (lib.mkIf (activeContainers != {}) {
        systemd.services = mkPodmanNetwork "media" activeNetworkUnits;
        virtualisation.oci-containers = {
          backend = "podman";
          containers = activeContainers;
        };
      })

      # recyclarr quality-profile sync (podman timer + oneshot). recyclarr is a
      # batch tool, so it runs `podman run --rm ... sync` on a daily timer rather
      # than as a long-lived oci-container. It joins media-net to reach
      # sonarr:8989 / radarr:7878 and runs as the shared media identity (169).
      (lib.mkIf (isPodman "recyclarr") {
        systemd.services.recyclarr-sync = {
          description = "Recyclarr quality-profile sync";
          after = [
            "podman-network-media.service"
            "podman-sonarr.service"
            "podman-radarr.service"
          ];
          serviceConfig = {
            Type = "oneshot";
            RuntimeDirectory = "recyclarr";
            # Read each *arr's API key from its preserved config.xml into a tmpfs
            # env file (mode 0600, gone on reboot) so keys never hit the nix
            # store or `ps` output, then sync.
            ExecStart = pkgs.writeShellScript "recyclarr-sync" ''
              set -eu
              sk=$(${pkgs.gnugrep}/bin/grep -oE '<ApiKey>[a-f0-9]+</ApiKey>' /data/.state/nixarr/sonarr/config.xml | ${pkgs.gnused}/bin/sed 's/<[^>]*>//g')
              rk=$(${pkgs.gnugrep}/bin/grep -oE '<ApiKey>[a-f0-9]+</ApiKey>' /data/.state/nixarr/radarr/config.xml | ${pkgs.gnused}/bin/sed 's/<[^>]*>//g')
              umask 077
              printf 'SONARR_API_KEY=%s\nRADARR_API_KEY=%s\n' "$sk" "$rk" > "$RUNTIME_DIRECTORY/env"
              ${pkgs.podman}/bin/podman rm -f recyclarr-sync 2>/dev/null || true
              exec ${pkgs.podman}/bin/podman run --rm --name recyclarr-sync \
                --network=media-net \
                --user 169:169 \
                --env-file "$RUNTIME_DIRECTORY/env" \
                -e TZ=${tz} \
                -v /data/.state/nixarr/recyclarr:/config \
                -v ${recyclarrYml}:/config/recyclarr.yml:ro \
                ${recyclarrImage} sync
            '';
          };
        };
        systemd.timers.recyclarr-sync = {
          wantedBy = ["timers.target"];
          timerConfig = {
            OnCalendar = "daily";
            Persistent = true;
            RandomizedDelaySec = "1h";
          };
        };
      })

      # Per-service systemd customizations. The nixarr and podman variants of a
      # service are mutually exclusive (exactly one is active), so the guarded
      # blocks never collide.
      {
        systemd = {
          services = lib.mkMerge [
            (lib.mkIf (isNixarr "jellyfin") {
              # Cap jellyfin memory so library scans don't push the rest of the
              # services into swap. Soft limit — kernel reclaims if exceeded but
              # the service isn't killed.
              jellyfin.serviceConfig.MemoryHigh = "4G";
            })

            (lib.mkIf (isPodman "jellyfin") {
              # Same 4G soft cap, now on the oci-container's systemd unit.
              "podman-jellyfin".serviceConfig.MemoryHigh = "4G";
            })

            (lib.mkIf (isNixarr "sabnzbd") {
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

              sabnzbd-healthcheck = {
                description = "SABnzbd health check";
                after = ["sabnzbd.service"];
                serviceConfig = {
                  Type = "oneshot";
                  ExecStart = sabnzbdHealthcheck "sabnzbd";
                };
              };
            })

            (lib.mkIf (isPodman "sabnzbd") {
              # MemoryHigh on the oci-container's systemd unit (oci-containers are
              # systemd services, so the cap still applies). cache_limit and the
              # blanked `permissions` now live in the preserved sabnzbd.ini under
              # /config, and PGID 169 + UMASK 002 replace the old chmod fixup.
              #
              # The ExecStartPre silences SABnzbd's "not writable with special
              # character filenames" warnings: the usenet download dirs live on the
              # CIFS/SMB media mount, which can't store certain characters, so
              # SABnzbd's startup probe fails harmlessly. Force helpful_warnings = 0
              # in the bind-mounted ini before the container starts.
              "podman-sabnzbd".serviceConfig = {
                MemoryHigh = "2G";
                ExecStartPre = lib.mkAfter [
                  (pkgs.writeShellScript "sabnzbd-disable-helpful-warnings" ''
                    ini="/data/.state/nixarr/sabnzbd/sabnzbd.ini"
                    [ -f "$ini" ] || exit 0
                    if ${pkgs.gnugrep}/bin/grep -q '^helpful_warnings = ' "$ini"; then
                      ${pkgs.gnused}/bin/sed -i 's/^helpful_warnings = .*/helpful_warnings = 0/' "$ini"
                    else
                      # Key absent: insert it directly under the [misc] section header.
                      ${pkgs.gnused}/bin/sed -i '/^\[misc\]/a helpful_warnings = 0' "$ini"
                    fi
                    # Keep the NewsDemon server on its EU endpoint.
                    ${pkgs.gnused}/bin/sed -i 's/news\.newsdemon\.com/eu.newsdemon.com/g' "$ini"
                  '')
                ];
              };

              sabnzbd-healthcheck = {
                description = "SABnzbd health check";
                after = ["podman-sabnzbd.service"];
                serviceConfig = {
                  Type = "oneshot";
                  ExecStart = sabnzbdHealthcheck "podman-sabnzbd";
                };
              };
            })
          ];

          # The health-check timer fires regardless of backend; the
          # sabnzbd-healthcheck unit exists under both (sabnzbd is always present
          # in this module on one backend or the other).
          timers.sabnzbd-healthcheck = {
            wantedBy = ["timers.target"];
            timerConfig = {
              OnCalendar = "*:0/5";
              Persistent = true;
            };
          };
        };
      }

      # Single-NIC saturation guard. ironforge has one uplink and its media
      # library lives on a remote Hetzner Storage Box reached over that same NIC
      # via CIFS. When a client can't Direct Play a file (e.g. the Jellyfin web
      # UI with an MKV/EAC3 source), jellyfin's ffmpeg buffers ahead by reading
      # the source at line rate (~400 Mbit/s observed), saturating the uplink so
      # SSH, ping, and the web UI all stall until the read finishes. Police
      # inbound traffic from the Storage Box down to 150 Mbit/s so a transcode
      # read always leaves headroom for management + the ~10 Mbit/s client
      # stream. Pairs with jellyfin's EnableThrottling (set in its own /config).
      # The Storage Box address and uplink are resolved at runtime so the rule
      # survives an IP or interface rename.
      {
        systemd.services.storage-read-shaper = {
          description = "Rate-limit CIFS reads from the Hetzner Storage Box (single-NIC saturation guard)";
          after = ["network-online.target"];
          wants = ["network-online.target"];
          wantedBy = ["multi-user.target"];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "storage-read-shaper-start" ''
              set -u
              host="u543742.your-storagebox.de" # mirrors lib/mk-cifs-mount.nix
              rate="150mbit"
              ips=$(${pkgs.dnsutils}/bin/dig +short A "$host" | ${pkgs.gnugrep}/bin/grep -E '^[0-9.]+$')
              if [ -z "$ips" ]; then echo "storage-read-shaper: could not resolve $host"; exit 0; fi
              first=$(echo "$ips" | ${pkgs.coreutils}/bin/head -1)
              ifc=$(${pkgs.iproute2}/bin/ip -o route get "$first" | ${pkgs.gawk}/bin/awk '{for (i=1; i<=NF; i++) if ($i == "dev") print $(i+1)}')
              if [ -z "$ifc" ]; then echo "storage-read-shaper: could not determine uplink"; exit 0; fi
              ${pkgs.iproute2}/bin/tc qdisc del dev "$ifc" ingress 2>/dev/null || true
              ${pkgs.iproute2}/bin/tc qdisc add dev "$ifc" handle ffff: ingress
              for ip in $ips; do
                ${pkgs.iproute2}/bin/tc filter add dev "$ifc" parent ffff: protocol ip prio 1 u32 \
                  match ip src "$ip"/32 \
                  police rate "$rate" burst 800k mtu 64k drop flowid :1
                echo "storage-read-shaper: capping reads from $ip on $ifc at $rate"
              done
            '';
            ExecStop = pkgs.writeShellScript "storage-read-shaper-stop" ''
              set -u
              host="u543742.your-storagebox.de"
              first=$(${pkgs.dnsutils}/bin/dig +short A "$host" | ${pkgs.gnugrep}/bin/grep -E '^[0-9.]+$' | ${pkgs.coreutils}/bin/head -1)
              [ -n "$first" ] || exit 0
              ifc=$(${pkgs.iproute2}/bin/ip -o route get "$first" | ${pkgs.gawk}/bin/awk '{for (i=1; i<=NF; i++) if ($i == "dev") print $(i+1)}')
              [ -n "$ifc" ] && ${pkgs.iproute2}/bin/tc qdisc del dev "$ifc" ingress 2>/dev/null || true
            '';
          };
        };
      }
    ])
