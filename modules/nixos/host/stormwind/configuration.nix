{lib, ...}: {
  imports = [
    (import ../../../services/hetzner-app-server.nix {
      containerDiskUUID = "9b6b97b7-3d0e-4ed1-86da-ca61c91780b3";
    })
  ];

  # Mount root by UUID rather than /dev/sda1 — this host has a second SCSI disk
  # (the containers volume) and the boot enumeration order between the two isn't
  # guaranteed. Device-path root races and can fail to mount; UUID is stable.
  fileSystems."/".device = lib.mkForce "/dev/disk/by-uuid/2cca3fcb-bab0-437b-94b5-664ecfcae57a";

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

  # Clients reach this host over a high-RTT, lossy Tailscale subnet route.
  # BBR maintains throughput better than CUBIC when packets are retransmitted.
  boot = {
    kernel.sysctl = {
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };
    kernelModules = ["tcp_bbr"];
  };
}
