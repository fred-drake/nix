{ secrets, ... }:

let
  soft-secrets = import "${secrets}/soft-secrets";
in
{
  # Function to create a node exporter configuration with a specific host key
  mkNodeExporter = hostKey: {
    services.prometheus.exporters.node = {
      enable = true;
      listenAddress = soft-secrets.host.${hostKey}.admin_ip_address;
      port = 9000;
      enabledCollectors = ["cpu" "systemd" "diskstats" "ethtool" "filesystem" "netdev"];
      extraFlags = ["--collector.softirqs" "--collector.tcpstat" "--collector.wifi"];
    };
  };
}
