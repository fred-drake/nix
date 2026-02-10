_: {
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "server";
    extraUpFlags = [
      "--login-server=https://headscale.brainrush.ai"
      "--advertise-routes=10.1.0.0/16"
      "--accept-routes"
      "--advertise-exit-node"
    ];
  };

  # Enable IPv6 forwarding for subnet routing (IPv4 is already set in configuration.nix)
  boot.kernel.sysctl = {
    "net.ipv6.conf.all.forwarding" = 1;
  };
}
