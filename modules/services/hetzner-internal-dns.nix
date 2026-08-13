{
  config,
  lib,
  ...
}: let
  domain = config.soft-secrets.networking.domain;
  address = hostname: ip: "/${hostname}.${domain}/${ip}";
in {
  # This resolver is intentionally authoritative only for the Hetzner service
  # names. It does not forward unknown internal names to the home resolver.
  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = true;
    settings = {
      server = lib.mkForce config.networking.nameservers;
      local = ["/${domain}/"];
      address = [
        (address "headscale" "10.1.1.2")
        (address "anton" "192.168.8.3")
        (address "glance" "192.168.8.2")
        (address "gnomeregan" "192.168.8.2")
        (address "ironforge" "10.1.1.3")
        (address "jellyfin" "10.1.1.3")
        (address "seerr" "10.1.1.3")
        (address "jellyseerr" "10.1.1.3")
        (address "sonarr" "10.1.1.3")
        (address "radarr" "10.1.1.3")
        (address "lidarr" "10.1.1.3")
        (address "prowlarr" "10.1.1.3")
        (address "sabnzbd" "10.1.1.3")
        (address "bazarr" "10.1.1.3")
        (address "orgrimmar" "10.1.1.4")
        (address "actual" "10.1.1.4")
        (address "calibre-desktop" "10.1.1.4")
        (address "calibre-desktop-web" "10.1.1.4")
        (address "hermes" "10.1.1.4")
        (address "buzz" "10.1.1.4")
        # Preserve the IPv4-mapped answer used by Buzz's Reqwest client.
        "/buzz.${domain}/::ffff:10.1.1.4"
        (address "gitea" "10.1.1.4")
        (address "gitea-status" "10.1.1.4")
        (address "woodpecker" "10.1.1.4")
        (address "paperless" "10.1.1.4")
        (address "paperless-ai" "10.1.1.4")
        (address "resume" "10.1.1.4")
        (address "calibre-web" "10.1.1.4")
        (address "files" "10.1.1.4")
        (address "stormwind" "10.1.1.5")
        (address "traceway" "10.1.1.5")
        (address "gatus" "10.1.1.5")
      ];

      # Serve local clients and Tailnet peers, never the public interface.
      interface = ["tailscale0"];
      listen-address = lib.mkForce ["127.0.0.1"];
      bind-dynamic = true;
      bind-interfaces = lib.mkForce false;
      cache-size = lib.mkForce 1000;
    };
  };

  networking.firewall.trustedInterfaces = ["tailscale0"];
}
