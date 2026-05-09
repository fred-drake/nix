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

  # Memory-constrained media host (7.6 GiB RAM). Keep jellyfin's working set
  # in RAM rather than aggressively swapping; default 60 was paging out hot
  # pages and stalling the web UI on cold loads.
  boot.kernel.sysctl."vm.swappiness" = 10;

  # Clients reach this host only via a high-RTT, lossy WireGuard tunnel
  # (~150 ms RTT, occasional drops from userspace WG on the home-side
  # MikroTik). BBR maintains throughput on lossy paths far better than the
  # default cubic, which collapses cwnd on every loss event.
  boot.kernelModules = ["tcp_bbr"];
  boot.kernel.sysctl."net.core.default_qdisc" = "fq";
  boot.kernel.sysctl."net.ipv4.tcp_congestion_control" = "bbr";
}
