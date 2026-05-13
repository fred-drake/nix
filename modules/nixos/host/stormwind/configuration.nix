_: {
  imports = [
    (import ../../../services/hetzner-app-server.nix {
      containerDiskUUID = "9b6b97b7-3d0e-4ed1-86da-ca61c91780b3";
    })
  ];

  networking = {
    hostName = "stormwind";
    interfaces = {
      enp7s0 = {
        ipv4.addresses = [
          {
            address = "10.1.1.5";
            prefixLength = 32;
          }
        ];
      };
    };
  };
}
