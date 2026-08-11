{config, ...}: {
  # Resolve internal service names through the Tailscale DNS gateway, while
  # keeping public DNS for every other domain. The resolver is reachable on
  # the official Tailnet, not at the old LAN address.
  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = true;
    settings = {
      server =
        config.networking.nameservers
        ++ [
          "/${config.soft-secrets.networking.domain}/100.109.225.111"
        ];
      # Podman/aardvark-dns uses bridge-gateway addresses, so bind only to the
      # host loopback resolver and let it forward container queries here.
      listen-address = ["127.0.0.1"];
      bind-interfaces = true;
      cache-size = 1000;
    };
  };
}
