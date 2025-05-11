{secrets, ...}: let
  soft-secrets = import "${secrets}/soft-secrets";
in {
  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = soft-secrets.host.adguard2.admin_ip_address;
    port = 9000;
    enabledCollectors = ["cpu" "systemd" "diskstats" "ethtool" "filesystem" "netdev"];
    extraFlags = ["--collector.softirqs" "--collector.tcpstat" "--collector.wifi"];
  };
}
