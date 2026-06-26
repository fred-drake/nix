{lib, ...}: {
  imports = [
    (import ../../../services/hetzner-app-server.nix {
      containerDiskUUID = "59f51d47-a712-4744-857d-662fd7553606";
    })
  ];

  # Mount root by UUID rather than /dev/sda1. This host has a second SCSI disk
  # (the containers volume), and the kernel can enumerate the two in either order
  # at boot — a device-path root intermittently lands on /dev/sdb and fails to
  # mount (this is what took orgrimmar down). UUID is order-independent.
  fileSystems."/".device = lib.mkForce "/dev/disk/by-uuid/313208b0-1dec-4caf-a3ef-3ccc732adc53";

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
