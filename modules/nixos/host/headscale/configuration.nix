_: {
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
        ipv4.routes = [
          {
            address = "10.1.0.1";
            prefixLength = 32;
          }
          {
            address = "10.0.0.0";
            prefixLength = 8;
            via = "10.1.0.1";
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
    iptables -A FORWARD -i enp7s0 -o eth0 -j ACCEPT
    iptables -A FORWARD -i eth0 -o enp7s0 -m state --state RELATED,ESTABLISHED -j ACCEPT
  '';
}
