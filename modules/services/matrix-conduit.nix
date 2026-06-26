# Matrix Conduit homeserver — runs on its own dedicated public box (undercity)
# as a digest-pinned podman oci-container.
#
# Because Matrix is the ONLY service on this host, the standard public Matrix
# layout is safe and simple — there's nothing else to expose:
#   - server_name = matrix.freddrake.com (PERMANENT), which is also the host's
#     public name, so there is NO split-horizon DNS and NO delegation needed.
#   - Client–Server API on 443 and federation on 8448, both public. Clients
#     auto-discover via /.well-known/matrix/client; federation reaches :8448
#     directly (and /.well-known/matrix/server advertises it explicitly).
#   - No secrets: Conduit generates its own signing keys into rocksdb under
#     /var/matrix-conduit.
#
# Account model: registration is enabled to bootstrap the first account (which
# Conduit auto-promotes to server admin). Flip CONDUIT_ALLOW_REGISTRATION to
# "false" and redeploy right after registering, then add users from the @conduit
# admin room with `!admin users create-user <name> <password>`.
{pkgs, ...}: let
  containers-sha = import ../../apps/fetcher/containers-sha.nix {inherit pkgs;};

  serverName = "matrix.freddrake.com";
  baseUrl = "https://${serverName}";
  conduitPort = "6167";
  dataDir = "/var/matrix-conduit";
in {
  # Client API (443) + federation (8448), both public. Nothing else runs on this
  # box, so opening 443 publicly exposes only Matrix.
  networking.firewall.allowedTCPPorts = [443 8448];

  security.acme.certs.${serverName} = {};

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
        proxyPass = "http://127.0.0.1:${conduitPort}";
        proxyWebsockets = true;
        extraConfig = "client_max_body_size 20M;";
      };
      # Client autodiscovery — Element resolves the homeserver from just the
      # user's server name.
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

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0700 root root -"
  ];

  virtualisation.oci-containers = {
    backend = "podman";
    containers.matrix-conduit = {
      image = containers-sha."docker.io"."matrixconduit/matrix-conduit"."v0.10.9"."linux/amd64";
      autoStart = true;
      # rocksdb database + auto-generated signing keys persist here.
      volumes = ["${dataDir}:/var/lib/matrix-conduit"];
      environment = {
        TZ = "America/New_York";
        # Empty so Conduit reads configuration from the env vars below.
        CONDUIT_CONFIG = "";
        CONDUIT_SERVER_NAME = serverName;
        CONDUIT_DATABASE_PATH = "/var/lib/matrix-conduit";
        CONDUIT_DATABASE_BACKEND = "rocksdb";
        CONDUIT_PORT = conduitPort;
        # Bind all interfaces inside the container; the host publish below keeps
        # it private to 127.0.0.1, and nginx fronts it.
        CONDUIT_ADDRESS = "0.0.0.0";
        CONDUIT_MAX_REQUEST_SIZE = "20000000";
        # Federate with the public Matrix network.
        CONDUIT_ALLOW_FEDERATION = "true";
        CONDUIT_ALLOW_CHECK_FOR_UPDATES = "false";
        # Notary server used to fetch other servers' signing keys.
        CONDUIT_TRUSTED_SERVERS = ''["matrix.org"]'';
        # Registration closed: the admin account is bootstrapped. Add more users
        # from the @conduit admin room with
        # `!admin users create-user <name> <password>`.
        CONDUIT_ALLOW_REGISTRATION = "false";
      };
      ports = ["127.0.0.1:${conduitPort}:${conduitPort}"];
    };
  };
}
