{
  config,
  pkgs,
  ...
}: let
  containers-sha = import ../../../../apps/fetcher/containers-sha.nix {inherit pkgs;};
in {
  systemd.tmpfiles.rules = [
    "d /var/radarr/config 0755 99 100 -"
  ];

  security.acme.certs."radarr.${config.soft-secrets.networking.domain}" = {
    domain = "radarr.${config.soft-secrets.networking.domain}";
    dnsProvider = "cloudflare";
    dnsResolver = "1.1.1.1:53";
    webroot = null;
    listenHTTP = null;
    s3Bucket = null;
    environmentFile = config.sops.secrets.cloudflare-api-key.path;
  };

  services.nginx.virtualHosts."radarr.${config.soft-secrets.networking.domain}" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:7878";
      proxyWebsockets = true;
      extraConfig = ''
        # Increase the maximum size of the hash table
        proxy_headers_hash_max_size 1024;

        # Increase the bucket size of the hash table
        proxy_headers_hash_bucket_size 128;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
      '';
    };
  };

  virtualisation.oci-containers.containers.radarr = {
    image = containers-sha."ghcr.io"."linuxserver/radarr"."latest"."linux/amd64";
    autoStart = true;
    ports = ["127.0.0.1:7878:7878"];
    volumes = [
      "/var/radarr/config:/config"
      "/mnt/array/storage1:/storage"
    ];
    environment = {
      PUID = "99";
      PGID = "100";
      TZ = "America/New_York";
    };
  };
}
