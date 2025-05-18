{
  config,
  pkgs,
  ...
}: let
  containers-sha = import ../../../../apps/fetcher/containers-sha.nix {inherit pkgs;};
in {
  systemd.tmpfiles.rules = [
    "d /var/sonarr/config 0755 99 100 -"
  ];

  security.acme.certs."sonarr.${config.soft-secrets.networking.domain}" = {
    domain = "sonarr.${config.soft-secrets.networking.domain}";
    dnsProvider = "cloudflare";
    dnsResolver = "1.1.1.1:53";
    webroot = null;
    listenHTTP = null;
    s3Bucket = null;
    environmentFile = config.sops.secrets.cloudflare-api-key.path;
  };

  services.nginx.virtualHosts."sonarr.${config.soft-secrets.networking.domain}" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8989";
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

  virtualisation.oci-containers.containers.sonarr = {
    image = containers-sha."ghcr.io"."linuxserver/sonarr"."latest"."linux/amd64";
    autoStart = true;
    ports = ["127.0.0.1:8989:8989"];
    volumes = [
      "/var/sonarr/config:/config"
      "/mnt/array/storage1:/storage"
    ];
    environment = {
      PUID = "99";
      PGID = "100";
      TZ = "America/New_York";
    };
  };
}
