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

  boot = {
    kernel.sysctl = {
      # Memory-constrained media host (7.6 GiB RAM). Keep jellyfin's working
      # set in RAM rather than aggressively swapping; default 60 was paging
      # out hot pages and stalling the web UI on cold loads.
      "vm.swappiness" = 10;

      # Raise the page allocator's high-order reserve. CIFS SMB3-encrypted
      # writes to the Hetzner Storage Box ask for order-4 (64 KiB contiguous)
      # allocations via crypt_message → smb2_async_writev; under fragmentation
      # those failed twice on 2026-05-09 and surfaced to sabnzbd as ENOMEM.
      # 256 MiB gives the allocator real headroom for high-order requests
      # without meaningfully eating into usable RAM on this host.
      "vm.min_free_kbytes" = 262144;

      # Clients reach this host only via a high-RTT, lossy WireGuard tunnel
      # (~150 ms RTT, occasional drops from userspace WG on the home-side
      # MikroTik). BBR maintains throughput on lossy paths far better than
      # the default cubic, which collapses cwnd on every loss event.
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };
    kernelModules = ["tcp_bbr"];
  };
}
