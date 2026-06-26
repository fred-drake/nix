{lib, ...}: {
  imports = [
    # No dedicated container disk on undercity — /var/lib/containers lives on the
    # root filesystem (single 76G disk).
    (import ../../../services/hetzner-app-server.nix {})
  ];

  # Mount root by UUID for consistency with the other Hetzner hosts and to stay
  # robust if a second disk/volume is ever attached (device-path root can race
  # the enumeration order). undercity currently has a single disk.
  fileSystems."/".device = lib.mkForce "/dev/disk/by-uuid/b9f39bfe-6e08-4815-b34a-b8e174296354";

  networking = {
    hostName = "undercity";
    # Public-facing leaf node: its own public IP on eth0 is the default route
    # (direct internet egress + inbound Matrix on 443/8448), and the Hetzner
    # private network is reached via enp7s0. This reuses the "gateway" routing
    # profile (default route out the public NIC) — undercity is NOT a NAT gateway
    # for others, it simply isn't NAT'd behind headscale the way
    # orgrimmar/ironforge are. Because the default route is the public NIC,
    # replies on the public IP are symmetric and no source policy routing is
    # needed.
    serverType = "gateway";
    interfaces = {
      eth0.ipv4.addresses = [
        {
          address = "65.108.217.23";
          prefixLength = 32;
        }
      ];
      enp7s0 = {
        ipv4.addresses = [
          {
            address = "10.1.1.6";
            prefixLength = 32;
          }
        ];
        # Reach the rest of the Hetzner private network via the headscale gateway.
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
      };
    };
  };
}
