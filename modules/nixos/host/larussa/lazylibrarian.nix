{
  config,
  pkgs,
  ...
}: let
  containers-sha = import ../../../../apps/fetcher/containers-sha.nix {inherit pkgs;};
in {
  systemd.tmpfiles.rules = [
    "d /var/lazylibrarian/config 0755 99 100 -"
  ];

  security.acme.certs."lazylibrarian.${config.soft-secrets.networking.domain}" = {
    domain = "lazylibrarian.${config.soft-secrets.networking.domain}";
    dnsProvider = "cloudflare";
    dnsResolver = "1.1.1.1:53";
    webroot = null;
    listenHTTP = null;
    s3Bucket = null;
    environmentFile = config.sops.secrets.cloudflare-api-key.path;
  };

  services.nginx.virtualHosts."lazylibrarian.${config.soft-secrets.networking.domain}" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:5299";
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

  virtualisation.oci-containers.containers.lazylibrarian = {
    image = containers-sha."lscr.io"."linuxserver/lazylibrarian"."latest"."linux/amd64";
    autoStart = true;
    ports = ["127.0.0.1:5299:5299"];
    volumes = [
      "/var/lazylibrarian/config:/config"
      "/mnt/array/storage1/calibre:/books"
      "/mnt/array/storage1/sabnzbd_downloads:/downloads"
    ];
    environment = {
      PUID = "99";
      PGID = "100";
      TZ = "America/New_York";
      DOCKER_MODS = "linuxserver/mods:universal-calibre|linuxserver/mods:lazylibrarian-ffmpeg";
    };
  };
}
