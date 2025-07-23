{config, ...}: {
  sops = {
    age.sshKeyPaths = ["/home/default/id_infrastructure"];
    defaultSopsFile = config.secrets.sopsYaml;
    secrets.sonarqube-env = {
      sopsFile = config.secrets.host.sonarqube.sonarqube-env;
      mode = "0400";
      key = "data";
    };
  };
}
