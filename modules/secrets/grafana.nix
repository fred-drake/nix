{config, ...}: {
  sops.age.sshKeyPaths = ["/home/default/id_infrastructure"];
  sops.defaultSopsFile = config.secrets.sopsYaml;
  sops.secrets.grafana-admin-password = {
    sopsFile = config.secrets.host.grafana.admin-password;
    mode = "0400";
    key = "data";
    owner = "grafana";
    group = "grafana";
  };
}
