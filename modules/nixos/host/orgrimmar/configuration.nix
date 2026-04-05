_: {
  imports = [
    (import ../../../services/hetzner-app-server.nix {
      containerDiskUUID = "59f51d47-a712-4744-857d-662fd7553606";
    })
  ];

  networking = {
    hostName = "orgrimmar";
    interfaces = {
      enp7s0 = {
        ipv4.addresses = [
          {
            address = "10.1.1.4";
            prefixLength = 32;
          }
        ];
      };
    };
  };
}
