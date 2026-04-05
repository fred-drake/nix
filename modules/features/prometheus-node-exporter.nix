# Prometheus node exporter — dendritic feature for monitored servers.
_: {
  my.modules.nixos.prometheus-node-exporter = {
    config,
    lib,
    ...
  }:
    lib.mkIf config.my.hasMonitoring {
      services.prometheus.exporters.node = {
        enable = true;
        listenAddress = config.soft-secrets.host.${config.my.hostName}.admin_ip_address;
        port = 9000;
        enabledCollectors = ["cpu" "systemd" "diskstats" "ethtool" "filesystem" "netdev"];
        extraFlags = ["--collector.softirqs" "--collector.tcpstat" "--collector.wifi"];
      };
    };
}
