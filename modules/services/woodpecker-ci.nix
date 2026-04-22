{
  config,
  pkgs,
  ...
}: let
  containers-sha = import ../../apps/fetcher/containers-sha.nix {inherit pkgs;};
  mkPodmanNetwork = import ../../lib/mk-podman-network.nix {inherit pkgs;};
  mkNginxProxy = import ../../lib/mk-nginx-proxy.nix {inherit config;};
  host = "woodpecker";
  proxyPort = "8000";
in {
  imports = [
    (mkNginxProxy {
      inherit host;
      port = proxyPort;
      extraConfig = ''
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        proxy_read_timeout 300;
      '';
    })
  ];

  sops.secrets = {
    woodpecker-postgresql-env = {
      sopsFile = config.secrets.host.woodpecker.postgresql-env;
      mode = "0400";
      key = "data";
    };
    woodpecker-env = {
      sopsFile = config.secrets.host.woodpecker.woodpecker-env;
      mode = "0400";
      key = "data";
    };
    woodpecker-agent-env = {
      sopsFile = config.secrets.host.woodpecker.woodpecker-agent-env;
      mode = "0400";
      key = "data";
    };
  };

  systemd = {
    tmpfiles.rules = [
      "d /var/woodpecker/data 0755 1000 1000 -"
      "d /var/woodpecker/postgresql 0755 999 999 -"
    ];
    services =
      (mkPodmanNetwork "woodpecker" [
        "podman-woodpecker-postgres.service"
        "podman-woodpecker-server.service"
        "podman-woodpecker-agent.service"
      ])
      // {
        podman-woodpecker-agent = {
          after = ["podman.socket"];
          bindsTo = ["podman.socket"];
        };
      };
    sockets.podman = {
      wantedBy = ["sockets.target"];
    };
  };

  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      woodpecker-postgres = {
        image = containers-sha."docker.io"."postgres"."18"."linux/amd64";
        autoStart = true;
        extraOptions = ["--network=woodpecker-net"];
        volumes = [
          "/var/woodpecker/postgresql:/var/lib/postgresql"
        ];
        environment = {
          TZ = "America/New_York";
        };
        environmentFiles = [config.sops.secrets.woodpecker-postgresql-env.path];
      };
      woodpecker-server = {
        image = containers-sha."docker.io"."woodpeckerci/woodpecker-server"."v3"."linux/amd64";
        autoStart = true;
        dependsOn = ["woodpecker-postgres"];
        extraOptions =
          [
            "--network=woodpecker-net"
            "--add-host=gitea.${config.soft-secrets.networking.domain}:host-gateway"
          ]
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
        # Internal nameservers are unroutable from the podman bridge, and aardvark-dns
        # forwards external queries to them when --dns is set, hanging the agent's
        # gRPC auth past its deadline. Rely on aardvark's default host-resolver forwarding.
        extraOptions = [
          "--network=woodpecker-net"
          "--add-host=gitea.${config.soft-secrets.networking.domain}:host-gateway"
          "--privileged"
          "--security-opt=seccomp=unconfined"
          "--security-opt=apparmor=unconfined"
          "--security-opt=label=disable"
        ];
        volumes = [
          "/run/podman/podman.sock:/var/run/docker.sock"
        ];
        environment = {
          WOODPECKER_SERVER = "woodpecker-server:9000";
          WOODPECKER_BACKEND = "docker";
          WOODPECKER_BACKEND_DOCKER_NETWORK = "woodpecker-net";
          TZ = "America/New_York";
        };
        environmentFiles = [config.sops.secrets.woodpecker-agent-env.path];
      };
    };
  };
}
