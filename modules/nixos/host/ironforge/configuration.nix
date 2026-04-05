_: {
  imports = [
    (import ../../../services/hetzner-app-server.nix {
      containerDiskUUID = "69caea45-e319-47d5-b088-b8155a301e12";
    })
  ];

  networking = {
    hostName = "ironforge";
    interfaces = {
      enp7s0 = {
        ipv4.addresses = [
          {
            address = "10.1.1.3";
            prefixLength = 32;
          }
        ];
      };
    };
  };
}
