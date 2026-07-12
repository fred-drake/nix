{config, ...}: {
  # Resolve internal service names through Hearthstone, while keeping public DNS
  # for every other domain. All Hetzner hosts can reach Hearthstone's LAN IP
  # through the Headscale subnet route.
  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = true;
    settings = {
      server =
        config.networking.nameservers
        ++ [
          "/${config.soft-secrets.networking.domain}/192.168.8.1"
        ];
      # Podman/aardvark-dns uses bridge-gateway addresses, so bind only to the
      # host loopback resolver and let it forward container queries here.
      listen-address = ["127.0.0.1"];
      bind-interfaces = true;
      cache-size = 1000;
    };
  };
}
