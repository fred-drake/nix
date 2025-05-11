{secrets, ...}: let
  soft-secrets = import "${secrets}/soft-secrets";
in {
  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = soft-secrets.host.gitea.admin_ip_address;
    port = 9000;
    enabledCollectors = ["systemd"];
    extraFlags = ["--collector.ethtool" "--collector.softirqs" "--collector.tcpstat" "--collector.wifi"];
  };
}
