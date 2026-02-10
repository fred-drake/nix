{config, ...}: {
  networking = {
    hostName = "headscale";
    serverType = "gateway";
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          {
            address = "157.180.42.128";
            prefixLength = 32;
          }
        ];
        ipv6.addresses = [
          {
            address = "fe80::9000:7ff:fe2f:f11c";
            prefixLength = 64;
          }
        ];
      };
      enp7s0 = {
        ipv4.addresses = [
          {
            address = "10.1.1.2";
            prefixLength = 32;
          }
        ];
        ipv6.addresses = [
          {
            address = "fe80::8400:ff:fe7b:4d41";
            prefixLength = 64;
          }
        ];
      };
    };
    firewall = {
      allowedTCPPorts = [22 80 443];
    };
  };

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  networking.firewall.extraCommands = ''
    iptables -t nat -A POSTROUTING -s 10.1.0.0/16 -o eth0 -j MASQUERADE
  '';
}
