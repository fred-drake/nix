# Matrix Synapse homeserver — replaces Conduit on undercity (dedicated public
# box). See modules/services/matrix-conduit.nix for the host rationale; this
# keeps the exact same public layout.
#
# Native NixOS modules rather than containers: the synapse module generates
# homeserver.yaml and persists signing keys, Postgres via local peer auth needs
# no password, and Coturn needs host UDP ranges that podman publishes badly.
# (Only future LiveKit Egress recording would be a container.)
#
#   - server_name = matrix.freddrake.com (PERMANENT) == the host's public name,
#     so there is NO split-horizon DNS and NO delegation.
#   - Client–Server API on 443, federation on 8448, both public. nginx
#     terminates TLS and proxies to Synapse's loopback http listener.
#   - Signing keys auto-generate and persist under /var/lib/matrix-synapse.
#
# Secrets (random, generated once, stored in the external nix-secrets repo as
# individual keys — no opaque blobs):
#   host/undercity/synapse  keys: registration_shared_secret,
#                                 macaroon_secret_key, form_secret
#   host/undercity/turn     key:  shared-secret
# The turn shared-secret is the single source of truth: Synapse's
# turn_shared_secret is rendered from it below, so the value lives in exactly
# one place. Synapse's homeserver.yaml fragment is assembled from these keys
# with a sops template (extraConfigFiles needs a YAML file).
#
# Accounts are created AFTER the first deploy (registration is otherwise
# closed), pointing -c at the rendered fragment (it carries
# registration_shared_secret):
#   register_new_matrix_user -c /run/secrets/rendered/synapse-extra-config.yaml \
#     -u fred   -a         http://localhost:8008   # server admin
#   register_new_matrix_user -c /run/secrets/rendered/synapse-extra-config.yaml \
#     -u hermes --no-admin http://localhost:8008
#   register_new_matrix_user -c /run/secrets/rendered/synapse-extra-config.yaml \
#     -u gatus  --no-admin http://localhost:8008
{
  config,
  pkgs,
  ...
}: let
  serverName = "matrix.freddrake.com";
  baseUrl = "https://${serverName}";
  synapsePort = 8008;
  acmeDir = config.security.acme.certs.${serverName}.directory;
in {
  # Client API (443) + federation (8448) + coturn STUN/TURN (3478/5349 and the
  # relay range). Nothing else runs on this box. The Hetzner cloud firewall is
  # managed separately; these are the host nftables rules.
  networking.firewall = {
    allowedTCPPorts = [443 8448 3478 5349];
    allowedUDPPorts = [3478 5349];
    allowedUDPPortRanges = [
      {
        from = 49152;
        to = 49252;
      }
    ];
  };

  sops = {
    secrets = {
      synapse-registration-shared-secret = {
        sopsFile = config.secrets.host.undercity.synapse;
        key = "registration_shared_secret";
        mode = "0400";
      };
      synapse-macaroon-secret-key = {
        sopsFile = config.secrets.host.undercity.synapse;
        key = "macaroon_secret_key";
        mode = "0400";
      };
      synapse-form-secret = {
        sopsFile = config.secrets.host.undercity.synapse;
        key = "form_secret";
        mode = "0400";
      };
      turn-shared-secret = {
        sopsFile = config.secrets.host.undercity.turn;
        key = "shared-secret";
        mode = "0400";
        owner = "turnserver";
        restartUnits = ["coturn.service"];
      };
    };
    # Assemble Synapse's homeserver.yaml secret fragment from the individual
    # keys. turn_shared_secret is pulled from the one turn secret, so Synapse
    # and coturn always agree (and there's nothing to keep in sync by hand).
    templates."synapse-extra-config.yaml" = {
      owner = "matrix-synapse";
      restartUnits = ["matrix-synapse.service"];
      content = ''
        registration_shared_secret: "${config.sops.placeholder.synapse-registration-shared-secret}"
        macaroon_secret_key: "${config.sops.placeholder.synapse-macaroon-secret-key}"
        form_secret: "${config.sops.placeholder.synapse-form-secret}"
        turn_shared_secret: "${config.sops.placeholder.turn-shared-secret}"
      '';
    };
  };

  # PostgreSQL — native, local unix-socket peer auth (no password secret).
  # Synapse requires its database created with C collation; template0 + explicit
  # LC_* guarantees that regardless of the cluster's default locale. The script
  # runs once, when the data directory is first initialised (fresh box).
  services.postgresql = {
    enable = true;
    initialScript = pkgs.writeText "synapse-pg-init.sql" ''
      CREATE ROLE "matrix-synapse" WITH LOGIN;
      CREATE DATABASE "matrix-synapse"
        WITH OWNER "matrix-synapse"
             TEMPLATE template0
             LC_COLLATE = "C"
             LC_CTYPE = "C";
    '';
  };

  services.matrix-synapse = {
    enable = true;
    # Secret values (registration_shared_secret, macaroon_secret_key,
    # form_secret, turn_shared_secret) are appended from the rendered sops
    # template so they never enter the world-readable nix store.
    extraConfigFiles = [config.sops.templates."synapse-extra-config.yaml".path];
    settings = {
      server_name = serverName;
      public_baseurl = baseUrl;
      report_stats = false;
      # nginx terminates TLS and proxies to this loopback http listener; both
      # the client and federation resources are served here (443 and 8448
      # upstream both hit this port).
      listeners = [
        {
          port = synapsePort;
          bind_addresses = ["127.0.0.1"];
          type = "http";
          tls = false;
          x_forwarded = true;
          resources = [
            {
              names = ["client" "federation"];
              compress = false;
            }
          ];
        }
      ];
      database = {
        name = "psycopg2";
        args = {
          user = "matrix-synapse";
          database = "matrix-synapse";
        };
      };
      # Registration is closed; accounts are minted with register_new_matrix_user
      # using the registration_shared_secret (see header).
      enable_registration = false;
      max_upload_size = "50M";
      # TURN for 1:1 calls — turn_shared_secret arrives via extraConfigFiles.
      turn_uris = [
        "turns:${serverName}:5349?transport=udp"
        "turns:${serverName}:5349?transport=tcp"
        "turn:${serverName}:3478?transport=udp"
        "turn:${serverName}:3478?transport=tcp"
      ];
      turn_user_lifetime = "1h";
      turn_allow_guests = false;
      # Keep memory modest on the 8GB box and avoid OOM from joining huge
      # federated rooms.
      caches.global_factor = 0.5;
      limit_remote_rooms = {
        enabled = true;
        complexity = 0.5;
      };
    };
  };

  # Synapse must come up after its database.
  systemd.services.matrix-synapse = {
    after = ["postgresql.service"];
    requires = ["postgresql.service"];
  };

  # Coturn — TURN relay for 1:1 calls, shared-secret auth keyed to Synapse's
  # turn_shared_secret. Reuses the nginx ACME cert for turns: (5349).
  services.coturn = {
    enable = true;
    realm = serverName;
    use-auth-secret = true;
    static-auth-secret-file = config.sops.secrets.turn-shared-secret.path;
    no-tcp-relay = true;
    min-port = 49152;
    max-port = 49252;
    cert = "${acmeDir}/fullchain.pem";
    pkey = "${acmeDir}/key.pem";
    extraConfig = ''
      no-multicast-peers
      denied-peer-ip=10.0.0.0-10.255.255.255
      denied-peer-ip=172.16.0.0-172.31.255.255
      denied-peer-ip=192.168.0.0-192.168.255.255
    '';
  };
  # turnserver must be able to read the nginx-group ACME cert, and restart when
  # it renews.
  users.users.turnserver.extraGroups = ["nginx"];

  security.acme.certs.${serverName} = {
    reloadServices = ["coturn.service"];
  };

  services.nginx.virtualHosts.${serverName} = {
    useACMEHost = serverName;
    onlySSL = true;
    listen = [
      {
        addr = "0.0.0.0";
        port = 443;
        ssl = true;
      }
      {
        addr = "[::]";
        port = 443;
        ssl = true;
      }
      {
        addr = "0.0.0.0";
        port = 8448;
        ssl = true;
      }
      {
        addr = "[::]";
        port = 8448;
        ssl = true;
      }
    ];
    locations = {
      "/" = {
        proxyPass = "http://127.0.0.1:${toString synapsePort}";
        proxyWebsockets = true;
        extraConfig = "client_max_body_size 50M;";
      };
      # Client autodiscovery — Element resolves the homeserver from the user's
      # server name.
      "= /.well-known/matrix/client" = {
        extraConfig = ''
          default_type application/json;
          add_header Access-Control-Allow-Origin *;
          return 200 '{"m.homeserver":{"base_url":"${baseUrl}"}}';
        '';
      };
      # Federation discovery — points remote servers at the 8448 endpoint.
      "= /.well-known/matrix/server" = {
        extraConfig = ''
          default_type application/json;
          return 200 '{"m.server":"${serverName}:8448"}';
        '';
      };
    };
  };
}
