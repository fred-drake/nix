{config, ...}: {
  sops.age.sshKeyPaths = ["/home/default/id_infrastructure"];
  sops.defaultSopsFile = config.secrets.sopsYaml;
  sops.secrets.sonarqube-env = {
    sopsFile = config.secrets.host.sonarqube.sonarqube-env;
    mode = "0400";
    key = "data";
  };
}
