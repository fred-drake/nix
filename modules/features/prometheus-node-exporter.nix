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
        enabledCollectors = ["cpu" "systemd" "diskstats" "ethtool" "filesystem" "netdev" "textfile"];
        extraFlags = [
          "--collector.softirqs"
          "--collector.tcpstat"
          "--collector.wifi"
          "--collector.textfile.directory=/var/lib/prometheus-node-exporter-text-files"
        ];
      };

      # node_exporter only listens on the host's private admin address. Permit
      # Gatus on that network to scrape custom health metrics.
      networking.firewall.allowedTCPPorts = [9000];
      systemd.tmpfiles.rules = [
        "d /var/lib/prometheus-node-exporter-text-files 0755 root root -"
      ];
    };
}
