_: {
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "server";
  };

  # Required by a subnet router; harmless on direct Tailnet nodes.
  boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = 1;
}
