{
  config,
  pkgs,
  ...
}: let
  containers-sha = import ./fetcher/containers-sha.nix {inherit pkgs;};
  host = "sonarqube";
  proxyPort = "9000";
in {
  security = {
    acme = {
      acceptTerms = true;
      preliminarySelfsigned = false;
      defaults = {
        email = config.soft-secrets.acme.email;
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
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;

              proxy_http_version 1.1;
              proxy_set_header   Upgrade $http_upgrade;
              proxy_set_header   Connection "upgrade";

              # SonarQube specific headers
              proxy_set_header X-Forwarded-Host $host;

              # Increase timeouts for SonarQube analysis
              proxy_connect_timeout 300;
              proxy_send_timeout 300;
              proxy_read_timeout 300;
            '';
          };
        };
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/sonarqube/data 0755 1000 1000 -"
    "d /var/sonarqube/logs 0755 1000 1000 -"
    "d /var/sonarqube/extensions 0755 1000 1000 -"
    "d /var/postgresql/data 0755 999 999 -"
  ];

  virtualisation.containers.enable = true;
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };
  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      sonarqube-postgres = {
        image = containers-sha."docker.io"."postgres"."17"."linux/amd64";
        autoStart = true;
        ports = [
          "0.0.0.0:5432:5432"
        ];
        volumes = [
          "/var/postgresql/data:/var/lib/postgresql/data"
        ];
        environment = {
          POSTGRES_DB = "sonarqube";
          POSTGRES_USER = "sonarqube";
          TZ = "America/New_York";
        };
        environmentFiles = [config.sops.secrets.sonarqube-env.path];
      };
      sonarqube = {
        image = containers-sha."docker.io"."sonarqube"."latest"."linux/amd64";
        autoStart = true;
        dependsOn = ["sonarqube-postgres"];
        ports = [
          "127.0.0.1:${proxyPort}:${proxyPort}"
        ];
        volumes = [
          "/var/sonarqube/data:/opt/sonarqube/data"
          "/var/sonarqube/logs:/opt/sonarqube/logs"
          "/var/sonarqube/extensions:/opt/sonarqube/extensions"
        ];
        environment = {
          SONAR_JDBC_URL = "jdbc:postgresql://host.containers.internal:5432/sonarqube";
          SONAR_JDBC_USERNAME = "sonarqube";
          TZ = "America/New_York";
        };
        environmentFiles = [config.sops.secrets.sonarqube-env.path];
      };
    };
  };
}
