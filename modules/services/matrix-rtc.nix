# MatrixRTC (group calls) for undercity — Element Call over a LiveKit SFU plus
# lk-jwt-service, the Matrix<->LiveKit auth bridge. Phase 2 of the Matrix build
# (Phase 1 = the Synapse homeserver in matrix-synapse.nix).
#
# Native NixOS modules (services.livekit / services.lk-jwt-service), matching
# undercity's all-native stack (synapse/coturn/postgres/nginx). The two binaries
# are overridden to nixpkgs-unstable in colmena/hosts/undercity.nix — stable
# 25.05 ships livekit 1.8.4 / lk-jwt 0.3.0, too old for current Element clients
# (the MISSING_MATRIX_RTC_TRANSPORT skew); the overlay pulls 1.13.1 / 0.4.4.
#
#   - LiveKit SFU: signaling/RoomService on 7880 stays PRIVATE (nginx proxies it
#     on loopback); media on UDP 50000-50100 + TCP 7881 fallback, both PUBLIC.
#   - lk-jwt-service: 8080 (private) — issues LiveKit JWTs from Matrix OpenID
#     tokens. The SFU URL is returned by THIS service, not advertised directly.
#   - nginx: dedicated matrix-rtc.freddrake.com vhost; /livekit/sfu -> SFU ws,
#     /livekit/jwt -> lk-jwt (both prefixes stripped). Synapse advertises this
#     host as the rtc_focus in .well-known/matrix/client (see matrix-synapse.nix).
#
# Secret (nix-secrets): host/undercity/livekit  keys: api_key, api_secret.
# Both services consume one "<api_key>: <api_secret>" keyfile, rendered by the
# sops template below so the value lives in exactly one place.
#
# Firewall: TCP 7881 + UDP 50000-50100 are opened here AND must be opened in the
# Hetzner Cloud Firewall (separate, user-managed). 7880/8080 stay closed —
# private, reached only by nginx on 127.0.0.1.
{config, ...}: let
  rtcHost = "matrix-rtc.freddrake.com";
in {
  networking.firewall = {
    allowedTCPPorts = [7881];
    allowedUDPPortRanges = [
      {
        from = 50000;
        to = 50100;
      }
    ];
  };

  sops = {
    secrets = {
      livekit-api-key = {
        sopsFile = config.secrets.host.undercity.livekit;
        key = "api_key";
        mode = "0400";
      };
      livekit-api-secret = {
        sopsFile = config.secrets.host.undercity.livekit;
        key = "api_secret";
        mode = "0400";
      };
    };
    # Both services want a single "<keyname>: <secret>" file. systemd's
    # LoadCredential reads it as root before each unit drops to its DynamicUser,
    # so the rendered root:0400 file is fine.
    templates."livekit.keys" = {
      restartUnits = ["livekit.service" "lk-jwt-service.service"];
      content = ''${config.sops.placeholder.livekit-api-key}: ${config.sops.placeholder.livekit-api-secret}'';
    };
  };

  # LiveKit SFU. package default resolves to the unstable override (1.13.1).
  services.livekit = {
    enable = true;
    # NOT openFirewall: it opens settings.port (7880, must stay private) and the
    # UDP range, but never the TCP fallback. We open 7881 + UDP by hand above.
    openFirewall = false;
    keyFile = config.sops.templates."livekit.keys".path;
    settings = {
      port = 7880;
      # Egress control channel. Single SFU node; redis only enables egress
      # dispatch (and is harmless for normal calls). Redis itself is native,
      # declared in matrix-egress.nix (loopback, no auth).
      redis.address = "127.0.0.1:6379";
      rtc = {
        port_range_start = 50000;
        port_range_end = 50100;
        use_external_ip = true;
        tcp_port = 7881;
      };
    };
  };

  # SFU must start after redis is up.
  systemd.services.livekit = {
    after = ["redis.service"];
    wants = ["redis.service"];
  };

  # Matrix<->LiveKit auth bridge. package default = unstable override (0.4.4).
  services.lk-jwt-service = {
    enable = true;
    port = 8080;
    livekitUrl = "wss://${rtcHost}/livekit/sfu";
    keyFile = config.sops.templates."livekit.keys".path;
  };
  # The 25.05 module sets LIVEKIT_URL/JWT_PORT/KEY_FILE but not the homeserver
  # allowlist; append it so we restrict to our server rather than the default "*".
  systemd.services.lk-jwt-service.environment.LIVEKIT_FULL_ACCESS_HOMESERVERS = "matrix.freddrake.com";

  # Dedicated vhost. ACME DNS-01 (Cloudflare) is inherited from the
  # security.acme defaults set in nginx-acme-proxy.nix — no per-cert plumbing.
  security.acme.certs.${rtcHost} = {};
  services.nginx.virtualHosts.${rtcHost} = {
    useACMEHost = rtcHost;
    forceSSL = true;
    locations = {
      # LiveKit client connects to <livekitUrl>/rtc; trailing slashes strip the
      # /livekit/sfu prefix so the SFU sees /rtc on its loopback port.
      "/livekit/sfu/" = {
        proxyPass = "http://127.0.0.1:7880/";
        proxyWebsockets = true;
      };
      # Client POSTs to <livekit_service_url>/sfu/get; strip /livekit/jwt so
      # lk-jwt sees /sfu/get. lk-jwt-service sets its OWN CORS headers (including
      # the OPTIONS preflight), so nginx must NOT add them — a duplicated
      # `Access-Control-Allow-Origin` makes browsers reject the response, which
      # surfaces in Element Call as a misleading OPEN_ID_ERROR (the /sfu/get 200
      # is logged server-side but the browser can't read the body). Just proxy.
      "/livekit/jwt/" = {
        proxyPass = "http://127.0.0.1:8080/";
      };
    };
  };
}
