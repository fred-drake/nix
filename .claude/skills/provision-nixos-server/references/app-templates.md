# Application Configuration Templates

## Nginx Proxy with SSL (Let's Encrypt + Cloudflare)

```nix
{
  config,
  pkgs,
  ...
}: let
  containers-sha = import ./fetcher/containers-sha.nix {inherit pkgs;};
  host = "<hostname>";
  proxyPort = "<port>";  # e.g., "8000"
in {
  security = {
    acme = {
      acceptTerms = true;
      preliminarySelfsigned = false;
      defaults = {
        inherit (config.soft-secrets.acme) email;
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
            proxyWebsockets = true;  # Adds proxy_http_version 1.1 and upgrade headers
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;

              proxy_connect_timeout 300;
              proxy_send_timeout 300;
              proxy_read_timeout 300;
            '';
          };
        };
      };
    };
  };
  # ... container configuration below
}
```

**Note:** When using `proxyWebsockets = true`, do NOT include `proxy_http_version 1.1` or `Upgrade`/`Connection` headers in extraConfig - they're added automatically and will cause duplicate directive errors.

## PostgreSQL Container

```nix
  systemd.tmpfiles.rules = [
    "d /var/<appname>/data 0755 1000 1000 -"
    "d /var/postgresql 0755 999 999 -"  # Note: mount at /var/lib/postgresql for pg18+
  ];

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    oci-containers = {
      backend = "podman";
      containers = {
        <appname>-postgres = {
          image = containers-sha."docker.io"."postgres"."18"."linux/amd64";
          autoStart = true;
          ports = [
            "0.0.0.0:5432:5432"  # Use 0.0.0.0 for container-to-container access
          ];
          volumes = [
            "/var/postgresql:/var/lib/postgresql"  # pg18+ uses this mount point
          ];
          environment = {
            TZ = "America/New_York";
          };
          environmentFiles = [config.sops.secrets.postgresql-env.path];
        };
      };
    };
  };
```

**PostgreSQL 18+ Note:** Mount volumes at `/var/lib/postgresql` (not `/var/lib/postgresql/data`). PostgreSQL 18 changed to use version-specific subdirectories.

## Application Container with PostgreSQL Dependency

```nix
        <appname> = {
          image = containers-sha."<registry>"."<image>"."<tag>"."linux/amd64";
          autoStart = true;
          dependsOn = ["<appname>-postgres"];
          ports = [
            "127.0.0.1:${proxyPort}:${proxyPort}"
          ];
          volumes = [
            "/var/<appname>/data:/app/data"  # Adjust paths as needed
          ];
          environment = {
            # Database connection uses host IP or host.containers.internal
            DATABASE_HOST = "host.containers.internal";
            DATABASE_PORT = "5432";
            TZ = "America/New_York";
          };
          environmentFiles = [config.sops.secrets.<appname>-env.path];
        };
```

**Database Connection:** Use `host.containers.internal` for containers to reach services on the host network (e.g., postgres exposed on 0.0.0.0:5432).

## Adding New Container Images

1. Add to `apps/fetcher/containers.toml`:
```toml
[[containers]]
repository = "docker.io"
name = "vendor/image-name"
tag = "v1"
architectures = ["linux/amd64"]
```

2. Run `just update-container-digests` to generate SHA hashes

3. Reference in app config:
```nix
image = containers-sha."docker.io"."vendor/image-name"."v1"."linux/amd64";
```
